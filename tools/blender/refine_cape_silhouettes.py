"""Author garment volumes over the saved cycle 22 models; no runtime changes."""
from pathlib import Path
import bpy,bmesh,math,sys,random
from mathutils import Vector
from mathutils.bvhtree import BVHTree
R=Path(__file__).resolve().parents[2]
PASS=int(next((a.split('=')[1] for a in sys.argv if a.startswith('--art-pass=')),'23'))
REV=int(next((a.split('=')[1] for a in sys.argv if a.startswith('--refinement=')),'4'))
OUT=R/'art/blender/cycles'/f'cycle_{PASS:02d}';OUT.mkdir(parents=True,exist_ok=True)
if (OUT/'characters.blend').exists():raise RuntimeError('Preserve saved models; choose fresh cycle')
bpy.ops.wm.open_mainfile(filepath=str(R/'art/blender/cycles/cycle_22/characters.blend'))
N=['WILLOW SCOUT','HEARTHLAND RANGER','RIDGE WAYFARER','EMBER FORAGER'];A=['BRISTLEBACK BOAR','WOODLAND HOG','RIDGEBACK BOAR','MEADOW BUCK']
COMMON=['Loose rolled linen sleeve','Rolled sleeve cuff']
CAPE=['Draped sage shoulder cape','Cape bound hem','Embroidered hem chevron','Cape brass eyelet','Cape leather fastening']
EXTRA={0:CAPE+['Gathered teal waist sash','Loose sash tail'],1:['Soft scarf wrap','Open ranger jacket'],2:CAPE+['Soft scarf wrap'],3:[]}
def match(name,parts):return any(name==p or name.startswith(p+'.') for p in parts)
if REV>=2:EXTRA[1]+=['Jacket back']
col=None;root=None

def mesh(name,vs,fs,mat,sub=1,thickness=0):
 d=bpy.data.meshes.new(name);d.from_pydata(vs,[],fs);d.update();bm=bmesh.new();bm.from_mesh(d);bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=1e-6) if REV>=2 else None;bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(d);bm.free()
 o=bpy.data.objects.new(name,d);col.objects.link(o);o.parent=root;d.materials.append(mat)
 for p in d.polygons:p.use_smooth=True
 if sub:m=o.modifiers.new('Soft fabric surface','SUBSURF');m.levels=sub;m.render_levels=sub
 if thickness:m=o.modifiers.new('Fabric edge thickness','SOLIDIFY');m.thickness=thickness
 return o

def grid(name,fn,nu,nv,mat,thickness=.002,sub=1):
 vs=[fn(i/nu,j/nv) for j in range(nv+1) for i in range(nu+1)];fs=[]
 for j in range(nv):
  for i in range(nu):a=j*(nu+1)+i;fs.append((a,a+1,a+nu+2,a+nu+1))
 return mesh(name,vs,fs,mat,sub,thickness)

def cord(name,pts,r,mat):
 d=bpy.data.curves.new(name,'CURVE');d.dimensions='3D';d.bevel_depth=r;d.bevel_resolution=3;d.use_fill_caps=True
 s=d.splines.new('POLY');s.points.add(len(pts)-1)
 for p,co in zip(s.points,pts):p.co=(*co,1)
 o=bpy.data.objects.new(name,d);col.objects.link(o);o.parent=root;d.materials.append(mat);return o

def cape(t,a,kind):
 wave=(.010*math.sin(5*a+.8*t)+.006*math.sin(9*a-4*t)+.003*math.sin(14*a+3*t))*t**1.5
 w=.063+.230*t+.035*math.sin(math.pi*t)+wave;d=.066+.085*t+wave
 drop=(.302 if kind==0 else .378-.052*math.sin(a)**2)*t**1.60
 z=1.515-drop-.023*math.cos(a+.7)*t*t+.009*math.sin(3*a)*t*t
 p=Vector((math.sin(a)*w,-math.cos(a)*d,z))
 for side in [-1,1]:
  start=Vector((side*.151,0,1.442));end=Vector((side*.267,-.005,1.188));axis=end-start;q=max(0,min(1,(p-start).dot(axis)/axis.length_squared));center=start+axis*q;center.x+=side*.010*math.sin(math.pi*q)
  radius=.041+.026*math.sin(math.pi*q)**.65+.006*q+.009;delta=p-center
  if delta.length<radius:p=center+delta.normalized()*radius
 return p

def make_cape(kind,outer,shade,trim):
 opening=.16 if kind==0 else 0
 def angle(u):return opening+u*(math.tau-2*opening)
 grid('Tailored shoulder cape' if kind==0 else 'Closed asymmetric wayfarer poncho',lambda u,t:cape(t,angle(u),kind),128,64,outer,.003)
 for t in [.012,.986]:cord('Bound tailored cape edge',[cape(t,angle(i/160),kind) for i in range(161)],.002,shade)
 for a in ([opening,math.tau-opening] if opening else []):cord('Cape opening seam',[cape(i/80,a,kind) for i in range(81)],.0015,shade)
 def raised(t,a):
  p=cape(t,a,kind);return p+Vector((math.sin(a)*.0014,-math.cos(a)*.0014,.0005))
 if kind==2:
  for lo,hi in [(.87,.889),(.965,.979)]:grid('Poncho woven border',lambda u,v:raised(lo+(hi-lo)*v,angle(u)),128,3,trim,.0004,0)
 for i in range(16 if kind==2 else 13):
  a=.31+i/((15 if kind==2 else 12))*(math.tau-.62)
  for side in [-1,1]:
   grid('Flat embroidered cape chevron',lambda u,v,a=a,side=side:raised(.944-.049*u, a+side*.073*(1-u)+(v-.5)*.012),12,2,trim,.0004,0)
 if kind==0:
  for side in [-1,1]:
   p=cape(.11,side*.33,kind)
   cord('Tailored cape fastening eyelet',[p+Vector((.009*math.cos(i/48*math.tau),-.003,.009*math.sin(i/48*math.tau))) for i in range(49)],.002,bpy.data.materials['Aged brass'])
  p=cape(.11,.33,kind);q=cape(.11,-.33,kind)
  cord('Tailored cape tie',[p.lerp(q,i/32)+Vector((0,-.009,-.007*math.sin(math.pi*i/32))) for i in range(33)],.0025,bpy.data.materials['Worn chestnut leather'])

def sleeve(side,mat,cuffmat):
 def surface(a,t):
  center=Vector((side*((.151+.116*t+.010*math.sin(math.pi*t)) if REV>=2 else (.175+.092*t+.006*math.sin(math.pi*t))), -.005*t,(1.442-.254*t) if REV>=2 else (1.432-.244*t)))
  rad=.041+.026*math.sin(math.pi*t)**.65+.006*t
  wrinkles=.003*math.sin(a*6+t*5)*math.sin(math.pi*t)+.003*math.sin(t*38+a*2)*math.exp(-((t-.8)/.23)**2)
  axis=Vector((side*.116,-.005,-.254)).normalized();across=Vector((1,0,side*.116/.254)).normalized();normal=axis.cross(across).normalized()
  return center+across*(math.cos(a)*(rad+wrinkles))+normal*(math.sin(a)*(rad*.90+wrinkles))
 grid('Gathered woven sleeve',lambda u,t:surface(u*math.tau,t),64,64,mat,.003)
 cord('Sleeve underarm seam',[surface(math.pi/2,i/80) for i in range(81)],.001,mat)
 center=Vector((side*.267,-.005,1.190))
 def cuff(u,v):
  a=u*math.tau;b=v*math.tau;r=.047+.009*math.cos(b)+.0018*math.sin(5*a+b)
  return center+Vector((math.cos(a)*r,math.sin(a)*r*.93,.015*math.sin(b)+.004*math.cos(a)))
 grid('Rolled fabric cuff volume',cuff,64,24,cuffmat,0)

CAPE_PARTS=['Tailored shoulder cape','Closed asymmetric wayfarer poncho','Bound tailored cape edge','Cape opening seam','Poncho woven border','Flat embroidered cape chevron','Tailored cape fastening eyelet','Tailored cape tie']
for kind in [0,2]:
 name=N[kind];col=bpy.data.collections[name+' — authored study'];root=next(o for o in col.objects if o.type=='EMPTY')
 outer=bpy.data.materials[name+' outer cloth'];shade=bpy.data.materials.get(name+' fold shade') or bpy.data.materials.get(name+' tailored seam shade');trim=bpy.data.materials['Flax stitching']
 for o in list(col.objects):
  if match(o.name,CAPE_PARTS):bpy.data.objects.remove(o,do_unlink=True)
 if REV>=5:
  for o in list(col.objects):
   if match(o.name,['Open linen collar']):bpy.data.objects.remove(o,do_unlink=True)
 make_cape(kind,outer,shade,trim)
 bpy.context.view_layer.update();verts=[];faces=[]
 for o in col.objects:
  if o.type!='MESH' or not match(o.name,['Tailored shoulder cape','Closed asymmetric wayfarer poncho','Linen shirt','Overlapping gathered teal sash']):continue
  ev=o.evaluated_get(bpy.context.evaluated_depsgraph_get());md=ev.to_mesh();offset=len(verts);local=root.matrix_world.inverted()@o.matrix_world;verts.extend([local@v.co for v in md.vertices]);faces.extend([[i+offset for i in p.vertices] for p in md.polygons]);ev.to_mesh_clear()
 tree=BVHTree.FromPolygons(verts,faces)
 def project(p,clearance=.006):
  p=Vector(p);hit=tree.ray_cast(Vector((p.x,-1,p.z)),Vector((0,1,0)),2)[0]
  if hit is not None:p.y=hit.y-clearance
  return p
 old=next(o for o in col.objects if match(o.name,['Fitted cape shoulder strap']));strapmat=old.data.materials[0]
 for o in list(col.objects):
  if match(o.name,['Fitted cape shoulder strap','Fitted strap stitched edge']):bpy.data.objects.remove(o,do_unlink=True)
 cache={}
 def strap(u,t):
  top=Vector((-.169,-.13,1.424)).lerp(Vector((-.137,-.14,1.432)),u);bottom=Vector((.126,-.128,.971)).lerp(Vector((.153,-.12,.990)),u);p=project(top.lerp(bottom,t));key=round(u,5)
  if key not in cache:cache[key]=[project(top.lerp(bottom,j/180)).y for j in range(181)]
  p.y=min(y+abs(j/180-t)*(.38 if REV>=5 else .65) for j,y in enumerate(cache[key]));return p
 grid('Fitted cape shoulder strap',strap,8,160,strapmat,.004)
 for u in [.08,.92]:cord('Fitted strap stitched edge',[strap(u,i/180)+Vector((0,-.0048,0)) for i in range(181)],.00065,trim)
 for o in col.objects:
  if match(o.name,['Strap buckle','Buckle inner leather']):o.location=project(o.location,(.021 if REV>=5 else .013) if match(o.name,['Buckle inner leather']) else .016)
 print('RESHAPED_CAPE_AND_STRAP',name,flush=True)
if REV>=5:
 name=N[1];col=bpy.data.collections[name+' — authored study'];root=next(o for o in col.objects if o.type=='EMPTY')
 head=next(o for o in col.objects if o.name.startswith(name+' continuous facial planes'))
 bpy.context.view_layer.update();ev=head.evaluated_get(bpy.context.evaluated_depsgraph_get());md=ev.to_mesh();tree=BVHTree.FromPolygons([v.co.copy() for v in md.vertices],[list(p.vertices) for p in md.polygons]);ev.to_mesh_clear()
 old=next(o for o in col.objects if o.name.startswith('Surface-following ranger beard'));beardmat=old.data.materials[0];bpy.data.objects.remove(old,do_unlink=True)
 d=bpy.data.curves.new('Ranger softly graded stubble','CURVE');d.dimensions='3D';d.bevel_depth=.00013;d.bevel_resolution=2
 def smooth(x):
  x=max(0,min(1,x));return x*x*(3-2*x)
 def fy(x,z):
  hit=tree.ray_cast(Vector((x,-.40,z)),Vector((0,1,0)),.8)[0];return hit.y if hit is not None else None
 random.seed(6821)
 for i in range(6500):
  x=random.uniform(-.085,.085);z=random.uniform(1.540,1.651);ax=abs(x)
  top=1.608+.034*min(1,ax/.068)**.8
  probability=smooth((top-z)/.020)*smooth((.084-ax)/.016)
  probability*=1-smooth((z-1.583)/.019)*(1-smooth((ax-.023)/.018))
  if random.random()>probability:continue
  y=fy(x,z);y2=fy(x+.00035,z-.0014)
  if y is None or y2 is None:continue
  sp=d.splines.new('POLY');sp.points.add(2)
  for p,co,r in zip(sp.points,[(x,y-.00025,z),(x+.0002,(y+y2)/2-.0004,z-.0007),(x+.00035,y2-.0002,z-.0014)],[.8,1,.05]):p.co=(*co,1);p.radius=r
 ob=bpy.data.objects.new('Surface-following ranger beard refined',d);col.objects.link(ob);ob.parent=root;d.materials.append(beardmat)
 print('SOFTENED_BEARD_BOUNDARIES',len(d.splines),flush=True)
scene=bpy.context.scene;scene.cycles.samples=24;cam=scene.camera
for name in A:bpy.data.collections[name+' — authored study'].hide_render=True

def render(target,offset,scale,file,w=1000,h=1000):
 cam.location=Vector(target)+Vector(offset);cam.rotation_euler=(Vector(target)-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.ortho_scale=scale
 scene.render.resolution_x=w;scene.render.resolution_y=h;scene.render.filepath=str(OUT/file);bpy.ops.render.render(write_still=True)
render((0,0,.94),(0,-8,1),5.8,'travelers.png',2400,1050)
render((0,0,.94),(.35,8,1.2),5.8,'travelers-rear.png',2400,1050)
for name in N:bpy.data.collections[name+' — authored study'].hide_render=True
for i,name in enumerate(N):
 col=bpy.data.collections[name+' — authored study'];col.hide_render=False;root=next(o for o in col.objects if o.type=='EMPTY');slug=['scout','ranger','wayfarer','forager'][i]
 render(root.matrix_world@Vector((0,0,1.23)),(.65,-4,.4),.89,slug+'-outfit.png')
 col.hide_render=True
if REV>=5:
 col=bpy.data.collections[N[1]+' — authored study'];col.hide_render=False;root=next(o for o in col.objects if o.type=='EMPTY')
 render(root.matrix_world@Vector((0,0,1.675)),(.6,-4,.13),.39,'ranger-face.png')
 render(root.matrix_world@Vector((0,0,1.675)),(4,-.65,.10),.39,'ranger-profile.png')
 col.hide_render=True
bpy.data.collections[N[0]+' — authored study'].hide_render=False
render((-1.8,0,1.25),(4,-.7,.4),.90,'scout-side.png')
for name in N+A:bpy.data.collections[name+' — authored study'].hide_render=False
cam.location=(4.5,-8,4.5);cam.rotation_euler=(Vector((0,1.25,1))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.ortho_scale=7.4
notes=bpy.data.texts.get('REVIEW STATUS');notes.clear();notes.write(f'Cycle {PASS}: hanging cape silhouettes and fitted straps over cycle 22 faces, hair and animals. Refinement 5 removes hidden collars that pierced the capes, eases strap bends and grades ranger stubble boundaries. Offline unrigged art; review actual garment clearance and silhouette. Not ready for game integration.')
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'characters.blend'),compress=True)
print('GARMENT_PASS_COMPLETE',PASS,flush=True)
