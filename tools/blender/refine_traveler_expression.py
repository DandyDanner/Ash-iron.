"""Refine saved cycle 20 traveler sockets, eyelids, ears and facial expression.
Preserves hair, clothing, equipment and all wildlife. Offline unrigged studies.
"""
from pathlib import Path
import bpy,bmesh,math,sys,random
from mathutils import Vector
from mathutils.bvhtree import BVHTree
R=Path(__file__).resolve().parents[2]
PASS=int(next((a.split('=')[1] for a in sys.argv if a.startswith('--art-pass=')),'21'))
REV=int(next((a.split('=')[1] for a in sys.argv if a.startswith('--refinement=')),'1'))
OUT=R/'art/blender/cycles'/f'cycle_{PASS:02d}';OUT.mkdir(parents=True,exist_ok=True)
if (OUT/'characters.blend').exists():raise RuntimeError('Choose a fresh cycle; preserve saved source')
bpy.ops.wm.open_mainfile(filepath=str(R/'art/blender/cycles/cycle_20/characters.blend'))
N=['WILLOW SCOUT','HEARTHLAND RANGER','RIDGE WAYFARER','EMBER FORAGER'];A=['BRISTLEBACK BOAR','WOODLAND HOG','RIDGEBACK BOAR','MEADOW BUCK']
PARTS=['continuous facial planes','resting eyebrow','underside nostril','shaped upper lip','shaped lower lip','fine mouth separation']
col=None;root=None

def mat(name,color,rough=.6):
 m=bpy.data.materials.new(name);m.diffuse_color=(*color,1);m.use_nodes=True;p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*color,1);p.inputs['Roughness'].default_value=rough;p.inputs['Specular IOR Level'].default_value=.26;return m

def mesh(name,vs,fs,m):
 d=bpy.data.meshes.new(name);d.from_pydata(vs,[],fs);d.update();bm=bmesh.new();bm.from_mesh(d);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(d);bm.free()
 o=bpy.data.objects.new(name,d);col.objects.link(o);o.parent=root;d.materials.append(m)
 for p in d.polygons:p.use_smooth=True
 return o

def curve(name,pts,r,m):
 d=bpy.data.curves.new(name,'CURVE');d.dimensions='3D';d.bevel_depth=r;d.bevel_resolution=3;sp=d.splines.new('POLY');sp.points.add(len(pts)-1)
 for i,(p,co) in enumerate(zip(sp.points,pts)):p.co=(*co,1);p.radius=.30+.70*math.sin(math.pi*i/(len(pts)-1))**.5
 o=bpy.data.objects.new(name,d);col.objects.link(o);o.parent=root;d.materials.append(m);return o

def g(x,z,cx,cz,sx,sz):return math.exp(-((x-cx)/sx)**2-((z-cz)/sz)**2)
def reshape(p,kind):
 x,y,z=p;front=max(0,min(1,(-y-.005)/.030));dy=0
 for side in [-1,1]:
  dy+=.0038*g(x,z,side*.042,1.680,.027,.017)
  dy-=.0022*g(x,z,side*.056,1.650,.022,.018)
  dy-=.0020*g(x,z,side*.012,1.640,.008,.008)
 dy-=.0025*g(x,z,0,1.661,.010,.022)
 lower=max(0,min(1,(1.613-z)/.067));x*=1-[.070,.022,.020,.075][kind]*lower*front
 smile=[.0017,.0009,.0006,.0021][kind];dz=(smile*(x/.030)**2+[.0005,-.0004,0,-.0006][kind]*x/.030)*g(x,z,0,1.608,.036,.015)*front
 if REV>=2:
  dz += [.022,.027,.025,.023][kind]*max(0,min(1,(y+.060)/.120))*max(0,min(1,(1.620-z)/.078))**1.3
  dy -= .003*g(x,z,0,1.615,.027,.013)
 return Vector((x,y+dy*front,z+dz))

def ear(side,name,skin,shade):
 normal=Vector((side*.82,-.57,0)).normalized();axis=Vector((side*.57,.82,0)).normalized();center=Vector((side*.096,.002,1.658));up=Vector((0,0,1))
 nr=24;nt=80;vs=[];fs=[]
 def point(r,a,back=False):
  u=.0135*r*math.cos(a)*(1-.10*math.sin(a));v=.0265*r*math.sin(a)
  depth=.003-.0035*math.exp(-(r/.40)**2)+.0038*math.exp(-((r-.83)/.14)**2)
  if back:depth-=.0045
  return center+axis*u+up*v+normal*depth
 for back in [False,True]:
  for j in range(nr+1):
   for i in range(nt):vs.append(point(j/nr,math.tau*i/nt,back))
 count=(nr+1)*nt
 for layer in [0,1]:
  for j in range(nr):
   for i in range(nt):a=layer*count+j*nt+i;b=layer*count+j*nt+(i+1)%nt;fs.append((a,b,b+nt,a+nt))
 for i in range(nt):a=nr*nt+i;b=nr*nt+(i+1)%nt;fs.append((a,b,b+count,a+count))
 ob=mesh(name+' anatomical ear '+str(side),vs,fs,skin)
 curve(name+' sculpted ear helix '+str(side),[point(.86,a)+normal*.0007 for a in [(-.40+i/90*math.tau*.91) for i in range(91)]],.0016,skin)
 curve(name+' ear antihelix '+str(side),[center+axis*u+up*v+normal*d for u,v,d in [(-.003,-.015,.004),(.003,-.009,.004),(.004,.001,.002),(.002,.012,.003),(-.002,.017,.004)]],.0013,skin)
 curve(name+' concha fold '+str(side),[center+axis*u+up*v+normal*d for u,v,d in [(-.005,-.008,.000),(-.001,-.009,-.0005),(.003,-.005,-.0005),(.003,0,.000)]],.0007,shade)

for kind,name in enumerate(N):
 col=bpy.data.collections[name+' — authored study'];root=next(o for o in col.objects if o.type=='EMPTY')
 for o in list(col.objects):
  if any(o.name.startswith(name+' '+p) for p in ['fitted almond eye','fine upper eyelid','fine lower eyelid','lash edge','folded ear','ear helix']):bpy.data.objects.remove(o,do_unlink=True);continue
  if not (any(o.name.startswith(name+' '+p) for p in PARTS) or o.name.startswith(('Surface freckle','Surface-following ranger beard'))):continue
  if o.type=='MESH':
   for v in o.data.vertices:v.co=reshape(v.co,kind)
   o.data.update()
  elif o.type=='CURVE':
   for sp in o.data.splines:
    if sp.type=='BEZIER':
     for p in sp.bezier_points:p.co=reshape(p.co,kind);p.handle_left=reshape(p.handle_left,kind);p.handle_right=reshape(p.handle_right,kind)
    else:
     for p in sp.points:p.co=(*reshape(p.co.xyz,kind),p.co.w)
 head=next(o for o in col.objects if o.name.startswith(name+' continuous facial planes'))
 bpy.context.view_layer.update();ob=head.evaluated_get(bpy.context.evaluated_depsgraph_get());me=ob.to_mesh();tree=BVHTree.FromPolygons([v.co.copy() for v in me.vertices],[list(p.vertices) for p in me.polygons]);ob.to_mesh_clear()
 def fy(x,z):
  p,n,_,_=tree.ray_cast(Vector((x,-.40,z)),Vector((0,1,0)),.8)
  if p is None:raise RuntimeError(('Facial landmark outside head',x,z))
  return p.y
 if REV>=2:
  for o in col.objects:
   if o.name.startswith((name+' shaped upper lip',name+' shaped lower lip')):
    for i,v in enumerate(o.data.vertices):
     band=(i//49)/8;u=-1+2*(i%49)/48;v.co.y=fy(v.co.x,v.co.z)-.0005-.0012*math.sin(math.pi*band)*(1-u*u)
   if o.name.startswith(name+' fine mouth separation'):
    for sp in o.data.splines:
     for p in sp.bezier_points:
      p.co.y=fy(p.co.x,p.co.z)-.0008;p.handle_left_type='AUTO';p.handle_right_type='AUTO'
  if kind==3:
   freckles=mat('Forager warm embedded freckles',(.19,.085,.039),.90)
   for o in col.objects:
    if o.name.startswith('Surface freckle'):
     o.data.materials[0]=freckles
     for v in o.data.vertices:v.co.y=fy(v.co.x,v.co.z)-.00025
  if kind==1:
   for o in list(col.objects):
    if o.name.startswith('Surface-following ranger beard'):bpy.data.objects.remove(o,do_unlink=True)
   shade_beard=mat('Ranger fine natural stubble',(.055,.023,.009),.84)
   d=bpy.data.curves.new('Ranger short beard fibers','CURVE');d.dimensions='3D';d.bevel_depth=.00013;d.bevel_resolution=2
   random.seed(5401)
   for i in range(4000):
    x=random.uniform(-.079,.079);z=random.uniform(1.554,1.635)
    if abs(x)<.035 and z>1.595:continue
    try:y=fy(x,z);y2=fy(x+.00035,z-.0014)
    except RuntimeError:continue
    sp=d.splines.new('POLY');sp.points.add(2)
    for p,co,r in zip(sp.points,[(x,y-.00025,z),(x+.0002,(y+y2)/2-.0004,z-.0007),(x+.00035,y2-.0002,z-.0014)],[.8,1,.05]):p.co=(*co,1);p.radius=r
   ob=bpy.data.objects.new('Surface-following ranger beard refined',d);col.objects.link(ob);ob.parent=root;d.materials.append(shade_beard)
   attr=head.data.color_attributes.get('Face warmth')
   for v,c in zip(head.data.vertices,attr.data):
    x,y,z=v.co;amount=max(0,min(1,(1.631-z)/.025))*.19*max(0,min(1,(-y-.007)/.03))
    if abs(x)<.035 and z>1.591:amount*=max(0,min(1,(1.607-z)/.016))
    old=c.color;c.color=(*(q*(1-amount) for q in old[:3]),1)
 colors=[(.48,.285,.16),(.45,.24,.12),(.19,.088,.040),(.62,.37,.21)]
 skin=mat(name+' sculpted eyelid and ear skin',colors[kind],.63);shade=mat(name+' subtle orbital crease',tuple(c*.65 for c in colors[kind]),.82);hair=bpy.data.materials[name+' hair']
 for side in [-1,1]:
  cx=side*.042;cz=1.678;hw=.024;upper=[.0105,.0087,.0091,.0112][kind];lower=.0067
  def ec(u,v):
   x=cx+side*u*hw;mid=cz+.002*u;amp=max(0,1-u*u)**.82;z=mid+(upper if v>=0 else lower)*amp*v
   return Vector((x,fy(x,z)-.0010-.0025*(1-u*u)*(1-v*v),z))
  vs=[];fs=[];coords=[];nu=64;nv=28
  for j in range(nv+1):
   for i in range(nu+1):
    u=-1+2*i/nu;v=-1+2*j/nv;p=ec(u,v);vs.append(p);coords.append(((p.x-cx)/.0107,(p.z-cz)/.0107,0))
  for j in range(nv):
   for i in range(nu):a=j*(nu+1)+i;fs.append((a,a+1,a+nu+2,a+nu+1))
  eye=mat(name+' inset iris and sclera '+str(side),(.66,.61,.51),.28);nd=eye.node_tree.nodes;lk=eye.node_tree.links;at=nd.new('ShaderNodeAttribute');at.attribute_name='Eye radial coordinate';dist=nd.new('ShaderNodeVectorMath');dist.operation='LENGTH';lk.new(at.outputs['Vector'],dist.inputs[0]);ramp=nd.new('ShaderNodeValToRGB');cr=ramp.color_ramp;cr.elements.remove(cr.elements[1]);stops=[(0,(.007,.004,.002,1)),(.37,(.007,.004,.002,1)),(.44,(.15,.067,.015,1)),(.77,(.23,.113,.031,1)),(.91,(.045,.027,.012,1)),(.985,(.038,.025,.013,1)),(1,(.70,.66,.57,1))]
  cr.elements[0].position=0;cr.elements[0].color=stops[0][1]
  for p,c in stops[1:]:e=cr.elements.new(p);e.color=c
  lk.new(dist.outputs['Value'],ramp.inputs[0]);lk.new(ramp.outputs[0],nd.get('Principled BSDF').inputs['Base Color'])
  o=mesh(name+' fitted almond eye '+str(side),vs,fs,eye);a=o.data.attributes.new('Eye radial coordinate','FLOAT_VECTOR','POINT');a.data.foreach_set('vector',[q for c in coords for q in c])
  for top in [True,False]:
   vs=[];fs=[];steps=64;bands=8
   for j in range(bands+1):
    t=j/bands
    for i in range(steps+1):
     u=-1+2*i/steps;inner=ec(u,1 if top else -1);x=inner.x+side*u*.0015*t;dz=(.0050 if top else -.0034)*max(0,1-u*u)**.65*t;z=inner.z+dz
     y=(1-t)*inner.y+t*(fy(x,z)-.00015)-.0012*math.sin(math.pi*t)*(1-u*u)
     vs.append((x,y,z))
   for j in range(bands):
    for i in range(steps):a=j*(steps+1)+i;fs.append((a,a+1,a+steps+2,a+steps+1))
   mesh(name+(' shaped upper eyelid' if top else ' shaped lower eyelid')+' '+str(side),vs,fs,skin)
   if top:
    curve(name+' restrained lash '+str(side),[ec(-1+2*i/64,1)+Vector((0,-.0002,0)) for i in range(65)],.00040,hair)
    pts=[]
    for i in range(49):
     u=-.92+1.84*i/48;p=ec(u,1);z=p.z+.0051*(1-u*u)**.65;x=p.x+side*u*.0015;pts.append((x,fy(x,z)-.00025,z))
    curve(name+' upper orbital crease '+str(side),pts,.00028,shade)
  ear(side,name,skin,shade)
 print('TRAVELER_EXPRESSION_AUTHORED',name,flush=True)
scene=bpy.context.scene;scene.cycles.samples=24;cam=scene.camera
for name in A:bpy.data.collections[name+' — authored study'].hide_render=True
def render(target,offset,scale,file,w=1000,h=1000):
 cam.location=Vector(target)+Vector(offset);cam.rotation_euler=(Vector(target)-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.ortho_scale=scale;scene.render.resolution_x=w;scene.render.resolution_y=h;scene.render.filepath=str(OUT/file);bpy.ops.render.render(write_still=True)
render((0,0,.94),(0,-8,1),5.8,'travelers.png',2400,1050)
render((0,0,.96),(0,8,1),5.8,'travelers-rear.png',2400,1050)
for name in N:bpy.data.collections[name+' — authored study'].hide_render=True
for i,name in enumerate(N):
 col=bpy.data.collections[name+' — authored study'];col.hide_render=False;root=next(o for o in col.objects if o.type=='EMPTY');target=root.matrix_world@Vector((0,0,1.675));slug=['scout','ranger','wayfarer','forager'][i]
 render(target,(.6,-4,.13),.39,slug+'-face.png');render(target,(4,-.65,.10),.39,slug+'-profile.png');col.hide_render=True
for name in N+A:bpy.data.collections[name+' — authored study'].hide_render=False
cam.location=(4.5,-8,4.5);cam.rotation_euler=(Vector((0,1.25,1))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.ortho_scale=7.4
notes=bpy.data.texts.get('REVIEW STATUS');notes.clear();notes.write(f'Cycle {PASS}: traveler sockets, shaped eyelids, cupped ears, restrained mouth/jaw expression over cycle 20. Hair, clothing and wildlife preserved. Actual reviewed Blender study, unrigged and below illustration fidelity.')
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'characters.blend'),compress=True)
print('EXPRESSION_PASS_COMPLETE',PASS,flush=True)
