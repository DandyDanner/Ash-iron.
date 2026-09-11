"""Author four volumetric hairstyles over the cycle 6 facial studies.
Blender --background --python tools/blender/refine_traveler_hair.py -- --art-pass=7
"""
from pathlib import Path
import bpy,bmesh,math,random,sys
from mathutils import Vector
R=Path(__file__).resolve().parents[2]
PASS=int(next((a.split('=')[1] for a in sys.argv if a.startswith('--art-pass=')),'7'))
REV=int(next((a.split('=')[1] for a in sys.argv if a.startswith('--refinement=')),'1'))
OUT=R/'art/blender/cycles'/f'cycle_{PASS:02d}'
OUT.mkdir(parents=True,exist_ok=True)
if (OUT/'characters.blend').exists():raise RuntimeError('Preserve saved pass; choose another number')
bpy.ops.wm.open_mainfile(filepath=str(R/'art/blender/cycles/cycle_06/characters.blend'))
scene=bpy.context.scene;scene.cycles.samples=32
NAMES=['WILLOW SCOUT','HEARTHLAND RANGER','RIDGE WAYFARER','EMBER FORAGER']
ANIMALS=['BRISTLEBACK BOAR','WOODLAND HOG','RIDGEBACK BOAR','MEADOW BUCK']
OLD=['Sculpted hair cap','Asymmetric swept hair lock','Fine fringe strand','Loose temple wisp','Temple and nape hair','Tied back hair tuft','Hair tie','Layered back hair','Crown braid','Trailing braid','Copper bob lock','Parted fringe']
col=None;root=None

def material(name,color):
 m=bpy.data.materials.new(name);m.diffuse_color=(*color,1);m.use_nodes=True
 p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*color,1);p.inputs['Roughness'].default_value=.60 if REV>=2 else .46;p.inputs['Specular IOR Level'].default_value=.24 if REV>=2 else .32
 return m

def mesh(name,verts,faces,mat,sub=0):
 d=bpy.data.meshes.new(name);d.from_pydata(verts,[],faces);d.update();bm=bmesh.new();bm.from_mesh(d);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(d);bm.free()
 o=bpy.data.objects.new(name,d);col.objects.link(o);o.parent=root;d.materials.append(mat)
 for p in d.polygons:p.use_smooth=True
 if sub:
  m=o.modifiers.new('Soft hair volumes','SUBSURF');m.levels=sub
 return o

def strands(name,paths,radius,mat):
 d=bpy.data.curves.new(name,'CURVE');d.dimensions='3D';d.bevel_depth=radius;d.bevel_resolution=3;d.resolution_u=2;d.use_fill_caps=True
 for pts in paths:
  sp=d.splines.new('POLY');sp.points.add(len(pts)-1)
  for i,(p,co) in enumerate(zip(sp.points,pts)):
   p.co=(*co,1);p.radius=min(1,.15+i*.18,.15+(len(pts)-1-i)*.15)
 o=bpy.data.objects.new(name,d);col.objects.link(o);o.parent=root;d.materials.append(mat)
 return o

def bezier(ctrl,t):
 a,b,c,d=map(Vector,ctrl);return a*(1-t)**3+b*3*(1-t)**2*t+c*3*(1-t)*t*t+d*t**3

def lock(name,ctrl,width,depth,mat,detail):
 pts=[bezier(ctrl,i/48) for i in range(49)];verts=[];faces=[];frames=[];sides=16
 for i,p in enumerate(pts):
  t=i/48;tan=(pts[min(48,i+1)]-pts[max(0,i-1)]).normalized();guide=Vector((p.x/.11,(p.y-.008)/.10,(p.z-1.705)/.12)).normalized()
  normal=(guide-tan*guide.dot(tan)).normalized()
  if normal.length<.1:normal=Vector((0,-1,0))
  across=tan.cross(normal).normalized();normal=across.cross(tan).normalized()
  w=width*(.45+.7*math.sin(math.pi*t))*(1-t)**.40+.00025
  h=depth*(.5+.55*math.sin(math.pi*t))*(1-t)**.48+.00015
  frames.append((p,across,normal,w,h))
  for j in range(sides):
   a=j/sides*math.tau;rib=1+.035*math.sin(a*5+t*9)
   verts.append(p+across*(math.cos(a)*w)+normal*(math.sin(a)*h*rib))
 for i in range(48):
  for j in range(sides):a=i*sides+j;b=i*sides+(j+1)%sides;faces.append((a,b,b+sides,a+sides))
 faces.extend([tuple(range(sides-1,-1,-1)),tuple(48*sides+j for j in range(sides))])
 ob=mesh(name,verts,faces,mat,1)
 paths=[]
 for frac in [-.67,-.31,.12,.51]:
  path=[]
  for i in range(5,47):
   p,across,normal,w,h=frames[i];f=frac+.025*math.sin(i*.29+frac)
   path.append(p+across*w*f+normal*(h*math.sqrt(1-f*f)+.00015))
  paths.append(path)
 strands(name+' directional fibers',paths,.00022,detail)
 return ob

def scalp(kind,mat):
 vs=[];fs=[];nu=96;nv=36
 for j in range(nv+1):
  for i in range(nu):
   a=i/nu*math.tau
   limit=(1.84-.62*math.cos(a)) if kind==3 else (1.73-.45*math.cos(a))
   limit+=.035*math.sin(a*7)+.015*math.cos(a*11)
   t=.008+j/nv*limit
   vs.append((.109*math.sin(t)*math.sin(a),.008-.099*math.sin(t)*math.cos(a),1.705+.119*math.cos(t)))
 for j in range(nv):
  for i in range(nu):a=j*nu+i;b=j*nu+(i+1)%nu;fs.append((a,b,b+nu,a+nu))
 ob=mesh('Continuous shaped hair foundation',vs,fs,mat,1);ob.modifiers.new('Soft hairline thickness','SOLIDIFY').thickness=.002

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

for kind,name in enumerate(NAMES):
 col=bpy.data.collections[name+' — authored study'];root=next(o for o in col.objects if o.type=='EMPTY')
 for ob in list(col.objects):
  if any(ob.name==p or ob.name.startswith(p+'.') for p in OLD):bpy.data.objects.remove(ob,do_unlink=True)
 color=[(.027,.017,.011),(.066,.028,.010),(.014,.009,.007),(.20,.055,.018)][kind]
 base=material(name+' authored hair',color);light=material(name+' hair strand planes',tuple(c*1.16 for c in color));shade=material(name+' hair shadow planes',tuple(c*.80 for c in color))
 scalp(kind,base);random.seed(771+kind)
 if kind in [0,1]:
  # Long overlapping paths flow from the part, around the crown and into the fringe.
  fronts=[
   [( .064,.028,1.808),(.025,-.057,1.831),(-.064,-.112,1.775),(-.093,-.079,1.686)],
   [( .071,.036,1.808),(.060,-.044,1.827),(-.020,-.109,1.779),(-.055,-.099,1.714)],
   [( .077,.038,1.795),(.092,-.026,1.820),(.050,-.109,1.774),(.002,-.110,1.739)],
   [( .074,.029,1.794),(.120,-.007,1.796),(.104,-.075,1.733),(.109,-.043,1.664)],
   [(-.028,.033,1.817),(-.072,-.021,1.818),(-.115,-.071,1.758),(-.110,-.039,1.666)]]
  for i,ctrl in enumerate(fronts):
   if kind==1:ctrl=[(x*1.03,y,z+(.004 if j<2 else .009)) for j,(x,y,z) in enumerate(ctrl)]
   lock('Sculpted swept wave',ctrl,.028 if i<3 else .020,.011 if i<3 else .009,light if i%3==0 else base,shade)
  for i in range(13):
   a=.9+i/12*(math.tau-1.8);x=math.sin(a);y=-math.cos(a)
   ctrl=[(.034,.018,1.815),(x*.072,y*.065,1.828),(x*.12,y*.111+.01,1.736),(x*.116,y*.108+.008,1.649+random.uniform(-.013,.013))]
   lock('Crown to nape wave',ctrl,.020,.008,base if i%4 else light,shade)
  if kind==0:
   # Loose edges and a compact tied tuft replace the previous long rigid spikes.
   for i in range(7):
    a=.4+i*.88;x=math.sin(a);y=math.cos(a)
    ctrl=[(x*.079,y*.073,1.782),(x*.111,y*.10,1.812),(x*.145,y*.104,1.79),(x*.142,y*.090,1.737)]
    if REV>=2:ctrl=[(x*.079,y*.073,1.782),(x*.100,y*.086,1.795),(x*.124,y*.096,1.769),(x*.114,y*.090,1.737)]
    lock('Scout loose silhouette tuft',ctrl,.013 if REV>=2 else .010,.004,base,shade)
   for i in range(7):
    s=(i-3)/3
    lock('Scout tied back lock',[(s*.018,.100,1.749),(s*.046,.164,1.784),(s*.069,.191,1.737),(s*.059,.184,1.674+.017*math.cos(i))],.014,.007,base,shade)
   strands('Scout fabric hair tie',[[Vector((.022*math.sin(i/64*math.tau),.123,1.748+.022*math.cos(i/64*math.tau))) for i in range(65)]],.003,bpy.data.materials['WILLOW SCOUT waist cloth'])
 if kind==2:
  for lane in range(7):
   x=(lane-3)*.025;pts=[]
   for j in range(181):
    a=-1.12+j/180*3.18
    if REV>=2:
     t=j/180;a=-1.36+t*3.50;px=x+.013*math.sin(t*math.pi);height=.128*math.sqrt(1-(px/.132)**2)
     pts.append((px,.008+math.sin(a)*(.109-abs(px)*.12),1.705+math.cos(a)*height))
    else:pts.append((x,.008+math.sin(a)*(.103-abs(x)*.15),1.705+math.cos(a)*(.126-abs(x)*.18)))
   braid('Woven crown braid',pts,.0088 if REV>=2 else .0075,base,light)
  for side in [-1,1]:
   for lane in range(3):
    pts=[]
    for j in range(181):
     t=j/180;pts.append((side*(.086+lane*.011)+side*.008*math.sin(t*math.pi),.065+lane*.015+.025*t,1.709-(.258+.022*lane if REV>=2 else .278)*t))
    braid('Long gathered braid',pts,.008,base,light)
 if kind==3:
  for i in range(16):
   a=.82+i/15*(math.tau-1.64);x=math.sin(a);y=-math.cos(a)
   ctrl=[(.025+x*.024,.014+y*.022,1.815),(x*.105,y*.093,1.820),(x*.143,y*.125,1.667),(x*.126+.006*math.sin(i),y*.114,1.602+.013*math.sin(i*1.7))]
   if REV>=2:
    ctrl[2]=(x*(.145+.008*math.sin(i*1.8)),y*.129,1.651)
    ctrl[3]=(x*.107+.006*math.sin(i),y*.098,1.616+.011*math.sin(i*1.7))
   lock('Rounded copper bob wave',ctrl,.032 if REV>=2 else .025,.013 if REV>=2 else .011,light if i%4==0 else base,shade)
  fronts=[[(.040,.008,1.817),(.020,-.065,1.825),(-.075,-.119,1.769),(-.100,-.078,1.697)],[(.045,.005,1.815),(.064,-.041,1.824),(.014,-.116,1.785),(-.029,-.112,1.741)],[(.055,.014,1.802),(.111,-.027,1.810),(.113,-.094,1.735),(.106,-.063,1.664)]]
  for i,ctrl in enumerate(fronts):lock('Forager side parted fringe',ctrl,.026,.010,base if i else light,shade)
  for i in range(1 if REV>=2 else 3):
   ctrl=[(.02,.00,1.81),(.025+i*.013,-.01,1.86),(-.025+i*.023,-.026,1.86),(-.031+i*.017,-.032,1.82)]
   if REV>=2:ctrl=[(.028,.024,1.813),(.023,-.009,1.849),(-.021,-.023,1.838),(-.044,-.020,1.816)]
   lock('Forager crown curl',ctrl,.010 if REV>=2 else .007,.004,base,shade)
 print('AUTHORED_HAIR',name,flush=True)

cam=scene.camera
for name in ANIMALS:bpy.data.collections[name+' — authored study'].hide_render=True

def render(target,offset,scale,file,w=1000,h=1000):
 cam.location=Vector(target)+Vector(offset);cam.rotation_euler=(Vector(target)-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.ortho_scale=scale
 scene.render.resolution_x=w;scene.render.resolution_y=h;scene.render.filepath=str(OUT/file);bpy.ops.render.render(write_still=True)

render((0,0,.94),(0,-8,1),5.8,'travelers.png',2400,1050)
render((0,0,.94),(.35,8,1.2),5.8,'travelers-rear.png',2400,1050)
for name in NAMES:bpy.data.collections[name+' — authored study'].hide_render=True
for i,name in enumerate(NAMES):
 col=bpy.data.collections[name+' — authored study'];col.hide_render=False;root=next(o for o in col.objects if o.type=='EMPTY')
 render(root.matrix_world@Vector((0,0,1.69)),(.7,-4,.30),.42,['scout-face.png','ranger-face.png','wayfarer-face.png','forager-face.png'][i])
 col.hide_render=True
bpy.data.collections[NAMES[0]+' — authored study'].hide_render=False
render((-1.8,0,1.69),(4,-1,.25),.44,'scout-profile.png')
for name in NAMES+ANIMALS:bpy.data.collections[name+' — authored study'].hide_render=False
cam.location=(4.5,-8,4.5);cam.rotation_euler=(Vector((0,1.25,1))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.ortho_scale=7.4
notes=bpy.data.texts.get('REVIEW STATUS');notes.clear();notes.write(f'Cycle {PASS}: four volumetric authored hairstyles over preserved cycle 6 facial studies. Review actual portraits. Clothing and all four animals unchanged. Offline and unrigged; concept fidelity still under development.')
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'characters.blend'),compress=True)
print('HAIR_PASS_COMPLETE',PASS,flush=True)
