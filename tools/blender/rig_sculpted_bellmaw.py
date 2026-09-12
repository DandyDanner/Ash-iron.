"""Prepare the largest creature in Dallon's new untextured Bellmaw sculpt. Blender 5.2.
Run: blender --background --factory-startup --python tools/blender/rig_sculpted_bellmaw.py -- /path/to/source.glb
Original input stays untouched. Runtime Skeleton3D uses the same anatomical controls.
"""
import bpy,bmesh,math,json,sys
import numpy as np
from pathlib import Path
from mathutils import Vector
R=Path(__file__).resolve().parents[2]
SOURCE=Path(sys.argv[sys.argv.index('--')+1]) if '--' in sys.argv else Path('/Users/dallonanderson/Downloads/Bellmaw.glb')
OUT=R/'art/blender/bellmaw_sculpt';OUT.mkdir(parents=True,exist_ok=True)
ASSET=R/'assets/creatures';ASSET.mkdir(parents=True,exist_ok=True)
REVIEW=R/'docs/art/sculpted-bellmaw';REVIEW.mkdir(parents=True,exist_ok=True)
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
bpy.ops.import_scene.gltf(filepath=str(SOURCE));obj=next(o for o in bpy.context.scene.objects if o.type=='MESH')
bm=bmesh.new();bm.from_mesh(obj.data);bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=.000005)
seen=set();parts=[]
for v in bm.verts:
 if v in seen:continue
 stack=[v];seen.add(v);group=[]
 while stack:
  q=stack.pop();group.append(q)
  for e in q.link_edges:
   w=e.other_vert(q)
   if w not in seen:seen.add(w);stack.append(w)
 parts.append(group)
keep=set(max(parts,key=len));bmesh.ops.delete(bm,geom=[v for v in bm.verts if v not in keep],context='VERTS')
bm.to_mesh(obj.data);bm.free();lo=Vector([min(v.co[i] for v in obj.data.vertices) for i in range(3)]);hi=Vector([max(v.co[i] for v in obj.data.vertices) for i in range(3)])
center=Vector(((lo.x+hi.x)*.5,(lo.y+hi.y)*.5,lo.z))
# Match the previous neutral height; actor scale 4 makes this twice the prior in-game height.
for v in obj.data.vertices:v.co=(v.co-center)*(1.34/(hi.z-lo.z))
obj.name='BellmawSkin';bpy.context.view_layer.objects.active=obj
mod=obj.modifiers.new('Gameplay mesh budget','DECIMATE');mod.ratio=54000/len(obj.data.polygons);bpy.ops.object.modifier_apply(modifier=mod.name)
# Source has no textures. Add portable vertex colors without borrowing the old UV atlas.
obj.data.materials.clear()
mat=bpy.data.materials.new('Bellmaw sculpted olive hide and amber throat');mat.use_nodes=True
bs=mat.node_tree.nodes.get('Principled BSDF');bs.inputs['Metallic'].default_value=0;bs.inputs['Roughness'].default_value=.8;bs.inputs['Specular IOR Level'].default_value=.22
colors=obj.data.color_attributes.new(name='HideColor',type='FLOAT_COLOR',domain='POINT')
vc=mat.node_tree.nodes.new('ShaderNodeVertexColor');vc.layer_name='HideColor';mat.node_tree.links.new(vc.outputs['Color'],bs.inputs['Base Color']);obj.data.materials.append(mat)
def blend(a,b,k):return tuple(a[i]*(1-k)+b[i]*k for i in range(3))
def soft(x):x=max(0,min(1,x));return x*x*(3-2*x)
for v in obj.data.vertices:
 x,y,z=v.co
 mottling=.5+.25*math.sin(x*17+z*11)*math.cos(y*13)+.15*math.sin(x*47-y*32+z*29)
 col=blend((.105,.135,.075),(.28,.30,.17),mottling)
 belly=(1-soft((z-.38)/.44))*(1-soft((abs(x)-.30)/.20))
 col=blend(col,(.26,.25,.13),belly*.55)
 throat=(1-soft((y+.91)/.27))*(1-soft((abs(x)-.35)/.18))*(1-soft((z-.79)/.16))*soft((z-.13)/.20)
 col=blend(col,blend((.29,.10,.028),(.64,.33,.07),mottling),throat)
 colors.data[v.index].color=(*col,1)
for p in obj.data.polygons:p.use_smooth=True
# Parallel rest axes simplify editable controls; hierarchy follows the animal.
points={'Root':(0,0,0),'Spine':(0,.05,.83),'Head':(0,-.73,1.04),'Throat':(0,-.98,.60)}
parents={'Spine':'Root','Head':'Spine','Throat':'Head'}
for side,x in [('L',-1),('R',1)]:
 for end,y in [('Front',-.68),('Rear',.87)]:
  key=end+side
  points[key+'Upper']=(x*.64,y,.83);points[key+'Lower']=(x*.84,y-.03,.37);points[key+'Foot']=(x*.84,y-.13,.085)
  parents[key+'Upper']='Spine';parents[key+'Lower']=key+'Upper';parents[key+'Foot']=key+'Lower'
armdata=bpy.data.armatures.new('BellmawRig');arm=bpy.data.objects.new('BellmawRig',armdata);bpy.context.collection.objects.link(arm);arm.show_in_front=True
bpy.context.view_layer.objects.active=arm;arm.select_set(True);obj.select_set(False);bpy.ops.object.mode_set(mode='EDIT')
for name,p in points.items():
 b=armdata.edit_bones.new(name);b.head=p;b.tail=Vector(p)+Vector((0,0,.16))
 if name in parents:b.parent=armdata.edit_bones[parents[name]]
bpy.ops.object.mode_set(mode='OBJECT')
def smooth(x):x=max(0,min(1,x));return x*x*(3-2*x)
groups={name:obj.vertex_groups.new(name=name) for name in points}
for v in obj.data.vertices:
 x,y,z=v.co;side='L' if x<0 else 'R';end='Front' if y<.1 else 'Rear';key=end+side
 # A broad torso blend prevents a hard seam at the shoulder/hip.
 limb=smooth((abs(x)-.43)/.29)*smooth((1.03-z)/.42)
 if end=='Rear':limb*=smooth((y-.18)/.35)
 else:limb*=1-smooth((y+.42)/.45)
 lower=1-smooth((z-.27)/.34);foot=1-smooth((z-.09)/.16)
 head=(1-smooth((y+.65)/.60))*(1-limb)
 throat=(1-smooth((y+1.01)/.39))*(1-smooth((z-.73)/.29))*(1-smooth((abs(x)-.43)/.21))
 throat=min(throat,1-limb);head=max(0,head-throat)
 weights={key+'Upper':limb*(1-lower),key+'Lower':limb*lower*(1-foot),key+'Foot':limb*lower*foot,'Throat':throat,'Head':head,'Spine':max(0,1-limb-head-throat)}
 # glTF/Godot uses four influences; prune tiny weights then normalize.
 active=sorted([(n,w) for n,w in weights.items() if w>1e-5],key=lambda p:p[1],reverse=True)[:4];total=sum(w for n,w in active)
 for n,w in active:groups[n].add([v.index],w/total,'REPLACE')
mod=obj.modifiers.new('Weighted Bellmaw skeleton','ARMATURE');mod.object=arm;obj.parent=arm
# Rest throat is less inflated than the upload; warning brings it up past source size.
# Bake the relaxed silhouette into the mesh so the bind pose is a true neutral pose.
for v in obj.data.vertices:
 weight=next((g.weight for g in v.groups if g.group==groups['Throat'].index),0)
 v.co=Vector(points['Throat'])+(v.co-Vector(points['Throat']))*(1-.10*weight)
# Authored editable loops. Runtime uses speed/state-driven poses to match combat exactly.
scene=bpy.context.scene;scene.render.fps=30
clips=[('Idle',60),('Walk',30),('Warning',36),('Recovery',38)]
for clip,last in clips:
 arm.animation_data_clear()
 for b in arm.pose.bones:b.rotation_mode='XYZ';b.rotation_euler=(0,0,0);b.location=(0,0,0);b.scale=(1,1,1)
 for f in range(1,last+2):
  t=(f-1)/30
  for b in arm.pose.bones:b.rotation_euler=(0,0,0);b.location=(0,0,0);b.scale=(1,1,1)
  arm.pose.bones['Spine'].location.y=math.sin(t*math.pi)*.012
  if clip=='Walk':
   for i,key in enumerate(['FrontL','RearL','FrontR','RearR']):
    wave=math.sin(t*math.tau+(math.pi if i in [1,2] else 0))
    arm.pose.bones[key+'Upper'].rotation_euler.x=wave*.16
    arm.pose.bones[key+'Lower'].rotation_euler.x=-wave*.12
    arm.pose.bones[key+'Foot'].rotation_euler.x=-wave*.04
  if clip=='Warning':
   k=min(1,t/1.2);arm.pose.bones['Throat'].scale=(1+.20*k,1+.22*k,1+.25*k)
   arm.pose.bones['Head'].rotation_euler.x=-.045*k
  if clip=='Recovery':
   k=math.exp(-t*4);arm.pose.bones['Throat'].scale=(1+.20*k,1+.22*k,1+.25*k);arm.pose.bones['Head'].rotation_euler.x=.08*math.sin(t*math.pi/1.25)
  for b in arm.pose.bones:
   b.keyframe_insert('location',frame=f);b.keyframe_insert('rotation_euler',frame=f);b.keyframe_insert('scale',frame=f)
 action=arm.animation_data.action;action.name=clip;action.use_fake_user=True
 track=arm.animation_data.nla_tracks.new();track.name=clip;track.strips.new(clip,1,action)
 # Stash survives animation_data_clear only via fake user. Collect later.
arm.animation_data_clear();arm.animation_data_create()
for clip,last in clips:
 action=bpy.data.actions[clip];track=arm.animation_data.nla_tracks.new();track.name=clip;track.strips.new(clip,1,action);track.mute=True
for b in arm.pose.bones:b.rotation_euler=(0,0,0);b.location=(0,0,0);b.scale=(1,1,1)
scene.frame_set(1)
bpy.ops.object.select_all(action='DESELECT');obj.select_set(True);arm.select_set(True);bpy.context.view_layer.objects.active=arm
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'bellmaw.blend'))
# Export actions directly, including the muted source stash.
bpy.ops.export_scene.gltf(filepath=str(ASSET/'bellmaw.glb'),export_format='GLB',use_selection=True,export_animations=True,export_animation_mode='ACTIONS',export_skins=True,export_yup=True)
report={'source_filename':SOURCE.name,'source_sha256':__import__('hashlib').sha256(SOURCE.read_bytes()).hexdigest(),'source_has_textures':False,'coloring':'authored olive/amber vertex colors','selected':'largest connected creature; other two and backpack removed','vertices':len(obj.data.vertices),'triangles':sum(len(p.vertices)-2 for p in obj.data.polygons),'bones':list(points),'clips':[c for c,n in clips],'source_bounds_dimensions':list(hi-lo), 'exported_bounds_dimensions_m':[max(v.co[i] for v in obj.data.vertices)-min(v.co[i] for v in obj.data.vertices) for i in (0,2,1)],'runtime_scale':4,'limitations':['Generated topology; no manual quad retopology','No foot IK; uneven slopes may slide','Creature face and rear toes retain source asymmetry']}
(OUT/'report.json').write_text(json.dumps(report,indent=2))
# True renders of the exported source geometry, never concept illustrations.
scene.render.engine='CYCLES';scene.cycles.device='CPU';scene.cycles.samples=24;scene.cycles.use_denoising=True;scene.render.resolution_x=1000;scene.render.resolution_y=800;scene.render.resolution_percentage=100;scene.world.color=(.16,.16,.16)
mat=bpy.data.materials.new('Review floor');mat.diffuse_color=(.10,.12,.13,1)
bpy.ops.mesh.primitive_plane_add(size=200);bpy.context.object.data.materials.append(mat)
center=Vector((0,0,.70))
for offset,energy,size in [((-3,-4,5),650,4),((4,-1,3),450,4),((0,4,4),850,3)]:
 bpy.ops.object.light_add(type='AREA',location=offset);light=bpy.context.object;light.data.energy=energy;light.data.shape='DISK';light.data.size=size;light.rotation_euler=(center-light.location).to_track_quat('-Z','Y').to_euler()
bpy.ops.object.camera_add(location=(3,-4,2.4));cam=bpy.context.object;scene.camera=cam;cam.data.type='ORTHO';cam.data.ortho_scale=3.8;cam.rotation_euler=(center-cam.location).to_track_quat('-Z','Y').to_euler()
for name,action,frame in [('idle','Idle',1),('walk','Walk',8),('warning','Warning',37)]:
 arm.animation_data.action=bpy.data.actions[action];scene.frame_set(frame);scene.render.filepath=str(REVIEW/(name+'.png'));bpy.ops.render.render(write_still=True)
print('BELLMAW_RIG_COMPLETE',json.dumps(report))
