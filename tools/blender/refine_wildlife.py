"""Rebuild original wildlife studies over cycle 15; preserve every traveler object."""
from pathlib import Path
import bpy,bmesh,math,random,sys,bisect
from mathutils import Vector
from mathutils.bvhtree import BVHTree
R=Path(__file__).resolve().parents[2]
PASS=int(next((a.split('=')[1] for a in sys.argv if a.startswith('--art-pass=')),'16'))
REV=int(next((a.split('=')[1] for a in sys.argv if a.startswith('--refinement=')),'1'))
OUT=R/'art/blender/cycles'/f'cycle_{PASS:02d}';OUT.mkdir(parents=True,exist_ok=True)
if (OUT/'characters.blend').exists():raise RuntimeError('Preserve saved studies; choose fresh cycle')
bpy.ops.wm.open_mainfile(filepath=str(R/'art/blender/cycles/cycle_15/characters.blend'))
N=['WILLOW SCOUT','HEARTHLAND RANGER','RIDGE WAYFARER','EMBER FORAGER'];A=['BRISTLEBACK BOAR','WOODLAND HOG','RIDGEBACK BOAR','MEADOW BUCK']
col=None;root=None

def mat(name,color,rough=.8):
 m=bpy.data.materials.new(name);m.use_nodes=True;m.diffuse_color=(*color,1)
 p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*color,1);p.inputs['Roughness'].default_value=rough;p.inputs['Specular IOR Level'].default_value=.26
 return m

def mesh(name,vs,fs,m):
 d=bpy.data.meshes.new(name);d.from_pydata(vs,[],fs);d.update();bm=bmesh.new();bm.from_mesh(d);bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=1e-6);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(d);bm.free()
 o=bpy.data.objects.new(name,d);col.objects.link(o);o.parent=root;d.materials.append(m)
 for p in d.polygons:p.use_smooth=True
 return o

def ell(name,pos,scale,m):
 vs=[];fs=[];nu=40;nv=24
 for j in range(nv+1):
  t=math.pi*j/nv
  for i in range(nu):
   a=math.tau*i/nu;vs.append(Vector(pos)+Vector((scale[0]*math.sin(t)*math.cos(a),scale[1]*math.sin(t)*math.sin(a),scale[2]*math.cos(t))))
 for j in range(nv):
  for i in range(nu):a=j*nu+i;b=j*nu+(i+1)%nu;fs.append((a,b,b+nu,a+nu))
 return mesh(name,vs,fs,m)

def curve(name,paths,r,m):
 d=bpy.data.curves.new(name,'CURVE');d.dimensions='3D';d.bevel_depth=r;d.bevel_resolution=2;d.use_fill_caps=True
 for pts in paths:
  sp=d.splines.new('POLY');sp.points.add(len(pts)-1)
  for i,(p,co) in enumerate(zip(sp.points,pts)):p.co=(*co,1);p.radius=max(.02,1-i/(len(pts)-1))
 o=bpy.data.objects.new(name,d);col.objects.link(o);o.parent=root;d.materials.append(m);return o

def cat(rows,t):
 f=t*(len(rows)-1);i=min(int(f),len(rows)-2);u=f-i;a,b,c,d=[Vector(rows[j]) for j in [max(0,i-1),i,i+1,min(len(rows)-1,i+2)]]
 return .5*(2*b+(c-a)*u+(2*a-5*b+4*c-d)*u*u+(-a+3*b-3*c+d)*u**3)

def tube(name,points,radii,m,flat=1,steps=48,sides=16):
 if REV>=3:sides=max(40,sides)
 vs=[];fs=[];centers=[cat(points,i/steps) for i in range(steps+1)]
 for i,p in enumerate(centers):
  t=i/steps;q=t*(len(radii)-1);k=min(int(q),len(radii)-2);r=radii[k]*(1-(q-k))+radii[k+1]*(q-k)
  tan=(centers[min(i+1,steps)]-centers[max(0,i-1)]).normalized();ax=Vector((1,0,0))
  if abs(tan.dot(ax))>.92:ax=Vector((0,1,0))
  ax=(ax-tan*ax.dot(tan)).normalized();up=tan.cross(ax).normalized()
  for j in range(sides):a=j/sides*math.tau;vs.append(p+r*(ax*math.cos(a)+up*math.sin(a)*flat))
 for i in range(steps):
  for j in range(sides):a=i*sides+j;b=i*sides+(j+1)%sides;fs.append((a,b,b+sides,a+sides))
 fs.extend([tuple(range(sides-1,-1,-1)),tuple(steps*sides+j for j in range(sides))]);return mesh(name,vs,fs,m)

def loft(name,rows,m):
 vs=[];fs=[];steps=160;sides=72
 for i in range(steps+1):
  y,w,h,z=cat(rows,i/steps)
  for j in range(sides):a=j/sides*math.tau;vs.append((math.sin(a)*max(.003,w),y,z+math.cos(a)*max(.003,h)))
 for i in range(steps):
  for j in range(sides):a=i*sides+j;b=i*sides+(j+1)%sides;fs.append((a,b,b+sides,a+sides))
 fs.extend([tuple(range(sides-1,-1,-1)),tuple(steps*sides+j for j in range(sides))]);return mesh(name,vs,fs,m)

def fuse(parts,m):
 bpy.ops.object.select_all(action='DESELECT')
 for o in parts:o.select_set(True)
 bpy.context.view_layer.objects.active=parts[0];bpy.ops.object.join();o=parts[0];o.name='Authored continuous wildlife anatomy'
 mod=o.modifiers.new('Unify connected anatomy','REMESH');mod.mode='VOXEL';mod.voxel_size=.0065;mod.use_smooth_shade=True;bpy.ops.object.modifier_apply(modifier=mod.name)
 mod=o.modifiers.new('Relax anatomical joins','SMOOTH');mod.factor=.65;mod.iterations=16 if REV>=3 else 5;bpy.ops.object.modifier_apply(modifier=mod.name)
 o.data.materials.clear();o.data.materials.append(m)
 for p in o.data.polygons:p.use_smooth=True
 return o

def surface(body):return BVHTree.FromPolygons([v.co for v in body.data.vertices],[p.vertices for p in body.data.polygons])

def eye(side,y,z,tree,coat,dark,iris,white,size):
 hit,n,_,_=tree.ray_cast(Vector((side*.7,y,z)),Vector((-side,0,0)),1.4)
 if hit is None:raise RuntimeError('Eye landmark misses head')
 if REV>=2:return inset_eye(hit,n,tree,coat,dark,iris,white,size)
 center=hit+n*.003;forward=(n+Vector((0,-.45,.05))).normalized();right=Vector((0,0,1)).cross(forward).normalized();up=forward.cross(right).normalized()
 ell('Inset wildlife eye',center,(size,size,size),dark)
 # Small iris disk follows the outward/forward eye orientation.
 vs=[center+forward*(size*.94)+right*math.cos(a)*size*.52+up*math.sin(a)*size*.57 for a in [i/32*math.tau for i in range(32)]]
 mesh('Wildlife amber iris',vs,[tuple(range(32))],iris)
 ell('Wildlife pupil',center+forward*size,(size*.23,size*.23,size*.29),dark)
 ell('Eye catchlight',center+forward*(size*1.20)+up*size*.25-right*size*.12,(size*.08,)*3,white)
 pts=[center+right*(math.cos(a)*size*1.12)+up*(math.sin(a)*size*.80)+forward*(size*.50) for a in [i/32*math.pi for i in range(33)]]
 curve('Soft wildlife upper lid',[pts],.004 if size<.03 else .005,coat)
 return center

def inset_eye(hit,n,tree,coat,dark,iris,white,size):
 # Build an almond lens against the actual head surface, not a projecting sphere.
 right=Vector((0,0,1)).cross(n).normalized();up=n.cross(right).normalized()
 def sample(x,z,lift=0):
  anchor=hit+right*x+up*z
  p,normal,_,_=tree.ray_cast(anchor+n*.09,-n,.18)
  return (p if p is not None else anchor)+n*lift
 vs=[];fs=[];rings=12;segments=48
 for j in range(rings+1):
  r=j/rings
  for i in range(segments):
   a=i/segments*math.tau;x=math.cos(a)*r*size*1.15;z=math.sin(a)*r*size*.58
   vs.append(sample(x,z,.0007+.005*(1-r*r)))
 for j in range(rings):
  for i in range(segments):a=j*segments+i;b=j*segments+(i+1)%segments;fs.append((a,b,b+segments,a+segments))
 mesh('Surface fitted almond wildlife eye',vs,fs,dark)
 r=size*.30
 vs=[sample(math.cos(i/40*math.tau)*r,math.sin(i/40*math.tau)*r,.006) for i in range(40)]
 mesh('Subtle amber wildlife iris',vs,[tuple(range(40))],iris)
 vs=[sample(math.cos(i/40*math.tau)*r*.53,math.sin(i/40*math.tau)*r*.72,.0067) for i in range(40)]
 mesh('Recessed wildlife pupil',vs,[tuple(range(40))],dark)
 ell('Small eye glint',sample(-r*.27,r*.35,.0075),(.0011,)*3,white)
 for upper in [True,False]:
  points=[sample(math.cos(a)*size*1.20,math.sin(a)*size*.67,.0015) for a in [i/40*math.pi+(0 if upper else math.pi) for i in range(41)]]
  curve('Fitted wildlife eyelid',[points],.0032 if upper else .0018,coat)
 return hit

def ear(side,kind,coat,inside):
 vs=[];fs=[];nu=24;nv=40
 def point(u,t):
  w=.064*math.sin(math.pi*t)**.75
  if kind==1:
   c=cat([(side*.15,-.45,.88),(side*.26,-.43,.94),(side*.31,-.51,.87),(side*.30,-.62,.76)],t)
  elif kind==3:c=Vector((side*(.075+.18*t),-.49+.04*t,1.565+.15*t))
  else:c=Vector((side*(.135+.16*t),-.44+.045*t,.89+.23*t))
  return c+Vector((side*(u*2-1)*w,-.021*math.sin(math.pi*u)*math.sin(math.pi*t),.010*math.sin(math.pi*u)*math.sin(math.pi*t)))
 for j in range(nv+1):
  for i in range(nu+1):vs.append(point(i/nu,j/nv))
 for j in range(nv):
  for i in range(nu):a=j*(nu+1)+i;fs.append((a,a+1,a+nu+2,a+nu+1))
 o=mesh('Cupped wildlife ear',vs,fs,coat);mod=o.modifiers.new('Ear rim volume','SOLIDIFY');mod.thickness=.007
 iv=[point(.16+i/nu*.68,.13+j/nv*.72)+Vector((0,-.0035,0)) for j in range(nv+1) for i in range(nu+1)]
 mesh('Inset ear velvet',iv,fs,inside)

def hoof(x,y,kind,dark):
 if REV>=3:return shaped_hoof(x,y,kind,dark)
 for split in [-1,1]:
  w=.025 if kind<3 else .014
  vs=[(x+split*w+dx*w*.90,y+dy*(.056 if kind<3 else .036),z) for z in [.021,(.119 if kind<3 else .096) if REV>=2 else (.09 if kind<3 else .078)] for dx,dy in [(-1,-1),(1,-1),(1,1),(-1,1)]]
  o=mesh('Shaped cloven hoof',vs,[(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)],dark);b=o.modifiers.new('Soft horn edge','BEVEL');b.width=.007;b.segments=3

def shaped_hoof(x,y,kind,dark):
 # Broader toe, tapered coronet and split front; top overlaps the pastern.
 scale=.59 if kind==3 else 1
 for split in [-1,1]:
  vs=[];fs=[];segments=32
  for z,width,depth,center in [(.018,.025,.058,.025),(.035,.026,.057,.025),(.072,.025,.050,.024),(.126,.021,.035,.018)]:
   zz=.018+(z-.018)*(.75 if kind==3 else 1)
   for i in range(segments):
    a=i/segments*math.tau;vs.append((x+split*center*scale+math.cos(a)*width*scale,y+math.sin(a)*depth*scale+.003,zz))
  for j in range(3):
   for i in range(segments):a=j*segments+i;b=j*segments+(i+1)%segments;fs.append((a,b,b+segments,a+segments))
  fs.extend([tuple(range(segments-1,-1,-1)),tuple(3*segments+i for i in range(segments))])
  mesh('Shaped cloven hoof',vs,fs,dark)

def fur(body,kind,coat,light,mane,eyes):
 random.seed(1001+kind);body.data.calc_loop_triangles();tris=list(body.data.loop_triangles);areas=[];total=0
 for tri in tris:total+=tri.area;areas.append(total)
 paths=[[],[],[]]
 for i in range((33000 if kind!=1 else 18000) if REV>=2 else (20000 if kind!=1 else 11000)):
  tri=tris[bisect.bisect_left(areas,random.random()*total)];u=math.sqrt(random.random());v=random.random();vv=[body.data.vertices[j] for j in tri.vertices]
  p=vv[0].co*(1-u)+vv[1].co*u*(1-v)+vv[2].co*u*v;n=(vv[0].normal*(1-u)+vv[1].normal*u*(1-v)+vv[2].normal*u*v).normalized()
  if p.z<.13 or (p.y<(-1.08 if REV>=2 else -.83) and abs(p.x)<.17) or any((p-e).length<(.030 if REV>=2 else .053) for e in eyes):continue
  ridge=kind in [0,2] and p.z>.84 and abs(p.x)<.14 and p.y>-.60
  length=random.uniform(.030,.068) if ridge else random.uniform(.013,.035) if kind==1 else random.uniform(.022,.045)
  if REV>=2:length*=.55 if p.y<-.75 else .82
  direction=Vector((0,1,-.3));tan=direction-n*direction.dot(n)
  if tan.length<.01:tan=Vector((1,0,0))
  tan.normalize();paths[2 if ridge else 1 if i%4==0 else 0].append([p+n*.0015+tan*length*t+n*math.sin(math.pi*t)*length*.16 for t in [0,.2,.4,.6,.8,1]])
 for title,ps,m in zip(['Laid body coat','Fine coat highlights','Brushed dark ridge'],paths,[coat,light,mane]):curve(title,ps,(.00042 if kind==1 else .0005) if REV>=2 else (.00065 if kind==1 else .0009),m)
 if REV>=2 and kind in [0,2]:
  tree=surface(body);locks=[]
  for j in range(7500):
   x=random.gauss(0,.058);y=random.uniform(-.62,.67);p,n,_,_=tree.ray_cast(Vector((x,y,2)),Vector((0,0,-1)),2)
   if p is None:continue
   height=random.uniform(.025,.10)*(1.15 if kind==2 else 1)*max(.15,1-abs(x)/.18)
   sweep=random.uniform(.025,.09)
   locks.append([p-n*.003+Vector((0,sweep*t,height*(t-.22*t*t))) for t in [0,.2,.4,.6,.8,1]])
  curve('Dense swept tapered mane',locks,.00085,mane)
 if REV<2 and kind in [0,2]:
  tree=surface(body)
  for j in range(30):
   y=-.54+j*.039
   for lane in [-1,0,1]:
    x=lane*.035+random.uniform(-.013,.013);p,n,_,_=tree.ray_cast(Vector((x,y,2)),Vector((0,0,-1)),2)
    if p is None:continue
    height=random.uniform(.033,.075)*(1.15 if kind==2 else 1)
    tube('Tapered swept ridge lock',[p-n*.009,p+Vector((0,.035,height)),p+Vector((random.uniform(-.012,.012),.09,height*.55)),p+Vector((0,.13,.012))],[.006,.011,.006,.00015],mane,.60,20,10)

def deer_fur(body,color,cream):
 random.seed(420);body.data.calc_loop_triangles();tris=list(body.data.loop_triangles);areas=[];total=0
 for tri in tris:total+=tri.area;areas.append(total)
 groups=[[],[]];fine=mat('Buck fine tawny guard coat',tuple(c*.86 for c in color),.9)
 for i in range(18000):
  tri=tris[bisect.bisect_left(areas,random.random()*total)];u=math.sqrt(random.random());v=random.random();vv=[body.data.vertices[j] for j in tri.vertices]
  p=vv[0].co*(1-u)+vv[1].co*u*(1-v)+vv[2].co*u*v;n=(vv[0].normal*(1-u)+vv[1].normal*u*(1-v)+vv[2].normal*u*v).normalized()
  if p.z<.23 or p.z>1.40:continue
  direction=Vector((0,1,-.4)) if p.z<1 else Vector((0,.1,-1));tan=(direction-n*direction.dot(n)).normalized();length=random.uniform(.006,.015)
  pale=p.z>1.04 and n.y<-.55 and abs(p.x)<.075
  groups[int(pale)].append([p+n*.0007+tan*length*t+n*math.sin(math.pi*t)*.001 for t in [0,.25,.5,.75,1]])
 for paths,m in zip(groups,[fine,cream]):curve('Fine directional deer coat',paths,.00027,m)

for kind,name in enumerate(A):
 col=bpy.data.collections[name+' — authored study'];root=next(o for o in col.objects if o.type=='EMPTY')
 for o in list(col.objects):
  if o!=root:bpy.data.objects.remove(o,do_unlink=True)
 colors=[(.235,.087,.029),(.43,.285,.14),(.10,.079,.052),(.32,.16,.053)]
 coat=mat(name+' sculpt coat',colors[kind],.88);light=mat(name+' fine coat light',tuple(c*1.33 for c in colors[kind]),.88);mane=mat(name+' sculpt mane',(.037,.024,.013) if kind==0 else (.022,.020,.016),.9)
 dark=mat(name+' dark horn and eye',(.020,.013,.009),.36);iris=mat(name+' amber iris',(.18,.075,.018),.42);white=mat(name+' eye highlight',(.8,.77,.66),.2);cream=mat(name+' soft cream markings',(.58,.49,.32),.88);inside=mat(name+' warm ear interior',(.22,.10,.053) if kind<3 else (.35,.22,.11),.9)
 if kind==1:
  nd=coat.node_tree.nodes;lk=coat.node_tree.links;tex=nd.new('ShaderNodeTexNoise');tex.inputs['Scale'].default_value=7;tex.inputs['Detail'].default_value=2.4;ramp=nd.new('ShaderNodeValToRGB');ramp.color_ramp.elements[0].position=.32 if REV>=3 else .20 if REV>=2 else .44;ramp.color_ramp.elements[0].color=((.12,.060,.024,1) if REV>=3 else (.25,.147,.07,1) if REV>=2 else (.12,.064,.029,1));ramp.color_ramp.elements[1].position=.64 if REV>=3 else .82 if REV>=2 else .55;ramp.color_ramp.elements[1].color=(.38,.24,.11,1) if REV>=3 else (*colors[kind],1);lk.new(tex.outputs['Fac'],ramp.inputs[0]);lk.new(ramp.outputs[0],nd.get('Principled BSDF').inputs['Base Color'])
 if kind<3:
  rows=[(-1.12,.115,.075,.47),(-.98,.145,.116,.515),(-.83,.18,.16,.575),(-.67,.235,.22,.66),(-.48,.285,.30,.71),(-.25,.335,.345,.72),(0,.343,.325,.68),(.25,.33,.30,.65),(.49,.28,.255,.64),(.69,.17,.18,.635),(.78,.015,.025,.635)]
  if kind==1:rows=[(y,w*(1.09 if y>-.4 else 1),h*(.87 if y<-.30 else 1.0),z-.035 if y<-.3 else z) for y,w,h,z in rows]
  parts=[loft('Tapered boar trunk and head',rows,coat)]
  for side in [-1,1]:
   for rear in [False,True]:
    pts=[(side*.24,-.34,.68),(side*.252,-.37,.40),(side*.245,-.35,.23),(side*.245,-.40,.105)] if not rear else [(side*.25,.43,.65),(side*.265,.40,.40),(side*.245,.50,.22),(side*.245,.475,.105)]
    if REV>=3:pts[0]=(side*.14,pts[0][1],.77 if not rear else .73)
    parts.append(tube('Angled boar limb',pts,[.103,.082,.048,.042],coat));hoof(pts[-1][0],pts[-1][1],kind,dark)
  if REV==3:
   for side in [-1,1]:parts.append(ell('Integrated jaw and cheek',(side*.14,-.71,.59),(.12,.145,.15),coat))
  body=fuse(parts,coat);tree=surface(body);eyes=[eye(s,-.745,.704 if kind!=1 else .657,tree,coat,dark,iris,white,.032 if REV>=3 else .025) for s in [-1,1]]
  for side in [-1,1]:
   ear(side,kind,coat,inside)
   if kind!=1:tube('Curved tapered ivory tusk',[(side*.15,-.96,.425),(side*.215,-1.012,.465),(side*.24,-1.03,.55),(side*.225,-1.00,.64)],[.026,.022,.013,.0002],cream,1,64,20)
  nose=mat(name+' sculpt nose leather',(.27,.11,.066) if kind==1 else (.075,.039,.025),.58)
  if REV>=4:
   pad=ell('Shaped snout pad',(0,-1.129,.47),(.124,.032,.069),nose)
   for side in [-1,1]:
    cutter=ell('Temporary nostril cutter',(side*.048,-1.156,.477),(.023,.025,.017),nose)
    bpy.context.view_layer.objects.active=pad
    cut=pad.modifiers.new('Sculpted nostril cavity','BOOLEAN');cut.operation='DIFFERENCE';cut.solver='EXACT';cut.object=cutter;bpy.ops.object.modifier_apply(modifier=cut.name)
    bpy.data.objects.remove(cutter,do_unlink=True)
    ell('Recessed nostril interior',(side*.048,-1.134,.477),(.019,.005,.013),dark)
  else:
   ell('Shaped snout pad',(0,-1.129,.47),(.124,.026,.075),nose)
   for side in [-1,1]:ell('Nostril inset',(side*.047,-1.151,.478),(.021,.005,.015),dark)
  curve('Lower snout crease',[[Vector((x,-1.105+.04*(x/.13)**2,.414+.008*(x/.13)**2)) for x in [-.13+i/40*.26 for i in range(41)]]],.0025,nose)
  tube('Curled tapered tail',[(0,.73,.66),(.022,.85,.59),(.063,.875,.62),(.055,.82,.65)],[.014,.011,.009,.001],mane,1)
  fur(body,kind,coat,light,mane,eyes)
 else:
  parts=[loft('Tapered deer barrel',[(-.40,.06,.10,.88),(-.27,.16,.225,.88),(-.08,.205,.215,.86),(.15,.207,.21,.84),(.35,.181,.195,.83),(.50,.12,.15,.82),(.56,.014,.025,.82)],coat),tube('Rising tapered deer neck',([(0,-.19,.86),(0,-.29,1.05),(0,-.40,1.24),(0,-.48,1.40),(0,-.52,1.48)] if REV>=3 else [(0,-.27,.96),(0,-.37,1.15),(0,-.48,1.37),(0,-.52,1.48)]),([.15,.14,.10,.08,.075] if REV>=3 else [.145,.115,.082,.075]),coat),loft('Wedge shaped deer head',[(-.89,.04,.033,1.445),(-.80,.060,.053,1.46),(-.68,.085,.087,1.49),(-.54,.10,.108,1.51),(-.43,.04,.04,1.49)],coat)]
  for side in [-1,1]:
   for rear in [False,True]:
    pts=[(side*.13,-.23,.87),(side*.13,-.25,.51),(side*.13,-.235,.28),(side*.13,-.25,.088)] if not rear else [(side*.14,.32,.88),(side*.145,.25,.57),(side*.14,.39,.30),(side*.14,.35,.088)]
    if REV>=3:pts[0]=(side*.055,pts[0][1],.98 if not rear else .96)
    parts.append(tube('Tapered deer leg',pts,[.061 if not rear else .082,.035 if not rear else .047,.023,.018],coat));hoof(pts[-1][0],pts[-1][1],kind,dark)
  body=fuse(parts,coat);tree=surface(body)
  attr=body.data.color_attributes.new(name='Natural coat markings',type='FLOAT_COLOR',domain='POINT')
  for v,c in zip(body.data.vertices,attr.data):
   x,y,z=v.co;n=v.normal;throat=math.exp(-(x/.080)**4)*max(0,min(1,(z-.93)/.12))*max(0,min(1,(1.45-z)/.12))*max(0,min(1,(-n.y-.3)/.45));belly=max(0,min(1,(-n.z-.45)/.45))*.65 if -.26<y<.38 and z<.82 else 0;muzzle=max(0,min(1,(-y-.72)/.09))*max(0,min(1,(1.47-z)/.025));blend=max(throat,belly,muzzle)
   c.color=(*[a*(1-blend)+b*blend for a,b in zip(colors[kind],(.58,.49,.32))],1)
  nd=coat.node_tree.nodes;lk=coat.node_tree.links;at=nd.new('ShaderNodeVertexColor');at.layer_name='Natural coat markings';lk.new(at.outputs['Color'],nd.get('Principled BSDF').inputs['Base Color'])
  if REV>=3:deer_fur(body,colors[kind],cream)
  eyes=[eye(s,-.635,1.544,tree,cream,dark,iris,white,.034 if REV>=3 else .026) for s in [-1,1]]
  for side in [-1,1]:
   ear(side,kind,light,cream)
   horn=mat('Sculpted warm antler '+str(side),(.28,.18,.079),.78)
   pts=[(side*.06,-.49,1.595),(side*.092,-.49,1.74),(side*.20,-.46,1.88),(side*.29,-.35,2.07)]
   tube('Curving antler beam',pts,[.021,.018,.012,.0002],horn,1,72,18)
   tube('Forward brow tine',[pts[1],(side*.12,-.59,1.83),(side*.15,-.64,1.94)],[.014,.01,.0002],horn,1,48,16)
   tube('Outer antler fork',[pts[2],(side*.34,-.42,1.98),(side*.39,-.35,2.10+(side*.018))],[.011,.008,.0002],horn,1,48,16)
  ell('Dark deer nose',(0,-.9,1.445),(.045,.025,.033),dark)
  curve('Deer lower muzzle line',[[Vector((x,-.855+.028*(x/.057)**2,1.416)) for x in [-.057+i/24*.114 for i in range(25)]]],.0017,dark)
  tube('Soft tapered deer tail',([(0,.49,.86),(0,.64,.83),(0,.65,.70)] if REV>=3 else [(0,.49,.86),(0,.62,.93),(0,.64,.84)]),[.035,.047,.0004],cream,.7)
 if (REV>=2 and kind==1) or (REV>=3 and kind in [0,2]):
  shortening=.73 if kind==1 else .86
  for o in col.objects:
   if o.type=='MESH':
    for v in o.data.vertices:
     if v.co.y<-.60:v.co.y=-.60+(v.co.y+.60)*shortening
   elif o.type=='CURVE':
    for sp in o.data.splines:
     for p in sp.points:
      if p.co.y<-.60:p.co.y=-.60+(p.co.y+.60)*shortening
 print('AUTHORED_WILDLIFE',name,flush=True)
scene=bpy.context.scene;scene.cycles.samples=24;cam=scene.camera
for name in N:bpy.data.collections[name+' — authored study'].hide_render=True

def render(target,offset,scale,file,w=1000,h=1000):
 cam.location=Vector(target)+Vector(offset);cam.rotation_euler=(Vector(target)-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.ortho_scale=scale;scene.render.resolution_x=w;scene.render.resolution_y=h;scene.render.filepath=str(OUT/file);bpy.ops.render.render(write_still=True)
render((0,2.5,.92),(.5,-8,2.0),6.6,'wildlife.png',2400,1100)
for name in A:bpy.data.collections[name+' — authored study'].hide_render=True
for i,name in enumerate(A):
 col=bpy.data.collections[name+' — authored study'];col.hide_render=False;root=next(o for o in col.objects if o.type=='EMPTY');slug=['bristleback','hog','ridgeback','buck'][i];target=root.matrix_world@Vector((0,-.16,.63 if i<3 else 1.07));scale=1.68 if i<2 else 1.95 if i==2 else 2.30
 render(target,(2,-4,1.05),scale,slug+'-portrait.png')
 render(target,(4,0,.35),scale*(1.43 if REV>=3 and i==3 else 1.28 if REV>=3 else 1.15),slug+'-side.png',1200,950)
 col.hide_render=True
for name in N+A:bpy.data.collections[name+' — authored study'].hide_render=False
cam.location=(4.5,-8,4.5);cam.rotation_euler=(Vector((0,1.25,1))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.ortho_scale=7.4
notes=bpy.data.texts.get('REVIEW STATUS');notes.clear();notes.write(f'Cycle {PASS}: reconstructed wildlife anatomy, ears, eyes, coats and antlers. Travelers preserved from cycle 15. Offline unrigged studies. Review actual silhouette/fur and remaining illustration-fidelity gap.')
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'characters.blend'),compress=True)
print('WILDLIFE_PASS_COMPLETE',PASS,flush=True)
