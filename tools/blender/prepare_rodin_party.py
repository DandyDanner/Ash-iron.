"""Prepare Dallon's four full-size Rodin travelers; discard miniature sheet figures.
Blender --background --factory-startup --python tools/blender/prepare_rodin_party.py -- [source.glb] [--only=0] [--no-render]
Clean authored surface colors, measured joints, isolated open fingers and soft cape weights.
"""
import bpy,bmesh,sys,json,hashlib,math
import numpy as np
from pathlib import Path
from mathutils import Vector
from mathutils.bvhtree import BVHTree
R=Path(__file__).resolve().parents[2];sys.path.insert(0,str(Path(__file__).parent))
from rodin_party_regions import PALETTES,FRONT,BACK,JOINTS,ARM_REGIONS
from rodin_party_texture import texture
from rodin_party_weights import bind
from willow_equipment_cleanup import remove_archery
ARGS=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else []
SOURCE=Path(next((a for a in ARGS if not a.startswith('--')),'/Users/dallonanderson/Downloads/Travelers.glb'))
ONLY=int(next((a.split('=')[1] for a in ARGS if a.startswith('--only=')),-1))
SLUGS=['willow_scout','hearthland_ranger','ridge_wayfarer','ember_forager']
OUT=R/'art/blender/rodin_party';OUT.mkdir(parents=True,exist_ok=True);(OUT/'.gdignore').touch()
REVIEW=R/'docs/art/rodin-party';REVIEW.mkdir(parents=True,exist_ok=True);(REVIEW/'.gdignore').touch()
BONES=['Body','Torso','Head','Cape','LeftLeg','LeftKnee','LeftArm','LeftElbow','LeftHand','RightLeg','RightKnee','RightArm','RightElbow','RightHand']
S=900/2.3

def smooth(t):
 t=np.clip(t,0,1);return t*t*(3-2*t)
def lin(h):
 c=np.array([int(h[j:j+2],16)/255 for j in (0,2,4)]);return np.where(c>.04045,((c+.055)/1.055)**2.4,c/12.92)
def polygon(x,y,poly):
 inside=np.zeros(len(x),dtype=bool)
 for (a,b),(c,d) in zip(poly,poly[1:]+poly[:1]):
  inside^=((b>y)!=(d>y))&(x<(c-a)*(y-b)/(d-b+1e-12)+a)
 return inside

def paint(P,k,N=None):
 x=300+P[:,0]*S;y=450-(P[:,2]-1.03)*S;xb=600-x
 X,Y,Z=P.T;back=((N[:,1]>.12)&(Y>.045)) if N is not None else (Y>.06);names=list(PALETTES[k]);labels=np.full(len(P),names.index('pants'),dtype=np.int32)
 def put(m,n):labels[m]=names.index(n)
 put(y<447,'shirt');put(y<214,'skin')
 put(y>700,'leather');put(y>821,'sole')
 put(y<196,'skin');put((y<178)&back,'hair')
 arms=[polygon(x,y,p) for p in ARM_REGIONS[k]]
 for mask in arms:put(mask,'skin')
 for name,poly in FRONT[k]:put(polygon(x,y,poly),name)
 for name,poly in BACK[k]:put(polygon(xb,y,poly)&back,name)
 # Material on the far side of each pack/roll must also reach the front-visible edge.
 if k==1:
  put((Y>.08)&(y>144)&(y<211)&(x>367),'cloth')
  put((Y>.17)&(y>211)&(y<408),'leather')
 if k==2:
  put((Y>.19)&(y>143)&(y<213),'wrap')
  put((Y>.21)&(y>211)&(y<425),'leather')
  put(polygon(x,y,[(191,276),(211,263),(230,270),(235,298),(224,312),(196,310)])&(Y<.02),'skin')
 if k==3:
  put((Y>.12)&(y>213)&(y<405),'wood')
  put((Y>.10)&(y>170)&(y<242),'cloth')
 # Clean exposed forearms independently of the pack and shirt strokes.
 bounds=[[(376,419),(380,430)],[(375,510),(375,510)],[(274,312),(374,396)],[(339,415),(338,417)]][k]
 for i,(low,high) in enumerate(bounds):
  put(arms[i]&(y>low)&(y<high),'skin')
 if k==1:
  put(polygon(x,y,[(398,143),(455,141),(479,189),(462,214),(403,205)]),'cloth')
  put(polygon(x,y,[(424,215),(452,218),(470,259),(461,307),(436,302)]),'leather')
 # Ranger's scarf stroke must not paint over the side of his jaw/ear.
 if k==1:
  cheek=(X>-.17)&(X<.20)&(Y<.17)&(Z>1.78)&(Z<1.91)&(labels!=names.index('hair'))
  put(cheek,'skin')
 # Soft, small variation comes from the 3D position, not shadows in an illustration.
 color=np.array([lin(PALETTES[k][n]) for n in names])[labels]
 grain=np.sin(X*125+np.sin(Z*81))*np.sin(Y*119-Z*93)
 color*=1+grain[:,None]*.012
 if k==1:
  beard=(labels==names.index('hair'))&(y>136)&(y<172)
  color[beard]=color[beard]*.35+lin(PALETTES[k]['skin'])*.65
 # Face accents are painted on the sculpt, below the hair and on front-facing skin.
 face=(labels==names.index('skin'))&(Y<.10)&(Z>1.7)
 eyes=[[(332,123,10,4),(364,124,6,3.5)],[(306,105,9,4),(342,106,6,4)],[(308,96,9,4),(343,97,6,4)],[(283,119,10,4.5),(323,123,8,4)]][k]
 for ex,ey,rx,ry in eyes:
  u=(x-ex)/rx;v=(y-ey)/ry;shape=(abs(u)<1)&(abs(v)<(1-u*u)*.85)
  m=face&shape;color[m]=lin(PALETTES[k]['eyes'])*(0.80+0.20*np.clip(v[m]+.4,0,1))[:,None]
  r=np.sqrt(((x-(ex+1.1))/(ry*.82))**2+((y-ey)/(ry*.92))**2)
  m=face&shape&(r<1);color[m]=lin(PALETTES[k]['iris'])*(1-.25*np.clip(r[m],0,1)+.09*np.sin(np.arctan2(y[m]-ey,x[m]-ex)*18))[:,None]
  m=face&shape&(r<.43);color[m]=lin(PALETTES[k]['pupil'])
  m=face&shape&(((x-ex)/.65)**2+((y-ey+1.1)/.65)**2<1);color[m]=lin('ded6c4')
  lid=face&shape&(v<-.48);color[lid]=color[lid]*.35+lin(PALETTES[k]['hair'])*.65
  brow=face&(abs(u)<1.1)&(abs(y-(ey-6+.8*u))<.7);color[brow]=lin(PALETTES[k]['hair'])*.9
 mouth=[(350,155,10),(325,142,10),(325,133,10),(302,156,10)][k]
 mx,my,rx=mouth;lip=face&(abs(x-mx)<rx)&(abs(y-(my+.018*(x-mx)**2))<1.0)
 color[lip]=color[lip]*.58+lin(['9a6451','81503a','563527','a56c59'][k])*.42
 if k==3:
  for fx,fy in [(277,135),(281,136),(285,134),(288,136),(319,138),(325,140),(329,137)]:
   m=face&((x-fx)**2+(y-fy)**2<.32);color[m]*=.60
 # Stitched edging belongs to the cloth surface, never crossing onto skin or gear.
 edges={0:[((209,294),(272,247)),((366,317),(449,289))],2:[((268,401),(480,298))],3:[((236,531),(343,459))]}.get(k,[])
 for a,b in edges:
  dx,dy=b[0]-a[0],b[1]-a[1];t=np.clip(((x-a[0])*dx+(y-a[1])*dy)/(dx*dx+dy*dy),0,1)
  dist=np.sqrt((x-a[0]-t*dx)**2+(y-a[1]-t*dy)**2)
  m=(labels==names.index('cloth'))&(Y<.08)&(dist<1.25);color[m]=lin(PALETTES[k]['trim'])
 return labels,color,arms,names

def bone_point(P,px,py):
 x=(px-300)/S;z=1.03+(450-py)/S
 d=(P[:,0]-x)**2+(P[:,2]-z)**2
 near=P[np.argsort(d)[:90]]
 hits=[];start=Vector((x,-2,z))
 for _ in range(16):
  location,normal,index,distance=BVH.ray_cast(start,Vector((0,1,0)),4)
  if location is None:break
  hits.append(location.y);start=location+Vector((0,.0002,0))
 # First solid interval is the visible body/limb, before any backpack behind it.
 depth=(hits[0]+hits[1])*.5 if len(hits)>=2 else float(np.median(near[:,1]))
 return np.array([x,depth,z])

def closest(P,a,b):
 v=b-a;t=np.clip((P-a)@v/(v@v),0,1);Q=a+t[:,None]*v;return np.linalg.norm(P-Q,axis=1),t

def material(name):
 m=bpy.data.materials.new('Rodin '+name);m.use_nodes=True;p=m.node_tree.nodes.get('Principled BSDF')
 p.inputs['Roughness'].default_value=.83 if name not in ['Skin','Eyes','Metal'] else {'Skin':.68,'Eyes':.32,'Metal':.45}[name]
 if name=='Metal':p.inputs['Metallic'].default_value=.55
 a=m.node_tree.nodes.new('ShaderNodeVertexColor');a.layer_name='GameColor';m.node_tree.links.new(a.outputs['Color'],p.inputs['Base Color']);m.use_backface_culling=False
 return m

bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
bpy.ops.import_scene.gltf(filepath=str(SOURCE))
meshes=[o for o in bpy.context.scene.objects if o.type=='MESH']
for o in meshes:
 bpy.context.view_layer.objects.active=o;o.select_set(True);bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
bpy.context.view_layer.objects.active=meshes[0];bpy.ops.object.join();obj=bpy.context.object
bm=bmesh.new();bm.from_mesh(obj.data);bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=1e-6);bm.to_mesh(obj.data);bm.free()
bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT');bpy.ops.mesh.separate(type='LOOSE');bpy.ops.object.mode_set(mode='OBJECT')
all_mesh=[o for o in bpy.context.scene.objects if o.type=='MESH'];largest=sorted(all_mesh,key=lambda o:len(o.data.vertices),reverse=True)[:4]
figs=sorted(largest,key=lambda o:sum(v.co.x for v in o.data.vertices)/len(o.data.vertices))
assert len(figs)==4 and min(len(o.data.vertices) for o in figs)>30000,'Expected four full-size figures'
for o in list(bpy.context.scene.objects):
 if o not in figs:bpy.data.objects.remove(o,do_unlink=True)
for o in figs:o.hide_render=True;o.hide_set(True)
source_hash=hashlib.sha256(SOURCE.read_bytes()).hexdigest()
for k,o in enumerate(figs):
 if ONLY>=0 and k!=ONLY:continue
 o.hide_render=False;o.hide_set(False);bpy.ops.object.select_all(action='DESELECT');o.select_set(True);bpy.context.view_layer.objects.active=o
 P=np.array([v.co[:] for v in o.data.vertices]);P[:,2]-=P[:,2].min();h=P[:,2].max();band=P[(P[:,2]>.25*h)&(P[:,2]<.35*h)];P[:,0]-=np.median(band[:,0]);waist=P[(P[:,2]>.55*h)&(P[:,2]<.62*h)&(abs(P[:,0])<.08*h)];P[:,1]-=np.median(waist[:,1]);crown=P[(abs(P[:,0])<.09*h)&(abs(P[:,1])<.13*h)];P*=2.06/crown[:,2].max();o.data.vertices.foreach_set('co',P.ravel());o.data.update()
 original=sum(len(p.vertices)-2 for p in o.data.polygons)
 if original>90000:
  dec=o.modifiers.new('Game mesh budget','DECIMATE');dec.ratio=90000/original;bpy.ops.object.modifier_apply(modifier=dec.name)
 equipment_cleanup=remove_archery(o,paint) if k==0 else {}
 me=o.data;P=np.array([v.co[:] for v in me.vertices]);X,Y,Z=P.T
 if k==1:
  # Local sculpt correction, centered from rays through the offending jaw lobe.
  # The feathered volume excludes the nose, eyes, scarf and backpack.
  distance=((X-.115)/.065)**2+((Y+.105)/.085)**2+((Z-1.815)/.06)**2
  influence=np.exp(-distance)*smooth((Z-1.72)/.06)*(1-smooth((Z-1.86)/.055))
  influence*=((abs(X)<.22)&(Y<.04))
  P[:,0]-=.011*influence;P[:,1]-=.006*influence
  me.vertices.foreach_set('co',P.ravel());me.update()
  region=o.vertex_groups.new(name='Jaw sculpt falloff')
  for i in np.nonzero(influence>.001)[0]:region.add([int(i)],float(influence[i]),'REPLACE')
  sculpt=o.modifiers.new('Relax the jaw surface','SMOOTH');sculpt.vertex_group=region.name;sculpt.factor=.5;sculpt.iterations=10
  bpy.ops.object.modifier_apply(modifier=sculpt.name);o.vertex_groups.remove(o.vertex_groups['Jaw sculpt falloff'])
  me=o.data;P=np.array([v.co[:] for v in me.vertices]);X,Y,Z=P.T

 BVH=BVHTree.FromPolygons([Vector(v) for v in P],[list(p.vertices) for p in me.polygons])
 labels,col,arm_masks,names=paint(P,k,np.array([v.normal[:] for v in me.vertices]))
 points={n:bone_point(P,*p) for n,p in JOINTS[k].items()}
 hip=(points['LeftLeg']+points['RightLeg'])/2
 points.update(Body=hip,Torso=np.array([hip[0],hip[1],1.25]),Head=bone_point(P,310,176),Cape=np.array([hip[0],.05,1.72]))
 # Classify rigid equipment on the back and the sculpted bow/pick independently of limbs.
 lab=lambda n:labels==names.index(n)
 head=(Z>1.70)&(np.abs(X-.035)<.28)&~lab('wood')&~lab('metal')
 gear=((Y>.15)&(Z>1.05)&~head&~(arm_masks[0]|arm_masks[1]))|(lab('wood')&~lab('skin'))|(lab('metal')&(Z>1.7))
 # A cape stays attached at its collar; only its lower cloth receives secondary motion.
 cape=(lab('cloth')&(Z>1.15)&(Z<1.78)&~gear) if k in (0,2) else np.zeros(len(P),bool)
 if k==0:cape&=Z>1.37
 weights=bind(P,[e.vertices[:] for e in me.edges],points,BONES,arm_masks,cape,gear,labels,names)
 bi={n:i for i,n in enumerate(BONES)}
 # A jaw is part of the rigid skull. Surface distances alone can bind it to
 # a touching scarf and leave half the face behind when the head turns.
 neck_skin=(lab('skin')|lab('hair'))&(abs(X)<.25)&(Y<.17)&(Z>1.64)
 head_amount=smooth((Z-1.64)/.08)
 weights[neck_skin]*=(1-head_amount[neck_skin,None])
 weights[neck_skin,bi['Head']]+=head_amount[neck_skin]
 if k==1:
  # Include the full jaw volume, including vertices on scarf/skin material borders.
  skull=(Z>1.76)&(abs(X)<.24)&(Y<.23)
  weights[skull]=0;weights[skull,bi['Head']]=1
 # A palm/finger surface must follow its hand rigidly, including where it touches cloth.
 for idx,side in enumerate(['Left','Right']):
  wrist=points[side+'Hand'];direction=wrist-points[side+'Elbow'];direction/=np.linalg.norm(direction)
  palm=arm_masks[idx]&(labels==names.index('skin'))&((P-wrist)@direction>-.035)&(np.linalg.norm(P-wrist,axis=1)<.22)
  weights[palm]=0;weights[palm,bi[side+'Hand']]=1
 # Contact surfaces belong to either the arm or the garment, never both.
 # Blending these disconnected body parts creates rubber webs when a tool is raised.
 arm_columns=np.array([any(t in n for t in ['Arm','Elbow','Hand']) for n in BONES])
 contact=(Z>.70)&(Z<1.30)
 arm_total=weights[:,arm_columns].sum(axis=1)
 arm_total[contact&(abs(X)<.12)]=0
 for use_arm in [False,True]:
  rows=contact&((arm_total>=.5)==use_arm)
  weights[np.ix_(rows,arm_columns!=use_arm)]=0
 # The two separated arms cannot pull on the opposite side of the waist.
 for side,sign in [('Left',1),('Right',-1)]:
  opposite=(X*sign>0)&(Z<1.50)
  columns=np.array([n.startswith(side) and any(t in n for t in ['Arm','Elbow','Hand']) for n in BONES])
  weights[np.ix_(opposite,columns)]=0
 order=np.argsort(weights,axis=1)[:,:-4];np.put_along_axis(weights,order,0,axis=1)
 empty=weights.sum(axis=1)<1e-8;weights[empty,bi['Body']]=1
 weights/=weights.sum(axis=1,keepdims=True)
 for n in BONES:
  g=o.vertex_groups.new(name=n)
  for i in np.nonzero(weights[:,bi[n]]>1e-5)[0]:g.add([int(i)],float(weights[i,bi[n]]),'REPLACE')
 # Keep all skin vertices in a single palette; material boundaries stay crisp.
 loops=np.array([l.vertex_index for l in me.loops]);attr=me.color_attributes.new(name='GameColor',type='FLOAT_COLOR',domain='CORNER');attr.data.foreach_set('color',np.column_stack((col[loops],np.ones(len(loops)))).ravel());me.color_attributes.active_color=attr
 matnames=['Fabric','Skin','Hair','Leather','Metal','Eyes'];me.materials.clear()
 for n in matnames:me.materials.append(material(n))
 cat={n:0 for n in names};cat.update(skin=1,hair=2,leather=3,sole=3,wood=3,metal=4,eyes=5,iris=5,pupil=5)
 for p in me.polygons:p.material_index=cat[names[int(np.bincount(labels[list(p.vertices)],minlength=len(names)).argmax())]];p.use_smooth=True
 texture(o,paint,k,OUT/(SLUGS[k]+'_albedo.png'))
 # Rodin sometimes joins a hanging hand to the hip/apron with a thin skin web.
 # Those are not anatomical joints: cut only cross-influence faces at hip height.
 bm=bmesh.new();bm.from_mesh(o.data);deform=bm.verts.layers.deform.active
 arm_ids={o.vertex_groups[n].index for n in BONES if any(t in n for t in ['Arm','Elbow','Hand'])}
 cuts=[]
 for f in bm.faces:
  if not any(.70<v.co.z<1.30 for v in f.verts):continue
  amount=[sum(w for g,w in v[deform].items() if g in arm_ids) for v in f.verts]
  if min(amount)<.45 and max(amount)>.55:cuts.append(f)
 bmesh.ops.delete(bm,geom=cuts,context='FACES');bm.to_mesh(o.data);bm.free()
 print('REMOVED HAND/HIP WEB FACES',k,len(cuts),flush=True)
 # Separate the lower open fingers; a held tool uses the existing closed grip.
 finger_sets=[]
 for idx,side in enumerate(['Left','Right']):
  wrist=points[side+'Hand'];direction=(wrist-points[side+'Elbow']);direction/=np.linalg.norm(direction)
  me=o.data
  group=o.vertex_groups[side+'Hand'].index
  ids={v.index for v in me.vertices if (np.array(v.co[:])-wrist)@direction>.017 and any(g.group==group and g.weight>.4 for g in v.groups)}
  faces=[p for p in me.polygons if all(v in ids for v in p.vertices)]
  for v in me.vertices:v.select=False
  for e in me.edges:e.select=False
  for p in me.polygons:p.select=False
  for p in faces:p.select=True
  bpy.context.tool_settings.mesh_select_mode=(False,False,True)
  if faces:
   before=set(bpy.context.scene.objects);bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.separate(type='SELECTED');bpy.ops.object.mode_set(mode='OBJECT');new=list(set(bpy.context.scene.objects)-before)[0];new.name=side+'Fingers';finger_sets.append(new)
   bpy.ops.object.select_all(action='DESELECT');o.select_set(True);bpy.context.view_layer.objects.active=o
 o.name='RodinTraveler';objects=[o]+finger_sets
 ad=bpy.data.armatures.new('TravelerRig');arm=bpy.data.objects.new('TravelerRig',ad);bpy.context.scene.collection.objects.link(arm);bpy.context.view_layer.objects.active=arm;o.select_set(False);arm.select_set(True);bpy.ops.object.mode_set(mode='EDIT')
 for n in BONES:b=ad.edit_bones.new(n);b.head=Vector(points[n]);b.tail=Vector(points[n])+Vector((0,0,.1))
 bpy.ops.object.mode_set(mode='OBJECT')
 for q in objects:
  mod=q.modifiers.new('Traveler skin','ARMATURE');mod.object=arm;q.parent=arm
  q['rodin_design']=k
 bpy.ops.object.select_all(action='DESELECT');arm.select_set(True)
 for q in objects:q.select_set(True)
 path=R/'assets/characters'/(SLUGS[k]+'.glb')
 bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,export_animations=False,export_skins=True,export_all_influences=False,export_def_bones=True,export_materials='EXPORT',export_attributes=False,export_yup=True,export_extras=True)
 # Save an editable character-only scene; other figures are excluded from the file.
 report=dict(source=SOURCE.name,sha256=source_hash,source_figure=k,**equipment_cleanup,discarded_miniatures=4,removed_hand_hip_web_faces=len(cuts),source_triangles=original,triangles=sum(len(p.vertices)-2 for q in objects for p in q.data.polygons),bones=BONES,points={n:points[n].tolist() for n in BONES},palette=PALETTES[k],open_finger_meshes=[q.name for q in finger_sets],cape_vertices=int(cape.sum()),max_weights=int((weights>1e-5).sum(1).max()),bytes=path.stat().st_size)
 (OUT/(SLUGS[k]+'.json')).write_text(json.dumps(report,indent=2)+'\n');print('PREPARED',SLUGS[k],json.dumps(report),flush=True)
 if '--no-render' not in ARGS:
  scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=20;scene.cycles.use_denoising=True;scene.world.color=(.08,.08,.08);scene.view_settings.view_transform='AgX';scene.render.resolution_x=600;scene.render.resolution_y=900;scene.render.resolution_percentage=100
  center=Vector((0,0,1.03));studio=[]
  for offset,energy in [((-3,-4,5),450),((4,-1,3),220),((0,4,4),450)]:
   bpy.ops.object.light_add(type='AREA',location=offset);l=bpy.context.object;studio.append(l);l.data.energy=energy;l.data.size=4;l.rotation_euler=(center-l.location).to_track_quat('-Z','Y').to_euler()
  bpy.ops.object.camera_add();cam=bpy.context.object;studio.append(cam);scene.camera=cam;cam.data.type='ORTHO'
  for name,offset,span,aim in [('front',(0,-4,0),2.3,center),('back',(0,4,0),2.3,center),('face',(0,-4,0),.52,Vector((.04,0,1.86)))]:
   cam.data.ortho_scale=span;cam.location=aim+Vector(offset);cam.rotation_euler=(aim-cam.location).to_track_quat('-Z','Y').to_euler();scene.render.filepath=str(REVIEW/(SLUGS[k]+'-'+name+'.png'));bpy.ops.render.render(write_still=True)
  for q in studio:bpy.data.objects.remove(q,do_unlink=True)
 for q in objects+[arm]:q.hide_render=True;q.hide_set(True)
if ONLY<0:
 for q in list(bpy.context.scene.objects):
  q.hide_render=False;q.hide_set(False)
 rigs=sorted([q for q in bpy.context.scene.objects if q.type=='ARMATURE'],key=lambda q:q.name)
 for i,q in enumerate(rigs):q.location.x=(i-1.5)*1.5
 bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'travelers.blend'))
print('RODIN PARTY COMPLETE',flush=True)
