"""Fit wayfarer braids to the saved cycle 24 scalp, preserving all other work."""
from pathlib import Path
import bpy,math,sys
from mathutils import Vector
from mathutils.bvhtree import BVHTree
R=Path(__file__).resolve().parents[2]
PASS=int(next((a.split('=')[1] for a in sys.argv if a.startswith('--art-pass=')),'25'))
REV=int(next((a.split('=')[1] for a in sys.argv if a.startswith('--refinement=')),'2'))
OUT=R/'art/blender/cycles'/f'cycle_{PASS:02d}';OUT.mkdir(parents=True,exist_ok=True)
if (OUT/'characters.blend').exists():raise RuntimeError('Preserve saved models; choose a fresh pass')
bpy.ops.wm.open_mainfile(filepath=str(R/'art/blender/cycles/cycle_24/characters.blend'))
N=['WILLOW SCOUT','HEARTHLAND RANGER','RIDGE WAYFARER','EMBER FORAGER'];A=['BRISTLEBACK BOAR','WOODLAND HOG','RIDGEBACK BOAR','MEADOW BUCK']
# The cycle 24 review exposed a remaining shirt patch through the tighter poncho.
CAPE=['Tailored shoulder cape','Closed asymmetric wayfarer poncho','Bound tailored cape edge','Cape opening seam','Poncho woven border','Flat embroidered cape chevron','Tailored cape fastening eyelet','Tailored cape tie']
def matches(o,parts):return any(o.name==p or o.name.startswith(p+'.') for p in parts)
def surfaces(objects,root):
 bpy.context.view_layer.update();vs=[];fs=[]
 for o in objects:
  ev=o.evaluated_get(bpy.context.evaluated_depsgraph_get());md=ev.to_mesh();off=len(vs);transform=root.matrix_world.inverted()@o.matrix_world
  vs.extend(transform@v.co for v in md.vertices);fs.extend([[i+off for i in p.vertices] for p in md.polygons]);ev.to_mesh_clear()
 return BVHTree.FromPolygons(vs,fs)
def clear_surface(p,tree,front_only=False):
 p=Vector(p);front=front_only or p.y<0;origin=Vector((p.x,-1 if front else 1,p.z));direction=Vector((0,1 if front else -1,0));hit=tree.ray_cast(origin,direction,2)[0]
 if hit is not None:
  p.y=min(p.y,hit.y-.009) if front else max(p.y,hit.y+.009)
 return p
for kind in [0,2]:
 c=bpy.data.collections[N[kind]+' — authored study'];rt=next(o for o in c.objects if o.type=='EMPTY')
 tree=surfaces([o for o in c.objects if o.type=='MESH' and matches(o,['Linen shirt'])],rt)
 for o in c.objects:
  if not matches(o,CAPE):continue
  if o.type=='MESH':
   for v in o.data.vertices:v.co=clear_surface(v.co,tree)
  if o.type=='CURVE':
   for sp in o.data.splines:
    for p in sp.points:p.co=(*clear_surface(p.co.xyz,tree),p.co.w)
 tree=surfaces([o for o in c.objects if o.type=='MESH' and matches(o,CAPE[:2])],rt)
 for o in c.objects:
  if matches(o,['Fitted cape shoulder strap']):
   for v in o.data.vertices:v.co=clear_surface(v.co,tree,True)
  if matches(o,['Fitted strap stitched edge']):
   for sp in o.data.splines:
    for p in sp.points:p.co=(*clear_surface(p.co.xyz,tree,True),p.co.w)
 print('CAPE_SHIRT_CLEARANCE',N[kind],flush=True)
name=N[2];col=bpy.data.collections[name+' — authored study'];root=next(o for o in col.objects if o.type=='EMPTY')
base=bpy.data.materials[name+' authored hair'];light=bpy.data.materials[name+' hair strand planes']
for o in list(col.objects):
 if o.name.startswith(('Woven crown braid','Long gathered braid')):bpy.data.objects.remove(o,do_unlink=True)
foundation=next(o for o in col.objects if o.name.startswith('Continuous shaped hair foundation'))
bpy.context.view_layer.update();ev=foundation.evaluated_get(bpy.context.evaluated_depsgraph_get());md=ev.to_mesh();tree=BVHTree.FromPolygons([v.co.copy() for v in md.vertices],[list(p.vertices) for p in md.polygons]);ev.to_mesh_clear()
def fit(p):
 p=Vector(p);hit,normal,_,_=tree.find_nearest(p)
 radial=hit-Vector((0,.008,1.705))
 if normal.dot(radial)<0:normal=-normal
 return hit+normal*(.0035 if REV>=3 else .0050)
def strands(name,paths,radius,mat):
 d=bpy.data.curves.new(name,'CURVE');d.dimensions='3D';d.bevel_depth=radius;d.bevel_resolution=3;d.resolution_u=2;d.use_fill_caps=True
 for pts in paths:
  sp=d.splines.new('POLY');sp.points.add(len(pts)-1)
  for i,(p,co) in enumerate(zip(sp.points,pts)):
   p.co=(*co,1);p.radius=min(1,.15+i*.18,.15+(len(pts)-1-i)*.15)
 o=bpy.data.objects.new(name,d);col.objects.link(o);o.parent=root;d.materials.append(mat)
 return o

def braid(name,points,width,mat,detail):
 centers=[Vector(p) for p in points];paths=[]
 for lane in range(3):
  pts=[]
  for i,p in enumerate(centers):
   t=i/(len(centers)-1);tan=(centers[min(i+1,len(centers)-1)]-centers[max(0,i-1)]).normalized();across=Vector((1,0,0))-tan*tan.x;across.normalize();normal=tan.cross(across).normalized()
   a=t*math.tau*15+lane*math.tau/3;taper=1-.32*t
   pts.append(p+across*math.cos(a)*width*taper+normal*math.sin(a*(2 if REV>=2 else 1))*width*.45*taper)
  paths.append(pts)
 strands(name,paths,width*.58,mat)
 # Narrow highlights follow the same woven direction without hollow tips.
 strands(name+' fine weave',[[p+Vector((0,-.0004,.0007)) for p in path] for path in paths],.0003,detail)


ends=[]
for lane in range(11):
 x=(lane-5)*.0192;pts=[]
 for j in range(241):
  t=j/240;a=-1.30+t*3.42;px=x+.008*math.sin(math.pi*t)*(1-abs(x)/.12)
  cross=math.sqrt(max(.01,1-(px/.113)**2))
  pts.append(fit((px,.008+math.sin(a)*.102*cross,1.705+math.cos(a)*.123*cross)))
 braid('Woven crown braid',pts,.0062*(1+.07*math.sin(lane*2.1)),base,light)
 ends.append(pts[-1])
for lane in range(9):
 start=ends[lane+1]+(Vector((0,-.003,.012)) if REV>=3 else Vector((0,0,0)));pts=[];side=(lane-4)/4
 end=Vector((side*(.116+.009*math.sin(lane)),.128+.020*math.cos(lane*1.1),1.405+.022*math.sin(lane*1.73)))
 c1=start+Vector((.008*side,.026,-.018));c2=Vector((side*.133,.165,1.504))
 for j in range(241):
  t=j/240;pts.append(start*(1-t)**3+c1*3*(1-t)**2*t+c2*3*(1-t)*t*t+end*t**3)
 braid('Long gathered braid',pts,.0063*(1+.09*math.sin(lane)),base,light)
print('FITTED_WAYFARER_BRAIDS',11,9,flush=True)
scene=bpy.context.scene;scene.cycles.samples=24;cam=scene.camera
for n in N+A:bpy.data.collections[n+' — authored study'].hide_render=True
col.hide_render=False

def render(target,offset,scale,file,w=1000,h=1000):
 cam.location=Vector(target)+Vector(offset);cam.rotation_euler=(Vector(target)-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.ortho_scale=scale
 scene.render.resolution_x=w;scene.render.resolution_y=h;scene.render.filepath=str(OUT/file);bpy.ops.render.render(write_still=True)
for file,offset in [('wayfarer-face.png',(.6,-4,.13)),('wayfarer-profile.png',(4,-.65,.10)),('wayfarer-rear.png',(.6,4,.18))]:
 render(root.matrix_world@Vector((0,0,1.67)),offset,.43,file)
col.hide_render=True
for kind in [0,2]:
 c=bpy.data.collections[N[kind]+' — authored study'];c.hide_render=False;rt=next(o for o in c.objects if o.type=='EMPTY')
 render(rt.matrix_world@Vector((0,0,1.23)),(.65,-4,.4),.89,('scout' if kind==0 else 'wayfarer')+'-outfit.png')
 if kind==0:render(rt.matrix_world@Vector((0,0,1.25)),(4,-.7,.4),.90,'scout-side.png')
 c.hide_render=True
for n in N:bpy.data.collections[n+' — authored study'].hide_render=False
render((0,0,.94),(0,-8,1),5.8,'travelers.png',2400,1050)
render((0,0,.94),(.35,8,1.2),5.8,'travelers-rear.png',2400,1050)
for n in N+A:bpy.data.collections[n+' — authored study'].hide_render=False
cam.location=(4.5,-8,4.5);cam.rotation_euler=(Vector((0,1.25,1))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.ortho_scale=7.4
notes=bpy.data.texts.get('REVIEW STATUS');notes.clear();notes.write(f'Cycle {PASS}: scalp-fitted wayfarer crown braids, continuous trailing braid paths, and shirt clearance beneath both capes. Refinement 3 embeds crown roots and overlaps hanging braid starts. Preserves cycle 24 faces, other garments/hair and wildlife. Offline unrigged study; illustration fidelity remains incomplete.')
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'characters.blend'),compress=True)
print('FITTED_BRAID_PASS_COMPLETE',PASS,flush=True)
