"""Repair the front traveler from Dallon's generated sheet as an offline candidate.
Replace corrupt head/neck with our clean cycle-30 facial surfaces, keeping uploaded clothing.
Run with Blender --background --factory-startup --python this_file -- /path/to/upload.glb.
The playable traveler remains unchanged pending body retopology/rigging.
"""
import bpy,bmesh,sys,json,math
from pathlib import Path
from mathutils import Vector,Matrix
R=Path(__file__).resolve().parents[2];SOURCE=Path(sys.argv[sys.argv.index('--')+1]) if '--' in sys.argv else Path('/Users/dallonanderson/Downloads/willow scout 3d model.glb')
OUT=R/'art/blender/willow_import';OUT.mkdir(parents=True,exist_ok=True)
REVIEW=R/'docs/art/willow-import';REVIEW.mkdir(parents=True,exist_ok=True)
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False);bpy.ops.import_scene.gltf(filepath=str(SOURCE));body=next(o for o in bpy.context.scene.objects if o.type=='MESH')
bm=bmesh.new();bm.from_mesh(body.data);bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=.000005);bmesh.ops.delete(bm,geom=[v for v in bm.verts if v.co.x>-.18],context='VERTS');bm.to_mesh(body.data);bm.free()
lo=Vector([min(v.co[i] for v in body.data.vertices) for i in range(3)]);hi=Vector([max(v.co[i] for v in body.data.vertices) for i in range(3)]);center=Vector(((lo.x+hi.x)*.5,(lo.y+hi.y)*.5,lo.z));factor=1.8/(hi.z-lo.z)
for v in body.data.vertices:v.co=(v.co-center)*factor
body.name='Imported Willow clothing'
for mat in body.data.materials:
 bs=mat.node_tree.nodes.get('Principled BSDF')
 for socket,value in [('Metallic',0),('Roughness',.8)]:
  for l in list(bs.inputs[socket].links):mat.node_tree.links.remove(l)
  bs.inputs[socket].default_value=value
 bs.inputs['Specular IOR Level'].default_value=.25
# Preserve a matching before view. Cameras/lights are identical for each comparison.
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.device='CPU';scene.cycles.samples=24;scene.cycles.use_denoising=True;scene.render.resolution_x=900;scene.render.resolution_y=1000;scene.render.resolution_percentage=100;scene.world.color=(.16,.16,.16)
center=Vector((0,0,1))
for offset,energy,size in [((-3,-4,5),500,4),((4,-1,3),280,4),((0,4,4),550,3)]:
 bpy.ops.object.light_add(type='AREA',location=offset);light=bpy.context.object;light.data.energy=energy;light.data.size=size;light.rotation_euler=(center-light.location).to_track_quat('-Z','Y').to_euler()
bpy.ops.object.camera_add();cam=bpy.context.object;scene.camera=cam;cam.data.type='ORTHO'
bpy.ops.mesh.primitive_plane_add(size=200);floor=bpy.context.object;mat=bpy.data.materials.new('Review floor');mat.diffuse_color=(.1,.12,.13,1);floor.data.materials.append(mat)
def render(name,target,offset,span):
 target=Vector(target);cam.location=target+Vector(offset);cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.ortho_scale=span;scene.render.filepath=str(REVIEW/(name+'.png'));bpy.ops.render.render(write_still=True)
if not (REVIEW/'before-face.png').exists(): render('before-face',(0,-.01,1.59),(0,-2,.05),.52)
if not (REVIEW/'before-full.png').exists(): render('before-full',(0,0,.90),(.3,-4,.25),2.08)
# Remove folded/overlapping face, hair and neck, preserving bow/quiver outside the head volume.
bm=bmesh.new();bm.from_mesh(body.data)
remove=[v for v in bm.verts if (v.co.z>1.51 and -.225<v.co.x<.20) or (v.co.z>1.44 and abs(v.co.x)<.11 and v.co.y<.07)]
bmesh.ops.delete(bm,geom=remove,context='VERTS');bm.to_mesh(body.data);bm.free()
bpy.context.view_layer.objects.active=body
mod=body.modifiers.new('Candidate clothing budget','DECIMATE');mod.ratio=min(1,55000/len(body.data.polygons));bpy.ops.object.modifier_apply(modifier=mod.name)
with bpy.data.libraries.load(str(R/'art/blender/cycles/cycle_30/characters.blend'),link=False) as (source,dest):
 dest.collections=['WILLOW SCOUT — authored study']
col=dest.collections[0];scene.collection.children.link(col);root=next(o for o in col.objects if o.type=='EMPTY');newparts=[]
bpy.context.view_layer.update()
for ob in list(col.objects):
 if ob.type not in ['MESH','CURVE']:continue
 if not ob.name.startswith('WILLOW SCOUT'):continue
 pts=[root.matrix_world.inverted()@ob.matrix_world@Vector(p) for p in ob.bound_box]
 if max(p.z for p in pts)<1.55 and not ob.name.startswith('Neck'):continue
 for mod in ob.modifiers:
  if mod.type=='SUBSURF':mod.levels=0;mod.render_levels=0
 if ob.type=='CURVE':ob.data.bevel_resolution=1;ob.data.resolution_u=4
 bpy.context.view_layer.update();dg=bpy.context.evaluated_depsgraph_get();data=bpy.data.meshes.new_from_object(ob.evaluated_get(dg),preserve_all_data_layers=True,depsgraph=dg);data.transform(root.matrix_world.inverted()@ob.matrix_world)
 for v in data.vertices:
  p=v.co;v.co=Vector((p.x*1.05-.015,p.y*1.1-.035,(p.z-1.548)*1.10+1.49))
 obj=bpy.data.objects.new('Repaired '+ob.name,data);scene.collection.objects.link(obj);newparts.append(obj)
 bpy.context.view_layer.objects.active=obj
 tris=sum(len(p.vertices)-2 for p in data.polygons);budget=18000 if 'facial planes' in ob.name else (12000 if 'eye' in ob.name.lower() else 1800)
 if tris>budget:
  mod=obj.modifiers.new('Candidate head budget','DECIMATE');mod.ratio=budget/tris;bpy.ops.object.modifier_apply(modifier=mod.name)
# Fit a tapered neck behind the jaw and inside the original collar, not a spherical plug.
neckmat=bpy.data.materials.new('Willow fitted neck skin');neckmat.use_nodes=True
bs=neckmat.node_tree.nodes.get('Principled BSDF');bs.inputs['Base Color'].default_value=(.48,.285,.16,1);bs.inputs['Roughness'].default_value=.64
verts=[];faces=[];rings=[(1.34,.058,.049,.024),(1.39,.047,.042,.015),(1.46,.041,.039,.005),(1.52,.041,.040,.0),(1.56,.047,.044,.0)]
for z,rx,ry,cy in rings:
 for i in range(48):
  a=math.tau*i/48;verts.append((-.015+rx*math.cos(a),cy+ry*math.sin(a),z))
for j in range(len(rings)-1):
 for i in range(48):a=j*48+i;b=j*48+(i+1)%48;faces.append((a,b,b+48,a+48))
data=bpy.data.meshes.new('Fitted neck');data.from_pydata(verts,[],faces);data.materials.append(neckmat);obj=bpy.data.objects.new('Repaired fitted neck',data);scene.collection.objects.link(obj);newparts.append(obj)
# Remove the appended collection and its unused clothed body; retain only repaired components.
for ob in list(col.objects):bpy.data.objects.remove(ob,do_unlink=True)
bpy.data.collections.remove(col)
for o in [body]+newparts:
 for p in o.data.polygons:p.use_smooth=True
render('after-face',(0,-.01,1.59),(0,-2,.05),.52)
render('after-three-quarter',(-.015,-.01,1.61),(1,-2,.03),.52)
render('after-full',(0,0,.90),(.3,-4,.25),2.08)
# Source includes studio for further manual review. Export only the repaired candidate.
bpy.ops.object.select_all(action='DESELECT')
for o in [body]+newparts:o.select_set(True)
bpy.context.view_layer.objects.active=body
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'willow-repaired.blend'))
bpy.ops.export_scene.gltf(filepath=str(OUT/'willow-repaired.glb'),export_format='GLB',use_selection=True,export_animations=False,export_yup=True)
(OUT/'report.json').write_text(json.dumps({'source':SOURCE.name,'status':'offline candidate, not the playable traveler','repair':'Removed damaged head/neck; fitted clean cycle-30 Willow face, eyes, ears, hair and neck','preserved':'Front figure clothing, equipment and source textures','remaining':['Clothing has unpainted atlas patches','Generated hands and equipment are fused','Collar opening needs manual reconstruction','Body needs retopology and skinning before replacing playable Willow'],'meshes':1+len(newparts)},indent=2))
print('WILLOW_REPAIR_COMPLETE')
