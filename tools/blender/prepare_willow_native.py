"""Rig the approved native-textured Rodin Willow without repainting or reshaping her.
Blender --background --factory-startup --python-exit-code 1 --python tools/blender/prepare_willow_native.py
The 14 independent rest bones are driven by Godot's authored_traveler proxy joints.
"""
import bpy,bmesh,sys,json,hashlib
import numpy as np
from pathlib import Path
from mathutils import Vector
from mathutils.bvhtree import BVHTree
R=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(Path(__file__).parent))
from rodin_party_weights import bind
OUT=R/'art/blender/willow_rodin_v2';SOURCE=OUT/'source.glb'
BONES=['Body','Torso','Head','Cape','LeftLeg','LeftKnee','LeftArm','LeftElbow','LeftHand','RightLeg','RightKnee','RightArm','RightElbow','RightHand']
def smooth(t):
 t=np.clip(t,0,1);return t*t*(3-2*t)
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
bpy.ops.import_scene.gltf(filepath=str(SOURCE))
objects=[o for o in bpy.context.scene.objects if o.type=='MESH']
assert len(objects)==1,'Expected the approved single traveler, not a sheet of figures'
o=objects[0];bpy.context.view_layer.objects.active=o;o.select_set(True)
bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
before_weld=len(o.data.vertices)
bm=bmesh.new();bm.from_mesh(o.data);bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=1e-6);bm.to_mesh(o.data);bm.free()
print('WELDED UV SEAMS',before_weld-len(o.data.vertices),flush=True)
me=o.data;P=np.array([v.co[:] for v in me.vertices]);lo=P.min(0);hi=P.max(0)
center=(lo+hi)/2;center[2]=lo[2];scale=2.06/(hi[2]-lo[2]);P=(P-center)*scale
me.vertices.foreach_set('co',P.ravel());me.update()
assert len(me.materials)==1
material=me.materials[0];material.name='Willow Native PBR'
image_roles={}
for n in material.node_tree.nodes:
 if n.type!='TEX_IMAGE':continue
 name=n.image.name.lower()
 role='normal' if 'normal' in name else 'metallic_roughness' if 'roughness' in name else 'albedo'
 n.image.name='willow_v2_'+role;image_roles[role]=n.image
assert set(image_roles)=={'albedo','normal','metallic_roughness'}
# Source color is used only to keep cape cloth attached to its collar. UVs, image
# pixels, normals and the approved mesh geometry are never repainted or rebuilt.
im=image_roles['albedo'];rgba=np.array(im.pixels[:]).reshape(im.size[1],im.size[0],4)
uv=np.array([v.uv[:] for v in me.uv_layers.active.data]);loops=np.array([l.vertex_index for l in me.loops])
colors=rgba[np.clip((uv[:,1]*im.size[1]).astype(int),0,im.size[1]-1),np.clip((uv[:,0]*im.size[0]).astype(int),0,im.size[0]-1),:3]
C=np.zeros((len(P),3));count=np.bincount(loops,minlength=len(P))
for c in range(3):C[:,c]=np.bincount(loops,weights=colors[:,c],minlength=len(P))/np.maximum(count,1)
X,Y,Z=P.T
cape=(C[:,1]>C[:,0]*1.015)&(C[:,1]>C[:,2]*1.055)&(Z>1.34)&(Z<1.78)
# The front is -Y in Blender, +Z after glTF Y-up export.
bvh=BVHTree.FromPolygons([Vector(p) for p in P],[list(p.vertices) for p in me.polygons])
def pivot(x,z):
 start=Vector((x,-1,z));hits=[]
 for _ in range(12):
  loc,normal,index,distance=bvh.ray_cast(start,Vector((0,1,0)),3)
  if loc is None:break
  hits.append(loc.y);start=loc+Vector((0,.0001,0))
 near=P[(abs(X-x)<.045)&(abs(Z-z)<.035)]
 assert len(near),'Joint misses the source mesh: '+str((x,z))
 depth=(hits[0]+hits[1])/2 if len(hits)>=2 else float(np.median(near[:,1]))
 return np.array([x,depth,z])
points={'Body':pivot(0,1.085),'Torso':pivot(0,1.28),'Head':pivot(0,1.745),'Cape':np.array([0,.045,1.71])}
for side,sign in [('Left',-1),('Right',1)]:
 points.update({side+'Leg':pivot(sign*.12,1.07),side+'Knee':pivot(sign*.145,.63),side+'Arm':pivot(sign*.205,1.53),side+'Elbow':pivot(sign*.305,1.30),side+'Hand':pivot(sign*.377,1.095)})
arms=[]
for side,sign in [('Left',-1),('Right',1)]:
 # Restrict bone seeds to the visible limb; geodesic distance follows the surface.
 threshold=np.interp(Z,[.8,1.12,1.3,1.5,1.7],[.31,.31,.235,.165,.19])
 arms.append((X*sign>threshold)&(Z>.85)&(Z<1.62)&~cape)
names=['pants','cloth','shirt','skin','hair'];labels=np.full(len(P),names.index('shirt'))
labels[Z<1.18]=names.index('pants');labels[cape]=names.index('cloth')
for mask in arms:labels[mask]=names.index('skin')
labels[Z>1.74]=names.index('skin')
gear=np.zeros(len(P),bool)
# Small disconnected surface details (boot laces, cuffs, pouch stitching) still
# need the nearest body's motion. Join their skinning graph, not their geometry.
edges=[tuple(e.vertices) for e in me.edges]
parent=list(range(len(P)))
def find(i):
 while parent[i]!=i:
  parent[i]=parent[parent[i]];i=parent[i]
 return i
for a,b in edges:
 a,b=find(a),find(b)
 if a!=b:parent[b]=a
components={}
for i in range(len(P)):components.setdefault(find(i),[]).append(i)
from mathutils.kdtree import KDTree
groups=sorted(components.values(),key=len,reverse=True)
print('SURFACE COMPONENTS',len(groups),[len(g) for g in groups[:20]],flush=True)
attached=list(groups[0]);graph_bridges=[]
for ids in groups[1:]:
 tree=KDTree(len(attached))
 for i in attached:tree.insert(Vector(P[i]),i)
 tree.balance()
 best=None
 for i in ids:
  co,j,d=tree.find(Vector(P[i]))
  if best is None or d<best[0]:best=(d,i,j)
 graph_bridges.append((best[1],best[2]));attached.extend(ids)
weights=bind(P,edges+graph_bridges,points,BONES,arms,cape,gear,labels,names)
bi={n:i for i,n in enumerate(BONES)}
# Neck-to-head blending ends below the jaw; no face vertex follows a sleeve/cape.
neck=(abs(X)<.17)&(Z>1.66)&~cape
head_amount=smooth((Z-1.66)/.08)
weights[neck]*=(1-head_amount[neck,None]);weights[neck,bi['Head']]+=head_amount[neck]
head=Z>1.76;weights[head]=0;weights[head,bi['Head']]=1
# Keep the waist/sash/pouch out of moving-arm weights, using the gap in this A-pose.
arm_cols=np.array([any(s in n for s in ['Arm','Elbow','Hand']) for n in BONES])
waist=(abs(X)<.30)&(Z<1.27)
weights[np.ix_(waist,arm_cols)]=0
for side,mask in zip(['Left','Right'],arms):
 wrist=points[side+'Hand'];direction=wrist-points[side+'Elbow'];direction/=np.linalg.norm(direction)
 hand=mask&((P-wrist)@direction>-.03)&(np.linalg.norm(P-wrist,axis=1)<.21)
 weights[hand]=0;weights[hand,bi[side+'Hand']]=1
opposite_cols={side:np.array([n.startswith(side) and any(s in n for s in ['Arm','Elbow','Hand']) for n in BONES]) for side in ['Left','Right']}
for side,sign in [('Left',-1),('Right',1)]:weights[np.ix_(X*sign<0,opposite_cols[side])]=0
empty=weights.sum(1)<1e-8;weights[empty,bi['Body']]=1
order=np.argsort(weights,axis=1)[:,:-4];np.put_along_axis(weights,order,0,axis=1);weights/=weights.sum(1)[:,None]
for j,name in enumerate(BONES):
 g=o.vertex_groups.new(name=name)
 for i in np.nonzero(weights[:,j]>1e-6)[0]:g.add([int(i)],float(weights[i,j]),'REPLACE')
fingers=[]
for side in ['Left','Right']:
 me=o.data;wrist=points[side+'Hand'];direction=wrist-points[side+'Elbow'];direction/=np.linalg.norm(direction)
 group=o.vertex_groups[side+'Hand'].index
 # Hide the same open-hand region replaced by the existing procedural tool grip.
 ids={v.index for v in me.vertices if (np.array(v.co[:])-wrist)@direction>.015 and any(g.group==group and g.weight>.99 for g in v.groups)}
 for v in me.vertices:v.select=False
 for e in me.edges:e.select=False
 for p in me.polygons:p.select=all(v in ids for v in p.vertices)
 assert any(p.select for p in me.polygons),'Missing open fingers: '+side
 bpy.context.tool_settings.mesh_select_mode=(False,False,True)
 before=set(bpy.context.scene.objects);bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.separate(type='SELECTED');bpy.ops.object.mode_set(mode='OBJECT')
 f=next(iter(set(bpy.context.scene.objects)-before));f.name=side+'Fingers';fingers.append(f)
 bpy.ops.object.select_all(action='DESELECT');o.select_set(True);bpy.context.view_layer.objects.active=o
o.name='RodinTraveler';meshes=[o]+fingers
armdata=bpy.data.armatures.new('TravelerRig');arm=bpy.data.objects.new('TravelerRig',armdata);bpy.context.scene.collection.objects.link(arm)
bpy.ops.object.select_all(action='DESELECT');arm.select_set(True);bpy.context.view_layer.objects.active=arm;bpy.ops.object.mode_set(mode='EDIT')
for name in BONES:
 b=armdata.edit_bones.new(name);b.head=Vector(points[name]);b.tail=b.head+Vector((0,0,.1))
bpy.ops.object.mode_set(mode='OBJECT')
for mesh in meshes:
 mod=mesh.modifiers.new('Traveler skin','ARMATURE');mod.object=arm;mesh.parent=arm
 mesh['rodin_design']=0;mesh['native_textures']=True;mesh.select_set(True)
arm['generation_id']='3b634674-2581-4ad0-89b0-800cc23fb916'
path=R/'assets/characters/willow_scout.glb'
bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,export_animations=False,export_skins=True,export_all_influences=False,export_def_bones=True,export_materials='EXPORT',export_attributes=False,export_yup=True,export_extras=True)
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'willow_scout.blend'))
report={'source':'source.glb','source_sha256':hashlib.sha256(SOURCE.read_bytes()).hexdigest(),'generation_id':arm['generation_id'],'height_m':2.06,'normalization_scale':float(scale),'normalization_center':center.tolist(),'triangles':sum(len(p.vertices)-2 for q in meshes for p in q.data.polygons),'bones':BONES,'points':{n:p.tolist() for n,p in points.items()},'max_weights':int((weights>1e-6).sum(1).max()),'open_finger_meshes':[q.name for q in fingers],'native_material':material.name,'textures':{role:{'name':im.name,'size':list(im.size)} for role,im in image_roles.items()},'welded_seam_vertices':before_weld-len(P),'surface_component_sizes':[len(g) for g in groups],'skinning_graph_bridges':len(graph_bridges),'shape_changes':'Uniform normalization, coincident UV seam welding (1e-6 tolerance), and finger surface separation. Graph bridges affect skinning only. No face repaint, remesh or decimation.','bytes':path.stat().st_size}
(OUT/'report.json').write_text(json.dumps(report,indent=2)+'\n');print('WILLOW NATIVE READY',json.dumps(report),flush=True)
