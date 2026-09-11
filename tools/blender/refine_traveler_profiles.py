"""Reshape saved cycle 8 faces without regenerating hair, outfits or animals.
Blender --background --python tools/blender/refine_traveler_profiles.py -- --art-pass=9
"""
from pathlib import Path
import bpy,math,sys
from mathutils import Vector
R=Path(__file__).resolve().parents[2]
PASS=int(next((a.split('=')[1] for a in sys.argv if a.startswith('--art-pass=')),'9'))
REV=int(next((a.split('=')[1] for a in sys.argv if a.startswith('--refinement=')),'1'))
OUT=R/'art/blender/cycles'/f'cycle_{PASS:02d}';OUT.mkdir(parents=True,exist_ok=True)
if (OUT/'characters.blend').exists():raise RuntimeError('Use a fresh cycle number to preserve source')
bpy.ops.wm.open_mainfile(filepath=str(R/'art/blender/cycles/cycle_08/characters.blend'))
N=['WILLOW SCOUT','HEARTHLAND RANGER','RIDGE WAYFARER','EMBER FORAGER']
A=['BRISTLEBACK BOAR','WOODLAND HOG','RIDGEBACK BOAR','MEADOW BUCK']
PARTS=['continuous facial planes','fitted almond eye','fine upper eyelid','fine lower eyelid','lash edge','resting eyebrow','underside nostril','folded ear','ear helix','shaped upper lip','shaped lower lip','fine mouth separation']
def face_object(o,name):
 return any(o.name.startswith(name+' '+p) for p in PARTS) or o.name.startswith('Surface freckle') or o.name.startswith('Surface-following ranger beard')
def g(x,z,cx,cz,sx,sz):return math.exp(-((x-cx)/sx)**2-((z-cz)/sz)**2)
BASE=[]
def sample(z,rows):
 for i in range(len(rows)-1):
  if z<=rows[i+1][0]:
   h=rows[i+1][0]-rows[i][0];t=max(0,(z-rows[i][0])/h);d=(rows[i+1][1]-rows[i][1])/h
   def slope(j):
    if j==0:return (rows[1][1]-rows[0][1])/(rows[1][0]-rows[0][0])
    if j==len(rows)-1:return (rows[j][1]-rows[j-1][1])/(rows[j][0]-rows[j-1][0])
    a=(rows[j][1]-rows[j-1][1])/(rows[j][0]-rows[j-1][0]);b=(rows[j+1][1]-rows[j][1])/(rows[j+1][0]-rows[j][0])
    return 0 if a*b<=0 else 2*a*b/(a+b)
   return (2*t**3-3*t*t+1)*rows[i][1]+(t**3-2*t*t+t)*h*slope(i)+(-2*t**3+3*t*t)*rows[i+1][1]+(t**3-t*t)*h*slope(i+1)
 return rows[-1][1]
def reshape(p,kind):
 x,y,z=p;front=max(0,min(1,(-y-.003)/.018));dy=0
 # Reduce the isolated nose peak and establish a continuous philtrum/muzzle plane.
 dy += [.006,.006,.005,.007][kind]*g(x,z,0,1.642,.022,.018)
 dy -= [.010,.009,.010,.010][kind]*g(x,z,0,1.619,.032,.015)
 dy -= [.008,.007,.008,.008][kind]*g(x,z,0,1.598,.034,.014)
 # Give the chin a defined front plane without a detached spherical volume.
 if REV<2:dy -= [.005,.007,.006,.004][kind]*g(x,z,0,1.561,.038,.020)
 else:
  dy -= [.019,.020,.020,.018][kind]*math.exp(-(x/.045)**2-((z-1.573)/.029)**4)
  dy += [0,.004,.004,0][kind]*g(x,z,0,1.642,.022,.018)
 shorten=[.012,.006,.006,.011][kind]
 dz=shorten*max(0,min(1,(1.595-z)/.066))**1.2
 if REV>=2:dz += [.006,.005,.005,.006][kind]*g(x,z,0,1.602,.045,.020)*front
 if REV>=3:
  target=[(1.529,-.036),(1.541,-.060),(1.558,-.087),(1.576,-.094),(1.590,-.098),(1.601,-.099),(1.610,-.100),(1.620,-.103),(1.631,-.109),(1.641,-.111),(1.650,-.105),(1.667,-.092),(1.686,-.085),(1.706,-.083),(1.721,-.078),(1.752,-.060),(1.779,-.007)]
  # Preserve distinct nose projection, then blend the continuous silhouette into cheeks.
  target=[(a,b-[0,.003,.004,-.002][kind]*math.exp(-((a-1.642)/.022)**2)) for a,b in target]
  width=.038 if REV<4 else .021+.023/(1+math.exp((z-1.620)/.009))
  influence=math.exp(-(x/width)**2)
  dy=(sample(z,target)-sample(z,BASE))*influence
  dz=shorten*max(0,min(1,(1.595-z)/.066))**1.2+.004*g(x,z,0,1.602,.045,.024)*front
 return Vector((x,y+dy*front,z+dz))
for kind,name in enumerate(N):
 col=bpy.data.collections[name+' — authored study'];count=0
 head=next(o for o in col.objects if o.name.startswith(name+' continuous facial planes'))
 BASE=sorted((v.co.z,v.co.y) for v in head.data.vertices if abs(v.co.x)<1e-7 and v.co.y<0)
 for o in col.objects:
  if not face_object(o,name):continue
  assert o.location.length<1e-5 and all(abs(v-1)<1e-5 for v in o.scale),o.name
  if o.type=='MESH':
   for v in o.data.vertices:v.co=reshape(v.co,kind)
   o.data.update()
  elif o.type=='CURVE':
   for sp in o.data.splines:
    if sp.type=='BEZIER':
     for p in sp.bezier_points:
      p.co=reshape(p.co,kind);p.handle_left=reshape(p.handle_left,kind);p.handle_right=reshape(p.handle_right,kind)
    else:
     for p in sp.points:p.co=(*reshape(p.co.xyz,kind),p.co.w)
  count+=1
 print('RESHAPED_FACE',name,count,flush=True)
scene=bpy.context.scene;scene.cycles.samples=24;cam=scene.camera
for name in A:bpy.data.collections[name+' — authored study'].hide_render=True

def render(target,offset,scale,file,w=900,h=900):
 cam.location=Vector(target)+Vector(offset);cam.rotation_euler=(Vector(target)-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.ortho_scale=scale
 scene.render.resolution_x=w;scene.render.resolution_y=h;scene.render.filepath=str(OUT/file);bpy.ops.render.render(write_still=True)
render((0,0,.94),(0,-8,1),5.8,'travelers.png',2400,1050)
for name in N:bpy.data.collections[name+' — authored study'].hide_render=True
for i,name in enumerate(N):
 col=bpy.data.collections[name+' — authored study'];col.hide_render=False;root=next(o for o in col.objects if o.type=='EMPTY');target=root.matrix_world@Vector((0,0,1.675));slug=['scout','ranger','wayfarer','forager'][i]
 render(target,(.6,-4,.13),.39,slug+'-face.png')
 render(target,(4,-.65,.10),.39,slug+'-profile.png')
 col.hide_render=True
for name in N+A:bpy.data.collections[name+' — authored study'].hide_render=False
cam.location=(4.5,-8,4.5);cam.rotation_euler=(Vector((0,1.25,1))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.ortho_scale=7.4
notes=bpy.data.texts.get('REVIEW STATUS');notes.clear();notes.write(f'Cycle {PASS}: facial profile refinement over cycle 8, preserving hair, garments and animals. Actual front and side portraits of all four travelers. Offline unrigged studies; fidelity not yet achieved.')
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'characters.blend'),compress=True)
print('PROFILE_PASS_COMPLETE',PASS,flush=True)
