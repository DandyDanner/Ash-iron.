"""Focused Willow study from preserved cycle 26; matched native Blender comparisons.
Run with -- --art-pass=27 --revision=1. Other seven models are fingerprint-checked.
"""
from pathlib import Path
import bpy,bmesh,math,sys,json,hashlib,random,ast
from mathutils import Vector
R=Path(__file__).resolve().parents[2]
CYCLE=int(next((a.split('=')[1] for a in sys.argv if a.startswith('--art-pass=')),'27'))
REV=int(next((a.split('=')[1] for a in sys.argv if a.startswith('--revision=')),'1'))
OUT=R/'art/blender/cycles'/f'cycle_{CYCLE:02d}';OUT.mkdir(parents=True,exist_ok=True)
if (OUT/'characters.blend').exists():raise RuntimeError('Preserve saved version; choose a new cycle')
bpy.ops.wm.open_mainfile(filepath=str(R/'art/blender/cycles/cycle_26/characters.blend'))
NAME='WILLOW SCOUT';col=bpy.data.collections[NAME+' — authored study'];root=next(o for o in col.objects if o.type=='EMPTY');scene=bpy.context.scene;cam=scene.camera

def fingerprint():
 h=hashlib.sha256();count=0
 for c in bpy.data.collections:
  if 'authored study' not in c.name or c==col:continue
  for o in sorted(c.objects,key=lambda a:a.name):
   count+=1;h.update(str((o.name,[list(v) for v in o.matrix_local])).encode())
   if o.type=='MESH':
    for v in o.data.vertices:h.update(str(tuple(v.co)).encode())
    for p in o.data.polygons:h.update(str((tuple(p.vertices),p.material_index)).encode())
   if o.type=='CURVE':
    for sp in o.data.splines:
     for p in sp.points:h.update(str(tuple(p.co)).encode())
     for p in sp.bezier_points:h.update(str((tuple(p.co),tuple(p.handle_left),tuple(p.handle_right))).encode())
   if o.type in ['MESH','CURVE']:
    for m in o.data.materials:h.update(str((m.name,tuple(m.diffuse_color))).encode())
 return {'objects':count,'sha256':h.hexdigest()}
before=fingerprint()
# Identical framing and lighting for both models; no game-world changes.
for c in bpy.data.collections:
 if 'authored study' in c.name:c.hide_render=c!=col
scene.cycles.samples=32;scene.render.resolution_percentage=100

def render(file,target,offset,scale,w=900,h=1000):
 t=root.matrix_world@Vector(target);cam.location=t+Vector(offset);cam.rotation_euler=(t-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=scale
 scene.render.resolution_x=w;scene.render.resolution_y=h;scene.render.filepath=str(OUT/file);bpy.ops.render.render(write_still=True)
def review(prefix):
 render(prefix+'-front.png',(0,0,1.674),(0,-4,.025),.40)
 render(prefix+'-three-quarter.png',(0,0,1.674),(2,-4,.05),.40)
 render(prefix+'-side.png',(0,0,1.674),(4,-.15,.025),.40)
 render(prefix+'-full.png',(0,0,.96),(.5,-5,.10),2.04,900,1100)
if REV==1:review('before')
else:
 import shutil
 for f in (R/'art/blender/cycles/cycle_27').glob('before-*.png'):shutil.copyfile(f,OUT/f.name)

def mat(name,color,rough=.6):
 m=bpy.data.materials.new(NAME+' '+name);m.diffuse_color=(*color,1);m.use_nodes=True;p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*color,1);p.inputs['Roughness'].default_value=rough;p.inputs['Specular IOR Level'].default_value=.32;return m
def mesh(name,vs,fs,m):
 d=bpy.data.meshes.new(NAME+' '+name);d.from_pydata(vs,[],fs);d.update();bm=bmesh.new();bm.from_mesh(d);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(d);bm.free()
 o=bpy.data.objects.new(NAME+' '+name,d);col.objects.link(o);o.parent=root;d.materials.append(m)
 for p in d.polygons:p.use_smooth=True
 return o
def curve(name,pts,r,m):
 d=bpy.data.curves.new(NAME+' '+name,'CURVE');d.dimensions='3D';d.bevel_depth=r;d.bevel_resolution=2
 sp=d.splines.new('POLY');sp.points.add(len(pts)-1)
 for i,(p,co) in enumerate(zip(sp.points,pts)):p.co=(*co,1);p.radius=.1+.9*math.sin(math.pi*i/(len(pts)-1))**.45
 o=bpy.data.objects.new(NAME+' '+name,d);col.objects.link(o);o.parent=root;d.materials.append(m);return o
def ga(x,z,cx,cz,sx,sz):return math.exp(-((x-cx)/sx)**2-((z-cz)/sz)**2)
def smooth(x):x=max(0,min(1,x));return x*x*(3-2*x)
def interp(z,table,k):
 for i in range(len(table)-1):
  if z<=table[i+1][0]:
   t=max(0,(z-table[i][0])/(table[i+1][0]-table[i][0]));a=table[max(0,i-1)][k];b=table[i][k];c=table[i+1][k];d=table[min(len(table)-1,i+2)][k]
   span=table[i+1][0]-table[i][0];m0=(c-a)/(table[i+1][0]-table[max(0,i-1)][0]);m1=(d-b)/(table[min(len(table)-1,i+2)][0]-table[i][0])
   return (2*t**3-3*t*t+1)*b+(t**3-2*t*t+t)*span*m0+(-2*t**3+3*t*t)*c+(t**3-t*t)*span*m1
 return table[-1][k]
# Replace face/attached features as one coherent surface, keeping the ear construction.
remove=['continuous facial planes','resting eyebrow','underside nostril','shaped upper lip','shaped lower lip','fine mouth separation','fitted almond eye','shaped upper eyelid','shaped lower eyelid','restrained lash','upper orbital crease']
for o in list(col.objects):
 if any(o.name.startswith(NAME+' '+p) for p in remove):bpy.data.objects.remove(o,do_unlink=True)
skincolor=(.48,.285,.16);skin=mat('living skin',skincolor,.57);skin.node_tree.nodes['Principled BSDF'].inputs['Subsurface Weight'].default_value=.075
shadow=mat('warm facial crease',(.125,.043,.026),.85);lip=mat('soft lip skin',(.40,.17,.115),.61);hair=mat('soft umber hair',(.023,.014,.010),.52)
rings=[(1.545,.012,.018,-.025),(1.554,.032,.037,-.022),(1.574,.057,.052,-.012),(1.608,.076,.066,-.001),(1.644,.091,.082,.006),(1.678,.094,.086,.007),(1.720,.095,.086,.009),(1.752,.075,.070,.010),(1.779,.008,.012,.010)]
if REV>=2:rings[:4]=[(1.554,.010,.020,-.045),(1.562,.032,.034,-.033),(1.579,.058,.050,-.019),(1.608,.077,.073,-.002)]
if REV>=3:rings[0]=(1.551,.008,.010,-.052)
if REV>=4:rings[:4]=[(1.548,.001,.001,-.040),(1.555,.022,.021,-.039),(1.574,.056,.051,-.018),(1.608,.077,.073,-.002)]
def fy(x,z):
 w=max(.012,interp(z,rings,1));d=interp(z,rings,2);y=interp(z,rings,3)-d*math.sqrt(max(0,1-(x/w)**2))
 # Narrow bridge, small rounded tip, alar wings, philtrum and chin planes.
 y-=(.010 if REV>=2 else .014)*ga(x,z,0,1.665,.0105,.030)+(.0145 if REV>=2 else .025)*ga(x,z,0,1.645,.0115,.010)
 for side in [-1,1]:
  y-=.007*ga(x,z,side*.012,1.640,.0065,.006)
  y+=.007*ga(x,z,side*.041,1.680,.027,.018)
  y-=.006*ga(x,z,side*.058,1.650,.023,.018)
  y-=.004*ga(x,z,side*.039,1.701,.026,.009)
 y-=.006*ga(x,z,0,1.613,.030,.013)+.003*ga(x,z,0,1.568,.030,.010)
 if REV>=2:y-=.006*ga(x,z,0,1.624,.027,.016)
 y+=.0017*ga(x,z,0,1.628,.004,.007)+.002*ga(x,z,0,1.594,.026,.007)
 return y
vs=[];fs=[];nz=130;na=192
for j in range(nz+1):
 low=1.548 if REV>=4 else (1.551 if REV>=3 else (1.554 if REV>=2 else 1.545));z=low+(1.779-low)*j/nz;w=interp(z,rings,1);d=interp(z,rings,2);cy=interp(z,rings,3)
 for i in range(na):
  a=i/na*math.tau;x=w*math.sin(a);y=fy(x,z) if math.cos(a)>0 else cy-d*math.cos(a)
  # Raise the rear jaw toward the ear instead of a flat rounded underside.
  zz=z+(.032 if REV>=2 else .042)*smooth((y+.047)/.11)*smooth((1.628-z)/.083)
  vs.append((x,y,zz))
for j in range(nz):
 for i in range(na):a=j*na+i;b=j*na+(i+1)%na;fs.append((a,b,b+na,a+na))
fs.extend([tuple(range(na-1,-1,-1)),tuple(nz*na+i for i in range(na))])
head=mesh('continuous facial planes',vs,fs,skin)
a=head.data.color_attributes.new(name='Face warmth',type='FLOAT_COLOR',domain='POINT')
for v,c in zip(head.data.vertices,a.data):
 x,y,z=v.co;front=smooth((-y+.005)/.05);warm=(.23*max(ga(x,z,-.058,1.650,.023,.016),ga(x,z,.058,1.650,.023,.016))+.13*ga(x,z,0,1.644,.014,.011))*front
 c.color=(*(q*(1-warm)+r*warm for q,r in zip(skincolor,(.60,.185,.105))),1)
n=skin.node_tree.nodes.new('ShaderNodeVertexColor');n.layer_name='Face warmth';skin.node_tree.links.new(n.outputs['Color'],skin.node_tree.nodes['Principled BSDF'].inputs['Base Color'])
plain=mat('eyelid skin',skincolor,.58)
# Rounded eye surfaces and socket transitions, with painted iris variation baked per vertex.
for side in [-1,1]:
 cx=side*.041;cz=1.680;hw=.0245;upper=.0120 if REV>=3 else (.0108 if REV>=2 else .0122);lower=.0067 if REV>=2 else .0074;cy=fy(cx,cz)+.026 if REV>=2 else fy(cx,cz)+.022;radius=.030
 def ep(u,v):
  x=cx+side*u*hw;mid=cz+.0018*u;z=mid+(upper if v>=0 else lower)*max(0,1-u*u)**.72*v
  sphere=cy-math.sqrt(max(.00001,radius**2-(x-cx)**2-(z-cz)**2))
  weight=(1-u*u)*(1-v*v) if REV>=2 else 1
  y=fy(x,z)*(1-weight)+sphere*weight-.0005
  if REV>=3:y=min(y,fy(x,z)-.0012)
  return Vector((x,y,z))
 ev=[];ef=[];nu=160 if REV>=2 else 100;nv=60 if REV>=2 else 40
 for j in range(nv+1):
  for i in range(nu+1):ev.append(ep(-1+2*i/nu,-1+2*j/nv))
 for j in range(nv):
  for i in range(nu):a=j*(nu+1)+i;ef.append((a,a+1,a+nu+2,a+nu+1))
 eyemat=mat('iris and sclera '+str(side),(.65,.61,.53),.19);eyemat.node_tree.nodes['Principled BSDF'].inputs['Specular IOR Level'].default_value=.50
 eye=mesh('fitted almond eye '+str(side),ev,ef,eyemat);attr=eye.data.color_attributes.new(name='Face warmth',type='FLOAT_COLOR',domain='POINT')
 for v,c in zip(eye.data.vertices,attr.data):
  x,y,z=v.co;iris_size=.0122 if REV>=3 else (.0127 if REV>=2 else .0108);dx=(x-cx)/iris_size;dz=(z-cz-.0008)/iris_size;r=math.hypot(dx,dz);ang=math.atan2(dz,dx)
  if r<.35:color=(.006,.004,.003)
  elif r<1:
   fibers=(math.sin(ang*43+r*11)+math.sin(ang*71-r*19))*.5;light=.5+.18*fibers+.18*max(0,-dz)
   color=tuple(a+(b-a)*light for a,b in zip((.060,.023,.008),(.27,.12,.031)))
   edge=smooth((r-.83)/.17);color=tuple(q*(1-edge)+.018*edge for q in color)
  else:
   corner=min(1,max(0,(abs(dx)-1.35)/.9));color=tuple(a*(1-corner*.28)+b*corner*.28 for a,b in zip((.68,.63,.53),(.47,.25,.18)))
  if REV>=2:
   if .31<r<.39:
    t=smooth((r-.31)/.08);color=tuple(a*(1-t)+b*t for a,b in zip((.006,.004,.003),(.13,.052,.014)))
   if .95<r<1.05:
    t=smooth((r-.95)/.10);color=tuple(a*(1-t)+b*t for a,b in zip((.018,.015,.010),(.68,.63,.53)))
  c.color=(*color,1)
 n=eyemat.node_tree.nodes.new('ShaderNodeVertexColor');n.layer_name='Face warmth';eyemat.node_tree.links.new(n.outputs['Color'],eyemat.node_tree.nodes['Principled BSDF'].inputs['Base Color'])
 for top in [True,False]:
  vs=[];fs=[];steps=80;bands=12
  for j in range(bands+1):
   t=j/bands
   for i in range(steps+1):
    u=-1+2*i/steps;inner=ep(u,1 if top else -1);x=inner.x+side*u*.002*t;z=inner.z+(.0075 if top else -.0055)*max(0,1-u*u)**.6*t
    y=(1-t)*inner.y+t*fy(x,z)-.0011*math.sin(math.pi*t)*(1-u*u);vs.append((x,y,z))
  for j in range(bands):
   for i in range(steps):a=j*(steps+1)+i;fs.append((a,a+1,a+steps+2,a+steps+1))
  mesh(('shaped upper eyelid ' if top else 'shaped lower eyelid ')+str(side),vs,fs,plain)
  if top:
   curve('restrained lash '+str(side),[ep(-1+2*i/80,1)+Vector((0,-.0003,0)) for i in range(81)],.00065,hair)
   pts=[]
   for i in range(65):
    u=-.86+1.72*i/64;p=ep(u,1);z=p.z+.0075*(1-u*u)**.6;pts.append((p.x,fy(p.x,z)-.0003,z))
   curve('upper orbital crease '+str(side),pts,.0003,mat('orbital shade '+str(side),(.30,.155,.092),.82))
 # Brow silhouette has an inner rise and tapered tail; fine strands stay on its surface.
 vs=[];fs=[]
 for i in range(49):
  t=i/48;x=side*(.017+.053*t);z=1.704+.006*math.sin(math.pi*t)-.004*t;th=.0022*(.35+.65*math.sin(math.pi*t))*(1-.55*t)
  for dz in [-th,th]:vs.append((x,fy(x,z+dz)-.001,z+dz))
 for i in range(48):fs.append((2*i,2*i+1,2*i+3,2*i+2))
 mesh('resting eyebrow '+str(side),vs,fs,hair)
 nx=side*.0105;pts=[]
 for i in range(21):
  t=i/20;x=nx+side*(t-.5)*.007;z=1.638-.0012*math.sin(math.pi*t);pts.append((x,fy(x,z)-.00025,z))
 curve('underside nostril '+str(side),pts,.00065,shadow)
# Soft closed mouth with an asymmetric lifted corner and fuller central lower lip.
def mouthline(u):return 1.610+.0026*u*u+.00055*u
for top in [True,False]:
 vs=[];fs=[];steps=64;bands=12
 for j in range(bands+1):
  t=j/bands
  for i in range(steps+1):
   u=-1+2*i/steps;x=.0265*u;h=(.0043*(1-.32*math.exp(-(u/.22)**2)) if top else -.0054)*(1-u*u);z=mouthline(u)+h*t;y=fy(x,z)-.00035-.0018*math.sin(math.pi*t)*(1-u*u);vs.append((x,y,z))
 for j in range(bands):
  for i in range(steps):a=j*(steps+1)+i;fs.append((a,a+1,a+steps+2,a+steps+1))
 mesh('shaped upper lip' if top else 'shaped lower lip',vs,fs,lip)
curve('fine mouth separation',[(.0265*u,fy(.0265*u,mouthline(u))-.0006,mouthline(u)) for u in [-1+2*i/64 for i in range(65)]],.00042,shadow)
# Rebuild the swept, tied hair silhouette; broad tapered locks rather than hanging rods.
for o in list(col.objects):
 if o.name.startswith(('Continuous shaped hair foundation','Sculpted swept wave','Crown to nape wave','Scout loose silhouette tuft','Scout tied back lock','Scout fabric hair tie')):bpy.data.objects.remove(o,do_unlink=True)
# Reuse reviewed construction helpers only (do not execute an older generator baseline).
module=ast.parse((R/'tools/blender/refine_traveler_hair.py').read_text());ns={'bpy':bpy,'bmesh':bmesh,'math':math,'Vector':Vector,'col':col,'root':root,'REV':2}
exec(compile(ast.Module(body=[n for n in module.body if isinstance(n,ast.FunctionDef) and n.name in ['mesh','strands','bezier','lock','scalp']],type_ignores=[]),'<hair helpers>','exec'),ns)
base=hair;light=mat('warm hair planes',(.034,.022,.015),.53);detail=mat('hair strand shade',(.015,.009,.006),.65)
ns['scalp'](0,base)
def lock(label,points,width=.025,depth=.009):return ns['lock']('WILLOW SCOUT hair '+label,points,width,depth,base,detail)
fronts=[
[(.045,.014,1.810),(.028,-.052,1.862),(-.073,-.111,1.810),(-.098,-.076,1.705)],
[(.045,.006,1.811),(.060,-.060,1.846),(-.016,-.115,1.790),(-.062,-.100,1.736)],
[(.057,.018,1.806),(.103,-.023,1.834),(.042,-.103,1.776),(.010,-.105,1.737)],
[(.062,.009,1.802),(.125,-.013,1.797),(.113,-.089,1.740),(.105,-.057,1.685)],
[(-.029,.030,1.812),(-.088,-.015,1.844),(-.127,-.079,1.775),(-.109,-.035,1.692)],
[(-.067,.023,1.79),(-.130,-.016,1.790),(-.140,-.040,1.710),(-.112,-.018,1.671)]]
for i,points in enumerate(fronts):
 if REV>=2:points=[(x,y,z-.014 if j==1 else z) for j,(x,y,z) in enumerate(points)]
 lock('swept fringe '+str(i),points,(.036 if REV>=2 else .030) if i<3 else .023,.006 if REV>=2 else .009)
random.seed(2927)
for i in range(11):
 a=.96+i/10*(math.tau-1.92);x=math.sin(a);y=-math.cos(a)
 lock('gathered crown '+str(i),[(.035,.030,1.806),(x*.070,y*.073,1.84),(x*.128,y*.113+.01,1.744),(x*.109,y*.109+.015,1.675+random.uniform(-.01,.01))],.025,.007)
for i in range(7):
 s=(i-3)/3;lock('tied tuft '+str(i),[(s*.013,.098,1.752),(s*.047,.146,1.819),(s*.079,.199,1.80),(s*.082,.183,1.708+.020*math.cos(i))],.018,.007)
for i in range(3 if REV>=2 else 6):
 a=1.10+i*1.65 if REV>=2 else .85+i*.97;x=math.sin(a);y=-math.cos(a)
 lock('loose wave '+str(i),[(x*.08,y*.067,1.785),(x*(.116 if REV>=2 else .141),y*.10,1.805),(x*.139,y*.105,1.786),(x*.137,y*.092,1.769)],.010,.0038)
curve('hair tie',[(.022*math.sin(i/64*math.tau),.121,1.753+.022*math.cos(i/64*math.tau)) for i in range(65)],.0028,bpy.data.materials['WILLOW SCOUT waist cloth'])
if REV>=2:
 # Fine drawn grooves made the locks read as plastic. Use restrained roughness and color variation.
 for o in list(col.objects):
  if o.name.startswith(NAME+' hair ') and 'directional fibers' in o.name:
   if REV>=3:
    o.data.bevel_depth=.000055;o.data.materials[0]=mat('subtle hair fibers',(.026,.016,.011),.73)
   else:bpy.data.objects.remove(o,do_unlink=True)
 for m in [base,light,detail]:
  p=m.node_tree.nodes['Principled BSDF'];p.inputs['Roughness'].default_value=.70;p.inputs['Specular IOR Level'].default_value=.23
 for o in col.objects:
  if o.type=='MESH' and (o.name.startswith(NAME+' hair ') or o.name.startswith('Continuous shaped hair foundation')):
   m=o.data.materials[0].copy();o.data.materials[0]=m;attr=o.data.color_attributes.new(name='Face warmth',type='FLOAT_COLOR',domain='POINT')
   for i,(v,c) in enumerate(zip(o.data.vertices,attr.data)):
    a=(i%16)/16*math.tau;t=(i//16)/48;variation=1+.12*math.sin(a*5+t*3)+.06*math.sin(a*11-t*5)
    c.color=(*(q*variation for q in (.023,.014,.010)),1)
   n=m.node_tree.nodes.new('ShaderNodeVertexColor');n.layer_name='Face warmth';m.node_tree.links.new(n.outputs['Color'],m.node_tree.nodes['Principled BSDF'].inputs['Base Color'])
review('after')
after=fingerprint();assert before==after,('Other model changed',before,after)
(OUT/'verification.json').write_text(json.dumps({'source':'cycle_26','revision':REV,'unchanged_other_models':after},indent=2)+'\n')
for c in bpy.data.collections:
 if 'authored study' in c.name:c.hide_render=False
notes=bpy.data.texts.get('REVIEW STATUS');notes.clear();notes.write('Willow-only face and hair reconstruction. Matched before/after renders; see cycle review. Other seven models preserved. Illustration fidelity remains a work in progress.')
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'characters.blend'),compress=True)
print('WILLOW_REFINEMENT_COMPLETE',CYCLE,after,flush=True)
