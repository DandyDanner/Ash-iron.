"""Prepare Dallon's supplied tree/chest/ore with portable PBR materials.
Blender --background --factory-startup --python tools/blender/prepare_imported_props.py
Optional arguments after --: Tree.zip Chest/base_basic_pbr.glb ore/base_basic_pbr.glb
Original downloads are never modified. Output GLBs, editable blend sources and report.
"""
import bpy,bmesh,sys,json,zipfile,tempfile,hashlib
import numpy as np
from pathlib import Path
from mathutils import Vector
R=Path(__file__).resolve().parents[2]; OUT=R/'assets/props';SRC=R/'art/blender/imported_props'
OUT.mkdir(parents=True,exist_ok=True);SRC.mkdir(parents=True,exist_ok=True)
args=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else []
inputs=args or ['/Users/dallonanderson/Downloads/Tree.zip','/Users/dallonanderson/Downloads/Chest/base_basic_pbr.glb','/Users/dallonanderson/Downloads/ore/base_basic_pbr.glb']
report={}
def clean():
 bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
def select(o):
 bpy.ops.object.select_all(action='DESELECT');o.select_set(True);bpy.context.view_layer.objects.active=o
def load(path):
 clean();path=Path(path)
 if path.suffix=='.zip':
  with zipfile.ZipFile(path)as z:b=z.read('base_basic_pbr.glb')
  dest=Path(tempfile.gettempdir())/'ash-props-tree-source.glb';dest.write_bytes(b)
 else:b=path.read_bytes();dest=path
 bpy.ops.import_scene.gltf(filepath=str(dest));o=next(o for o in bpy.context.scene.objects if o.type=='MESH');select(o);bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
 return o,{'source':str(path),'sha256':hashlib.sha256(b).hexdigest(),'source_triangles':sum(len(p.vertices)-2 for p in o.data.polygons)}
def fit(o,size):
 lo=Vector([min(v.co[i]for v in o.data.vertices)for i in range(3)]);hi=Vector([max(v.co[i]for v in o.data.vertices)for i in range(3)]);center=Vector(((hi.x+lo.x)/2,(hi.y+lo.y)/2,lo.z))
 for v in o.data.vertices:v.co=Vector([(v.co[i]-center[i])*size[i]/(hi[i]-lo[i]) for i in range(3)])
def decimate(o,count):
 select(o);m=o.modifiers.new('Gameplay triangle budget','DECIMATE');m.ratio=min(1,count/sum(len(p.vertices)-2 for p in o.data.polygons));bpy.ops.object.modifier_apply(modifier=m.name)
def materials(o,gray=False):
 for mat in o.data.materials:
  if not mat.use_nodes:continue
  bs=mat.node_tree.nodes.get('Principled BSDF')
  for key,value in [('Metallic',0),('Roughness',.82)]:
   for link in list(bs.inputs[key].links):mat.node_tree.links.remove(link)
   bs.inputs[key].default_value=value
  for node in mat.node_tree.nodes:
   if node.type=='TEX_IMAGE'and node.image:
    im=node.image
    if max(im.size)>1024:im.scale(1024,1024)
    im.pack()
  if gray:
   im=bs.inputs['Base Color'].links[0].from_node.image;pixels=np.empty(len(im.pixels),dtype=np.float32);im.pixels.foreach_get(pixels);a=pixels.reshape(-1,4);lum=a[:,:3]@np.array([.2126,.7152,.0722]);top=max(float(np.percentile(lum,95)),.001);tone=.10+.42*np.sqrt(np.clip(lum/top,0,1));a[:,:3]=tone[:,None];im.pixels.foreach_set(pixels);im.update();im.pack()
def export(name,objects,data):
 bpy.ops.object.select_all(action='DESELECT')
 for o in objects:o.select_set(True)
 bpy.context.view_layer.objects.active=objects[0]
 for o in objects:
  if o.type=='MESH':
   for p in o.data.polygons:p.use_smooth=True
 data['meshes']={o.name:sum(len(p.vertices)-2 for p in o.data.polygons)for o in objects if o.type=='MESH'}
 bpy.ops.wm.save_as_mainfile(filepath=str(SRC/(name+'.blend')))
 bpy.ops.export_scene.gltf(filepath=str(OUT/(name+'.glb')),export_format='GLB',use_selection=True,export_animations=False,export_yup=True)
 data['glb_bytes']=(OUT/(name+'.glb')).stat().st_size;report[name]=data
# Shared textured near/far tree with original proportions, grounded at its trunk.
o,d=load(inputs[0]);materials(o);fit(o,(3.60,3.60,5.10));far=o.copy();far.data=o.data.copy();bpy.context.collection.objects.link(far);decimate(o,8000);decimate(far,1400);o.name='PineNear';far.name='PineFar';export('pine',[o,far],d)
# Rock cluster in a unit box, grounded. Shader palettes preserve this surface detail.
o,d=load(inputs[2]);materials(o,True);fit(o,(1,1,1));far=o.copy();far.data=o.data.copy();bpy.context.collection.objects.link(far);decimate(o,6000);decimate(far,900);o.name='RockNear';far.name='RockFar';export('rock_cluster',[o,far],d)
# Cut a true hinged lid, hollow the body, and cap the fresh cuts with dark wood.
o,d=load(inputs[1]);materials(o);fit(o,(.92,.58,.62));decimate(o,9000)
inner=bpy.data.materials.new('Chest inner wood');inner.diffuse_color=(.19,.10,.045,1);inner.use_nodes=True;inner.node_tree.nodes.get('Principled BSDF').inputs['Base Color'].default_value=inner.diffuse_color;inner.node_tree.nodes.get('Principled BSDF').inputs['Roughness'].default_value=.9
o.data.materials.append(inner);inner_index=len(o.data.materials)-1
lid=o.copy();lid.data=o.data.copy();bpy.context.collection.objects.link(lid)
def cut(obj,upper):
 bm=bmesh.new();bm.from_mesh(obj.data)
 result=bmesh.ops.bisect_plane(bm,geom=list(bm.verts)+list(bm.edges)+list(bm.faces),dist=.00001,plane_co=(0,0,.49),plane_no=(0,0,1),clear_inner=upper,clear_outer=not upper)
 edges=[e for e in result['geom_cut']if isinstance(e,bmesh.types.BMEdge)and e.is_boundary]
 if edges:
  cap=bmesh.ops.holes_fill(bm,edges=edges,sides=0)
  for f in cap['faces']:f.material_index=inner_index
 bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(obj.data);bm.free()
cut(o,False);cut(lid,True)
# Remove the cut's top cap and build the inside explicitly. A boolean on generated
# topology can invert the cavity, so keep the original exterior and an open shell.
bm=bmesh.new();bm.from_mesh(o.data)
faces=[f for f in bm.faces if all(v.co.z > .4899 for v in f.verts)]
bmesh.ops.delete(bm,geom=faces,context='FACES');bm.to_mesh(o.data);bm.free()
parts=[o]
def inside_box(name,location,size):
 bpy.ops.mesh.primitive_cube_add(size=1,location=location);box=bpy.context.object;box.name=name;box.dimensions=size;select(box);bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);box.data.materials.append(inner);parts.append(box)
inside_box('Interior floor',(0,0,.065),(.72,.40,.035))
for side in [-1,1]:
 inside_box('Inner side',(side*.35,0,.275),(.025,.40,.42))
 inside_box('Inner end',(0,side*.19,.275),(.72,.025,.42))
 inside_box('Top side rim',(side*.43,0,.482),(.045,.55,.014))
 inside_box('Top end rim',(0,side*.266,.482),(.86,.035,.014))
bpy.ops.object.select_all(action='DESELECT')
for part in parts:part.select_set(True)
bpy.context.view_layer.objects.active=o;bpy.ops.object.join()
# Godot's back edge is -Z; glTF maps Blender +Y there.
pivot=Vector((0,.29,.49))
for v in lid.data.vertices:v.co-=pivot
lid.location=pivot;o.name='ChestBody';lid.name='ChestLid';export('storage_chest',[o,lid],d)
(SRC/'report.json').write_text(json.dumps(report,indent=2));print('PROPS_COMPLETE',json.dumps(report),flush=True)
