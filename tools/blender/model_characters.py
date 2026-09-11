"""Original Blender mesh studies; generate a named review pass without touching Godot.
Blender --background --factory-startup --python tools/blender/model_characters.py -- --art-pass=1
"""
from pathlib import Path
import sys, math, random, json
import bpy, bmesh
from mathutils import Vector
from mathutils.bvhtree import BVHTree
R=Path(__file__).resolve().parents[2]
CYCLE=int(next((a.split('=')[1] for a in sys.argv if a.startswith('--art-pass=')), '1'))
OUT=R/'art/blender/cycles'/f'cycle_{CYCLE:02d}'
OUT.mkdir(parents=True,exist_ok=True)
if (OUT/'characters.blend').exists(): raise SystemExit('Pass already exists; preserve it and use a new cycle number.')
random.seed(818)
bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
scene=bpy.context.scene
scene.unit_settings.system='METRIC'
scene.render.engine='CYCLES';scene.cycles.samples=24;scene.cycles.use_denoising=True
scene.render.resolution_x=1000;scene.render.resolution_y=1100;scene.render.resolution_percentage=100
scene.render.image_settings.file_format='PNG'
scene.world.use_nodes=True;scene.world.node_tree.nodes['Background'].inputs['Color'].default_value=(.55,.61,.69,1)
scene.world.node_tree.nodes['Background'].inputs['Strength'].default_value=.32
scene.view_settings.view_transform='AgX'
GROUP=None;ROOT=None
KIND=0
HERO_NAMES=['WILLOW SCOUT','HEARTHLAND RANGER','RIDGE WAYFARER','EMBER FORAGER']
ANIMAL_NAMES=['BRISTLEBACK BOAR','WOODLAND HOG','RIDGEBACK BOAR','MEADOW BUCK']

def mat(name,color,rough=.8,grain=0,metal=0):
 m=bpy.data.materials.new(name);m.diffuse_color=(*color,1);m.use_nodes=True
 n=m.node_tree.nodes; l=m.node_tree.links;p=n.get('Principled BSDF')
 p.inputs['Specular IOR Level'].default_value=.25 if CYCLE>=2 else .5
 p.inputs['Base Color'].default_value=(*color,1);p.inputs['Roughness'].default_value=rough;p.inputs['Metallic'].default_value=metal
 if grain:
  noise=n.new('ShaderNodeTexNoise');noise.inputs['Scale'].default_value=130 if grain<.2 else 48;noise.inputs['Detail'].default_value=2
  bump=n.new('ShaderNodeBump');bump.inputs['Strength'].default_value=grain;bump.inputs['Distance'].default_value=.008
  l.new(noise.outputs['Fac'],bump.inputs['Height']);l.new(bump.outputs['Normal'],p.inputs['Normal'])
 return m
skin=mat('Warm tan skin',(.48,.285,.16),.52,.05);skin.node_tree.nodes['Principled BSDF'].inputs['Subsurface Weight'].default_value=.07
hair=mat('Dark umber hair',(.033,.022,.017),.56,.10)
hair_high=mat('Hair warm planes',(.054,.032,.022),.60,.08)
cream=mat('Warm linen',(.65,.57,.40),.96,.15)
sage=mat('Sage woven cape',(.175,.215,.115),.93,.16)
sage_dark=mat('Hood fold shade',(.12,.155,.075),.96,.14)
teal=mat('Teal sash',(.052,.13,.12),.91,.16)
pants=mat('Sand canvas',(.40,.325,.21),.95,.17)
leather=mat('Worn chestnut leather',(.16,.078,.034),.7,.23)
leather_edge=mat('Leather edge and seams',(.25,.14,.067),.79,.15)
solemat=mat('Boot soles',(.056,.038,.022),.92,.15)
thread=mat('Flax stitching',(.69,.57,.34),.88)
brass=mat('Aged brass',(.46,.30,.085),.38,0,.68)
eye_white=mat('Warm eye whites',(.73,.68,.54),.27)
iris=mat('Amber brown iris',(.19,.089,.021),.27)
pupil=mat('Pupils',(.008,.006,.004),.13)
lip=mat('Subtle warm lip',(.35,.16,.103),.59)
nostril=mat('Soft nostril shadow',(.08,.027,.015),.9)
fur=mat('Russet boar coat',(.225,.092,.032),.92,.20)
fur_light=mat('Russet guard hairs',(.34,.145,.047),.88)
fur_dark=mat('Bristleback dark mane',(.047,.028,.015),.91)
hoofmat=mat('Cloven hoof horn',(.045,.037,.026),.67,.1)
nosemat=mat('Boar nose leather',(.095,.049,.027),.53,.25)
ivory=mat('Tusk ivory',(.73,.62,.40),.44,.05)
earinner=mat('Ear inner warm skin',(.22,.091,.044),.89,.1)

def group(name):
 global GROUP,ROOT
 GROUP=bpy.data.collections.new(name);scene.collection.children.link(GROUP)
 ROOT=bpy.data.objects.new(name,None);GROUP.objects.link(ROOT)
 return ROOT

def own(obj,name,material=None):
 obj.name=name
 for c in list(obj.users_collection):c.objects.unlink(obj)
 GROUP.objects.link(obj);obj.parent=ROOT
 if material is not None:obj.data.materials.append(material)
 if obj.type=='MESH':
  for p in obj.data.polygons:p.use_smooth=True
 return obj

def mesh(name,verts,faces,material,sub=0):
 d=bpy.data.meshes.new(name);d.from_pydata(verts,[],faces);d.update()
 if CYCLE>=2:
  bm=bmesh.new();bm.from_mesh(d);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(d);bm.free()
  if name.startswith(('Flat diagonal shoulder strap','Open linen collar','Open ranger jacket','Asymmetric forager wrap','Pointed ear','Ear inner velvet')):
   crease=d.attributes.new('crease_edge','FLOAT','EDGE')
   for value in crease.data:value.value=.75
 o=bpy.data.objects.new(name,d);GROUP.objects.link(o);o.parent=ROOT
 if material:d.materials.append(material)
 for p in d.polygons:p.use_smooth=True
 if sub:
  m=o.modifiers.new('Smooth sculpt surface','SUBSURF');m.levels=sub;m.render_levels=sub
 return o

def ell(name,pos,scale,material):
 bpy.ops.mesh.primitive_uv_sphere_add(segments=32,ring_count=20,location=pos)
 o=own(bpy.context.object,name,material);o.scale=scale
 bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 return o

def bevelbox(name,pos,scale,material,radius=.008):
 bpy.ops.mesh.primitive_cube_add(size=1,location=pos);o=own(bpy.context.object,name,material);o.scale=scale
 bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 b=o.modifiers.new('Soft worked edges','BEVEL');b.width=radius;b.segments=3
 o.modifiers.new('Weighted normals','WEIGHTED_NORMAL')
 return o

def tube(name,points,radii,material,flatten=1,sides=10):
 # Smooth, tapered 3D volume with a parallel-transport frame.
 pts=[Vector(p) for p in points]
 if CYCLE>=2:
  old=pts;rr=radii;pts=[];radii=[]
  for i in range(len(old)-1):
   for j in range(5):
    t=j/5;a=old[max(0,i-1)];b=old[i];c=old[i+1];d=old[min(len(old)-1,i+2)]
    pts.append((2*b+(c-a)*t+(2*a-5*b+4*c-d)*t*t+(-a+3*b-3*c+d)*t*t*t)*.5)
    radii.append(rr[i]*(1-t)+rr[i+1]*t)
  pts.append(old[-1]);radii.append(rr[-1])
  pts.insert(1,pts[0].lerp(pts[1],.08));radii.insert(1,radii[0])
  pts.insert(-1,pts[-1].lerp(pts[-2],.08));radii.insert(-1,radii[-1])
 verts=[];faces=[];prev=None
 for i,p in enumerate(pts):
  tangent=(pts[min(len(pts)-1,i+1)]-pts[max(0,i-1)]).normalized()
  if prev is None:
   normal=Vector((0,-1,0)) if abs(tangent.y)<.9 else Vector((1,0,0))
   side=tangent.cross(normal).normalized()
   if CYCLE>=4 and any(word in name.lower() for word in ['hair','fringe','bob','mane']):side=(Vector((1,0,0))-tangent*tangent.x).normalized()
  else:side=(prev-tangent*prev.dot(tangent)).normalized()
  prev=side;other=side.cross(tangent).normalized()
  for j in range(sides):
   a=j/sides*math.tau;verts.append(p+radii[i]*(side*math.sin(a)+other*math.cos(a)*flatten))
 for i in range(len(pts)-1):
  for j in range(sides):faces.append((i*sides+j,i*sides+(j+1)%sides,(i+1)*sides+(j+1)%sides,(i+1)*sides+j))
 faces.extend([tuple(range(sides-1,-1,-1)),tuple((len(pts)-1)*sides+j for j in range(sides))])
 return mesh(name,verts,faces,material,2)

def cord(name,points,radius,material):
 d=bpy.data.curves.new(name,'CURVE');d.dimensions='3D';d.resolution_u=12;d.bevel_depth=radius;d.bevel_resolution=3
 sp=d.splines.new('BEZIER');sp.bezier_points.add(len(points)-1)
 for p,co in zip(sp.bezier_points,points):
  p.co=co;p.handle_left_type='VECTOR' if CYCLE>=2 and 'chevron' in name else 'AUTO';p.handle_right_type=p.handle_left_type
 o=bpy.data.objects.new(name,d);GROUP.objects.link(o);o.parent=ROOT;d.materials.append(material)
 return o

def loft(name,rings,material,center=(0,0,0),fold=0,sides=40):
 verts=[];faces=[]
 if CYCLE>=2 and fold:
  original=rings;rings=[]
  for i in range(len(original)-1):
   for j in range(4):
    t=j/4;rings.append(tuple(original[i][k]*(1-t)+original[i+1][k]*t for k in range(4)))
  rings.append(original[-1]);fold*=1.3 if CYCLE>=3 else 2.4
 for i,(z,rx,ry,cy) in enumerate(rings):
  for j in range(sides):
   a=j/sides*math.tau
   wrinkles=fold*(math.sin(a*6+z*29)*.6+math.sin(a*9-z*17)*.4)
   verts.append((center[0]+math.sin(a)*(rx+wrinkles),center[1]+cy+math.cos(a)*(ry+wrinkles),center[2]+z))
 for i in range(len(rings)-1):
  for j in range(sides):faces.append((i*sides+j,i*sides+(j+1)%sides,(i+1)*sides+(j+1)%sides,(i+1)*sides+j))
 faces.extend([tuple(range(sides-1,-1,-1)),tuple((len(rings)-1)*sides+j for j in range(sides))])
 return mesh(name,verts,faces,material,2)

def fuse(name,objects,material,voxel=.005):
 bpy.ops.object.select_all(action='DESELECT')
 for o in objects:o.select_set(True)
 bpy.context.view_layer.objects.active=objects[0];bpy.ops.object.join();o=objects[0];o.name=name
 for mod in list(o.modifiers):bpy.ops.object.modifier_apply(modifier=mod.name)
 rem=o.modifiers.new('Continuous sculpted volume','REMESH');rem.mode='VOXEL';rem.voxel_size=voxel;rem.use_smooth_shade=True
 bpy.ops.object.modifier_apply(modifier=rem.name)
 sm=o.modifiers.new('Relax joined forms','SMOOTH');sm.factor=.6;sm.iterations=5;bpy.ops.object.modifier_apply(modifier=sm.name)
 o.data.materials.clear();o.data.materials.append(material)
 for p in o.data.polygons:p.use_smooth=True
 return o

def ring(name,center,r1,r2,material,rotation=None):
 bpy.ops.mesh.primitive_torus_add(major_radius=r1,minor_radius=r2,major_segments=32,minor_segments=8,location=center)
 o=own(bpy.context.object,name,material)
 if rotation:o.rotation_euler=rotation
 return o

def scout(kind=0):
 global KIND
 KIND=kind
 root=group(HERO_NAMES[kind]+' — authored study')
 # Continuous tapered trouser legs and folded boot construction.
 for side in [-1,1]:
  x=side*.10
  loft('Canvas trouser leg',[(.29,.061,.058,0),(.32,.067,.064,0),(.39,.071,.072,.0),(.47,.064,.066,-.007),(.54,.067,.066,-.005),(.65,.078,.076,0),(.79,.090,.089,.005),(.96,.092,.090,.006),(1.0,.081,.082,0)],pants,(x,0,0),.005)
  loft('Rolled trouser cuff',[(.285,.060,.060,0),(.289,.072,.067,0),(.315,.074,.069,0),(.329,.062,.062,0)],pants,(x,0,0),.003)
  ell('Exposed ankle',(x,0,.255),(.041,.044,.064),skin)
  boot=fuse('Shaped leather boot',[ell('Foot',(x,-.041,.068),(.071,.128,.052),leather),ell('Instep',(x,-.006,.12),(.058,.075,.089),leather)],leather,.004)
  loft('Folded boot cuff',[(.178,.057,.061,0),(.198,.074,.074,0),(.228,.068,.062,.006),(.233,.058,.051,.006)],leather,(x,0,0),.004)
  ell('Layered boot sole',(x,-.043,.023),(.073,.13,.015),solemat)
  for n in range(5):
   z=.10+n*.019;y=-.094+n*.008
   cord('Crossed flax laces',[(x-.035,y,z),(x+.035,y-.004,z+.012)],.0027,thread)
   cord('Crossed flax laces',[(x+.035,y,z),(x-.035,y-.004,z+.012)],.0027,thread)
  # Simple sewn cargo pockets follow the outer thigh.
  pocket=bevelbox('Canvas pocket flap',(x+side*.065,-.033,.71),(.045,.088,.115),pants,.01)
  cord('Pocket seam',[(x+side*.09,-.078,.75),(x+side*.093,-.079,.665)],.0014,thread)
 loft('Linen shirt',[(.91,.147,.092,0),(.95,.16,.100,0),(1.05,.149,.094,0),(1.16,.157,.103,0),(1.30,.178,.106,0),(1.40,.198,.104,0),(1.44,.190,.093,0),(1.48,.065,.059,0)],cream,fold=.003)
 ell('Neck',(0,0,1.492),(.045,.045,.080),skin)
 for side in [-1,1]:
  tube('Loose rolled linen sleeve',[(side*.192,0,1.415 if CYCLE>=4 else 1.43),(side*.238,0,1.38),(side*.26,-.003,1.26),(side*.27,-.005,1.18)],([.043,.056,.051,.041] if CYCLE>=2 else [.048,.071,.061,.051]),sage if CYCLE>=3 and KIND==1 else cream,.88)
  cuff=ring('Rolled sleeve cuff',(side*.267,-.005,1.185),.043 if CYCLE>=2 else .051,.007 if CYCLE>=2 else .012,cream)
  tube('Forearm',[(side*.267,0,1.18),(side*.28,-.008,1.10),(side*.303,-.015,.965)],[.037,.04,.024],skin,.90)
  ell('Palm',(side*.310,-.018,.931),(.034,.021,.049),skin)
  for n in range(4):
   xx=side*.31+(n-1.5)*.015
   tube('Relaxed finger',[(xx,-.019,.908),(xx,-.026,.879),(xx,-.033,.859+abs(n-1.5)*.007)],[.008,.007,.005],skin,.88,8)
  tube('Thumb',[(side*.281,-.024,.947),(side*.268,-.037,.924),(side*.271,-.047,.908)],[.012,.010,.007],skin,.85,8)
  for n in range(3):ring('Leather wrist wraps',(side*.3,-.015,.987+n*.01),.025,.0034,leather)
  collar=mesh('Open linen collar',[(side*.024,-.057,1.49),(side*.085,-.094,1.44),(side*.052,-.113,1.36),(side*.015,-.095,1.42)],[(0,1,2,3)],cream,1)
  sol=collar.modifiers.new('Cloth thickness','SOLIDIFY');sol.thickness=.003
 for n in range(5):ell('Wood shirt button',(0,-.105,1.08+n*.049),(.005,.003,.005),leather)
 # Real cloth sash, asymmetric hanging tails, broad leather band.
 loft('Gathered teal waist sash',[(.947,.153,.102,0),(.957,.163,.106,0),(.977,.165,.105,0),(.997,.163,.106,0),(1.019,.156,.101,0)],teal,fold=.004)
 tail=mesh('Loose sash tail',[(-.14,-.11,.99),(-.20,-.108,.94),(-.21,-.12,.73),(-.17,-.127,.68),(-.117,-.115,.96)],[(0,1,2,3,4)],teal,2)
 tail.modifiers.new('Woven cloth thickness','SOLIDIFY').thickness=.004
 # Belt curves around waist; pouches have rounded corners, flaps and stitches.
 for side in [-1,1]:
  x=side*.17
  bevelbox('Leather hip pouch',(x,-.092,.916),(.104,.07,.135),leather,.014)
  bevelbox('Overlapping pouch flap',(x,-.133,.955),(.109,.012,.059),leather_edge,.008)
  ell('Pouch brass fastener',(x,-.143,.938),(.006,.003,.006),brass)
  cord('Pouch edge seam',[(x-.044,-.132,.925),(x-.041,-.134,.862),(x+.04,-.134,.862),(x+.045,-.132,.925)],.0015,thread)
 cord('Slanted leather waist belt',[(-.154,-.092,.952),(-.05,-.12,.972),(.10,-.114,1.006),(.16,-.07,1.024)],.012,leather)
 strap=mesh('Flat diagonal shoulder strap',[(-.169,-.13,1.424),(-.137,-.14,1.432),(.153,-.12,.990),(.126,-.128,.971)],[(0,1,2,3)],leather,1)
 strap.modifiers.new('Leather thickness','SOLIDIFY').thickness=.006
 cord('Strap stitched edge',[(-.161,-.143,1.42),(-.02,-.146,1.20),(.13,-.13,.987)],.0013,thread)
 bevelbox('Strap buckle',(-.016,-.153,1.201),(.043,.010,.041),brass,.003)
 bevelbox('Buckle inner leather',(-.016,-.16,1.201),(.027,.005,.025),leather,.001)
 make_head()
 if KIND in [0,2]:make_cape()
 add_outfit(KIND)
 root.location.x=[-1.8,-.60,.60,1.8][KIND]
 root.scale=Vector([(1,1,1),(1.10,1.07,1.045),(1.13,1.06,1.055),(.97,.99,.99)][KIND])
 return root

def make_head():
 head=loft('Head sculpt',[(1.516,.030,.040,-.007),(1.539,.055,.059,-.004),(1.580,.080,.072,0),(1.627,.098,.083,.005),(1.672,.101,.086,.007),(1.72,.096,.088,.009),(1.755,.070,.072,.011),(1.779,.018,.023,.010)],skin)
 parts=[head]
 parts.append(ell('Nasal bridge',(0,-.073 if CYCLE>=2 else -.079,1.66),(.011,.011 if CYCLE>=2 else .020,.032),skin))
 parts.append(ell('Nose tip',(0,-.087 if CYCLE>=2 else -.103,1.631),(.016,.015 if CYCLE>=2 else .025,.012),skin))
 for side in [-1,1]:
  parts.append(ell('Nose wing',(side*.012,-.082 if CYCLE>=2 else -.094,1.625),(.009,.009 if CYCLE>=2 else .015,.009),skin))
  if CYCLE<2:parts.append(ell('Cheek plane',(side*.056,-.062,1.621),(.033,.024,.026),skin))
 head=fuse('Continuous face and nose sculpt',parts,skin,.0025)
 for side in [-1,1]:
  ell('Ear',(side*.102,.003,1.643),(.014,.012,.028) if CYCLE>=2 else (.018,.014,.035),skin)
  ell('Ear hollow',(side*.109,-.008,1.644),(.006,.002,.015),lip)
  ell('Eye',(side*.044,-.066 if CYCLE>=2 else -.081,1.667),(.023,.014,.014) if CYCLE>=2 else (.027,.021,.018),eye_white)
  ell('Iris',(side*.044,-.0798 if CYCLE>=2 else -.1018,1.667),(.0115,.003,.012),iris)
  ell('Pupil',(side*.044,-.082 if CYCLE>=2 else -.104,1.667),(.006,.002,.007),pupil)
  cord('Upper eyelid',([(side*.022,-.069,1.666),(side*.044,-.082,1.680),(side*.066,-.062,1.670)] if CYCLE>=2 else [(side*.019,-.089,1.666),(side*.044,-.099,1.683),(side*.071,-.082,1.670)]),.003,skin)
  cord('Upper lash line',([(side*.022,-.071,1.667),(side*.044,-.084,1.679),(side*.066,-.064,1.670)] if CYCLE>=2 else [(side*.020,-.091,1.667),(side*.044,-.101,1.681),(side*.070,-.084,1.670)]),.0012,hair)
  cord('Lower eyelid',([(side*.022,-.069,1.665),(side*.044,-.081,1.655),(side*.066,-.062,1.669)] if CYCLE>=2 else [(side*.020,-.089,1.665),(side*.044,-.099,1.652),(side*.070,-.082,1.669)]),.0025,skin)
  tube('Shaped eyebrow',[(side*.023,-.082,1.704),(side*.044,-.089,1.710),(side*.073,-.071,1.70)],[.003,.005,.0005],hair,.4,8)
  ell('Nostril',(side*.010,-.098 if CYCLE>=2 else -.114,1.623),(.0035,.002,.002),nostril)
 cord('Mouth line',[(-.024,-.076,1.586),(0,-.082,1.582),(.024,-.076,1.587)],.0016,lip)
 cord('Lower lip',[(-.017,-.079,1.581),(0,-.084,1.578),(.017,-.079,1.581)],.0025,skin)
 # Open cap stops above brows; multiple swept volumes form the hairstyle.
 verts=[];faces=[];nu=48;nv=12
 for r in range(nv+1):
  for j in range(nu):
   a=j/nu*math.tau;limit=1.60+.38*math.cos(a)
   t=.03+r/nv*limit
   verts.append((math.sin(a)*math.sin(t)*.109,math.cos(a)*math.sin(t)*.095+.008,math.cos(t)*.112+1.705))
 for r in range(nv):
  for j in range(nu):faces.append((r*nu+j,r*nu+(j+1)%nu,(r+1)*nu+(j+1)%nu,(r+1)*nu+j))
 mesh('Sculpted hair cap',verts,faces,hair,1)
 for i in range(0 if CYCLE>=3 else (8 if KIND in [0,1] else 0)):
  x=-.069+i*.021
  tube('Swept layered fringe',[(x+.040,.025,1.794),(x+.045,-.042,1.80),(x-.013,-.096,1.758),(x-.032,-.090,1.706+abs(i-2)*.010)],[.014,.029,.025,.0006],hair_high if i%3==0 else hair,.30)
 if CYCLE>=3 and KIND in [0,1]:
  # Offset, taper and turn the clumps around the scalp; avoid a repeated comb silhouette.
  random.seed(931+KIND)
  for i in range(13):
   x=-.088+i*.0145;variation=random.uniform(-.012,.012)
   pts=[(x*.6,.028,1.802+variation),(x*.95,-.035,1.792+variation),(x-.018,-.078,1.763+variation),(x-.03,-.090,1.727+variation+(i%3)*.008)]
   tube('Asymmetric swept hair lock',pts,[.009,.018,.015,.0004],hair_high if i%4==0 else hair,.17)
   # Fine directional grooves sit on each lock, rather than a noise texture alone.
   for offset in [-.004,.003]:
    cord('Fine fringe strand',[(px+offset,py-.003,pz+.001) for px,py,pz in pts[1:]],.00055,hair_high)
  for side in [-1,1]:
   tube('Loose temple wisp',[(side*.085,-.021,1.745),(side*.104,-.047,1.708),(side*.106,-.029,1.679)],[.008,.011,.0003],hair,.16)
 for side in [-1,1]:
  for i in range(4 if KIND in [0,1] else 0):
   tube('Temple and nape hair',[(side*.071,.017+i*.018,1.759),(side*.107,.023+i*.018,1.706),(side*(.10+i*.005),.034+i*.02,1.658-i*.006)],[.012,.021,.0005],hair,.36)
 for i in range(6 if KIND==0 else 0):
  tube('Tied back hair tuft',[(0,.102,1.748),((i-2.5)*.012,.154,1.773),((i-2.5)*.019,.19,1.707+(i%2)*.02)],[.011,.021,.0005],hair_high if i%3==0 else hair,.5)
 if KIND==0:ring('Hair tie',(0,.12,1.745),.025,.004,teal,(math.pi/2,0,0))
 if CYCLE>=4 and KIND in [0,1]:
  for i in range(9):
   x=(i-4)*.020
   tube('Layered back hair',[(x*.7,.051,1.785),(x,.096,1.723),(x*.93,.102,1.644+abs(i-4)*.005)],[.010,.018,.0005],hair_high if i%4==0 else hair,.24)
 specialized_hair(KIND,head)

def cape_point(t,a):
 spread=min(1,t/(.20 if CYCLE>=4 else (.15 if CYCLE>=3 else .38)));spread=spread*spread*(3-2*spread)
 w=.055+(.245 if CYCLE>=4 else (.215 if CYCLE>=3 else (.205 if CYCLE>=2 else .185)))*spread+(.050 if CYCLE>=4 else .079)*t*t;d=.060+.065*spread+.068*t*t
 fold=(math.sin(a*7+t*2)*.006+math.sin(a*11-t)*.002)*t
 return (math.sin(a)*(w+fold),-math.cos(a)*(d+fold),1.499-(.279 if KIND==0 else .355)*t+.012*math.sin(a*3)*t*t)

def make_cape():
 verts=[];faces=[];rows=14;cols=64
 for r in range(rows+1):
  for c in range(cols+1):verts.append(cape_point(r/rows,.31+c/cols*(math.tau-.62)))
 for r in range(rows):
  for c in range(cols):a=r*(cols+1)+c;faces.append((a,a+1,a+cols+2,a+cols+1))
 o=mesh('Draped sage shoulder cape',verts,faces,sage,2);o.modifiers.new('Cloth hem thickness','SOLIDIFY').thickness=.003
 pts=[cape_point(.98,.31+c/64*(math.tau-.62)) for c in range(65)];cord('Cape bound hem',pts,.0025,sage_dark)
 for i in range(13):
  a=.45+i/12*(math.tau-.9)
  pts=[cape_point(.91,a-.045),cape_point(.80,a),cape_point(.91,a+.045)]
  pts=[(x*1.005,y*1.018,z) for x,y,z in pts];cord('Embroidered hem chevron',pts,.003,thread)
 hood=loft('Hanging folded hood',[(1.22,.012,.015,.191),(1.27,.065,.030,.185),(1.35,.109,.045,.157),(1.44,.082,.049,.083),(1.49,.071,.028,.057)],sage_dark,fold=.003)
 cord('Hood center seam',[(0,.218,1.23),(0,.204,1.32),(0,.18,1.38),(0,.117,1.46)],.0017,sage)
 for side in [-1,1]:ring('Cape brass eyelet',(side*.045,-.07,1.47),.009,.002,brass,(math.pi/2,0,0))
 cord('Cape leather fastening',[(-.043,-.079,1.47),(0,-.086,1.462),(.043,-.079,1.47)],.0025,leather)

def boar(kind=0):
 global KIND
 KIND=kind
 root=group(ANIMAL_NAMES[kind]+' — authored study')
 parts=[ell('Barrel',(0,.12,.62),(.345,.59,.31) if CYCLE>=3 else (.385,.59,.33),fur),ell('Heavy shoulders',(0,-.28,.73),(.325,.36,.335) if CYCLE>=3 else (.375,.36,.365),fur),ell('Rump',(0,.47,.62),(.32,.31,.30),fur),ell('Wedge head',(0,-.61,.62),(.25,.34,.245),fur),ell('Sloping muzzle',(0,-.87,.46),(.17,.28,.16),fur)]
 for side in [-1,1]:
  for y in [-.32,.43]:
   x=side*.25
   parts.extend([ell('Upper leg',(x,y,.36),(.091,.115,.225),fur),ell('Lower leg',(x,y+.025,.18),(.058,.066,.125),fur)])
 body=fuse('Continuous boar anatomy',parts,fur,.008)
 for side in [-1,1]:
  for y in [-.32,.43]:
   for split in [-1,1]:bevelbox('Cloven hoof',(side*.25+split*.026,y-.011,.063),(.048,.111,.098),hoofmat,.012)
  center=Vector((side*.206,-.733,.69));look=Vector((side*.65,-.75,.07)).normalized()
  eye=ell('Boar dark eye',center,(.032,.032,.032),pupil)
  ir=ell('Boar amber iris',center+look*.029,(.016,.005,.016),iris);ir.rotation_euler=look.to_track_quat('-Y','Z').to_euler()
  tube('Expressive boar brow',[(side*.16,-.72,.753),(side*.226,-.728,.742),(side*.254,-.672,.72)],[.01,.021,.008],fur_dark,.5)
  if KIND!=1:tube('Curved ivory tusk',[(side*.151,-.992,.41),(side*.235,-1.04,.444),(side*.267,-1.056,.54),(side*.251,-1.055,.631)],[.033,.027,.015,.0005],ivory,1)
  ear=mesh('Pointed ear',[(side*.13,-.40,.84),(side*.25,-.37,.86),(side*.32,-.36,1.075),(side*.18,-.42,1.025),(side*.20,-.34,.94)],[(0,1,4),(1,2,4),(2,3,4),(3,0,4)],fur_dark,2)
  ear.modifiers.new('Ear thickness','SOLIDIFY').thickness=.012
  mesh('Ear inner velvet',[(side*.16,-.425,.876),(side*.236,-.399,.89),(side*.289,-.39,1.03),(side*.204,-.43,.985)],[(0,1,2,3)],earinner,2)
 ell('Nose pad',(0,-1.117,.445),(.157,.036,.105),nosemat)
 for side in [-1,1]:ell('Recessed nostril',(side*.060,-1.15,.452),(.026,.008,.019),nostril)
 for i in range(4):
  y=-.87-i*.05;z=.593-i*.022
  cord('Muzzle wrinkle',[(-.095,y,z-.009),(0,y-.017,z),(.095,y,z-.009)],.003,nosemat)
 cord('Boar mouth crease',[(-.15,-1.067,.396),(0,-1.12,.377),(.15,-1.067,.396)],.003,nosemat)
 cord('Curved tail',[(0,.73,.64),(.015,.84,.58),(.049,.87,.60),(.056,.835,.632)],.013,fur_dark)
 if KIND!=1:
  make_fur(body)
  if CYCLE>=3:
   bpy.context.view_layer.update()
   surface=BVHTree.FromObject(body,bpy.context.evaluated_depsgraph_get())
   for i in range(17):
    y=-.32+i*.046;z=1.022-.085*((y+.22)/.75)**2
    for lane in [-1,0,1]:
     x=lane*.029
     if CYCLE>=4:
      co,normal,index,dist=surface.ray_cast(body.matrix_local.inverted()@Vector((x,y,2)),Vector((0,0,-1)))
      if co is None:continue
      z=(body.matrix_local@co).z;lift=random.uniform(.023,.07)
      tube('Swept mane clump',[(x,y,z-.012),(x+.008*math.sin(i),y+.033,z+lift),(x+.012*math.cos(i),y+.092,z+lift*.65)],[.012,.018,.0004],fur_dark,.30,8)
     else:tube('Swept mane clump',[(x,y,z-.03),(x,y+.05,z+.047),(x,y+.13,z+.027)],[.019,.023,.0004],fur_dark,.25,8)

 if KIND==1:
  for ob in list(GROUP.objects):
   if ob.name.startswith(('Pointed ear','Ear inner velvet')):bpy.data.objects.remove(ob,do_unlink=True)
  for side in [-1,1]:tube('Floppy hog ear',[(side*.16,-.45,.85),(side*.30,-.49,.83),(side*.29,-.61,.73)],[.045,.11,.012],earinner,.25)
 root.location.x=[-2.10,-.72,.73][KIND]
 root.scale=Vector([(1,1,1),(1.04,.89,.86),(1.16,1.12,1.14)][KIND])
 root.rotation_euler.z=-.18
 return root

def make_fur(body):
 # Sample the actual remeshed body surface, so strands emerge from skin instead of floating.
 bpy.context.view_layer.update();deps=bpy.context.evaluated_depsgraph_get();ev=body.evaluated_get(deps);m=ev.to_mesh();m.calc_loop_triangles()
 tris=list(m.loop_triangles);areas=[];total=0
 for tri in tris:total+=tri.area;areas.append(total)
 import bisect
 curves=[]
 for title,material in [('Russet coat',fur),('Copper guard hairs',fur_light),('Dark mane',fur_dark)]:
  d=bpy.data.curves.new(title,'CURVE');d.dimensions='3D';d.resolution_u=2;d.bevel_depth=.00085 if CYCLE>=2 else .0020;d.bevel_resolution=1;d.materials.append(material)
  o=bpy.data.objects.new(title,d);GROUP.objects.link(o);o.parent=ROOT;curves.append(d)
 for k in range(13500 if CYCLE>=2 else 6500):
  tri=tris[bisect.bisect_left(areas,random.random()*total)];a,b,c=[m.vertices[i] for i in tri.vertices]
  u=math.sqrt(random.random());v=random.random()
  pos=body.matrix_local@((1-u)*a.co+u*(1-v)*b.co+u*v*c.co)
  norm=(a.normal*(1-u)+b.normal*u*(1-v)+c.normal*u*v).normalized()
  if pos.z<.28 or (pos.y<-.78 and abs(pos.x)<.18):continue
  if CYCLE>=2 and ((abs(pos.x)-.206)/.053)**2+((pos.y+.733)/.066)**2+((pos.z-.69)/.064)**2<1:continue
  mane=abs(pos.x)<.115 and pos.z>.85 and pos.y>-.50
  length=(random.uniform(.025,.055) if not mane else random.uniform(.08,.13)) if CYCLE>=2 else (random.uniform(.026,.060) if not mane else random.uniform(.105,.16))
  tangent=Vector((0,.85,-.45));tangent=(tangent-norm*tangent.dot(norm)).normalized()
  direction=(norm*(.10 if CYCLE>=2 else .5)+tangent*.9).normalized()
  d=curves[2 if mane else (1 if k%4==0 else 0)]
  sp=d.splines.new('POLY');sp.points.add(3)
  for i,p in enumerate(sp.points):
   t=i/3;co=pos+norm*.002+norm*(math.sin(t*math.pi/2)*length*(.13 if CYCLE>=2 else .45))+direction*(t*t*length*.8)
   p.co=(*co,1);p.radius=(1-t)*.8+.04
 ev.to_mesh_clear()

# Materials are per design; this does not change the game's customization or inventory.
def configure_hero(kind):
 global skin,hair,hair_high,sage,sage_dark,cream,pants,teal,leather
 colors=[
  ((.48,.285,.16),(.033,.022,.017),(.175,.215,.115),(.65,.57,.40),(.40,.325,.21)),
  ((.45,.24,.12),(.070,.032,.014),(.13,.16,.070),(.55,.46,.29),(.18,.105,.052)),
  ((.19,.088,.040),(.016,.010,.007),(.080,.135,.19),(.45,.25,.045),(.090,.085,.065)),
  ((.62,.37,.21),(.20,.061,.020),(.12,.17,.077),(.58,.33,.066),(.34,.13,.054))][kind]
 skin=mat(HERO_NAMES[kind]+' skin',colors[0],.53,.04);skin.node_tree.nodes['Principled BSDF'].inputs['Subsurface Weight'].default_value=.06
 hair=mat(HERO_NAMES[kind]+' hair',colors[1],.6,.10);hair_high=mat(HERO_NAMES[kind]+' hair highlights',tuple(c*1.4 for c in colors[1]),.62,.08)
 sage=mat(HERO_NAMES[kind]+' outer cloth',colors[2],.94,.16);sage_dark=mat(HERO_NAMES[kind]+' fold shade',tuple(c*.74 for c in colors[2]),.96,.15)
 cream=mat(HERO_NAMES[kind]+' shirt',colors[3],.95,.15);pants=mat(HERO_NAMES[kind]+' trousers',colors[4],.93,.17)
 teal=mat(HERO_NAMES[kind]+' waist cloth',(.052,.13,.12) if kind==0 else colors[2],.95,.15)

def specialized_hair(kind,head):
 if kind==1:
  # Short beard follows the actual face surface, avoiding the lips and nose.
  random.seed(418)
  d=bpy.data.curves.new('Short ranger beard','CURVE');d.dimensions='3D';d.bevel_depth=.0008;d.bevel_resolution=1;d.materials.append(hair)
  o=bpy.data.objects.new('Short ranger beard',d);GROUP.objects.link(o);o.parent=ROOT
  for v in head.data.vertices:
   p=head.matrix_local@v.co
   if 1.537<p.z<1.626 and p.y<-.044 and random.random()<.22 and not(abs(p.x)<.027 and p.z>1.57):
    sp=d.splines.new('POLY');sp.points.add(1);sp.points[0].co=(*p,1);sp.points[1].co=(*(p+Vector((0,-.002,-.007))),1);sp.points[1].radius=.1
 if kind==2:
  for lane in range(7):
   x=(lane-3)*.026
   for twist in [-1,1]:
    pts=[]
    for j in range(19):
     t=j/18;a=-1.04+t*2.72
     pts.append((x+math.sin(t*math.pi*14+twist*math.pi/2)*.004,math.sin(a)*.101+.008,1.7+math.cos(a)*(.113-abs(x)*.16)))
    cord('Crown braid',pts,.0065,hair_high if lane%3==0 else hair)
  for side in [-1,1]:
   for lane in range(3):
    for twist in [-1,1]:
     pts=[(side*(.08+lane*.014)+math.sin(j*.95+twist*math.pi/2)*.005,.08+lane*.013,1.71-j*.012) for j in range(24)]
     cord('Trailing braid',pts,.007,hair)
 if kind==3:
  for i in range(15):
   a=(1.05+i/14*(math.tau-2.10)) if CYCLE>=3 else (.56+i/14*(math.tau-1.12))
   x=math.sin(a)*.086;y=-math.cos(a)*.078
   tube('Copper bob lock',[(x*.75,y*.75,1.783),(x*1.19,y*1.22,1.699),(x*1.11,y*1.27,1.595+.015*math.sin(i))],[.012,.026,.003],hair_high if i%3==0 else hair,.44)
  for i in range(5):
   x=-.06+i*.024
   tube('Parted fringe',[(x+.025,-.009,1.80),(x+.025,-.079,1.774),(x-.020,-.094,1.710+abs(i-1)*.01)],[.012,.023,.001],hair,.38)
  random.seed(432)
  for side in [-1,1]:
   for i in range(9):
    ell('Freckle',(side*random.uniform(.041,.069),-.081,random.uniform(1.624,1.645)),(.0012,.0007,.001),lip)

def add_outfit(kind):
 if kind in [1,2]:
  scarf=mat('Rust scarf' if kind==1 else 'Ivory knitted scarf',(.31,.10,.044) if kind==1 else (.62,.55,.39),.98,.17)
  for n in range(4):
   o=ring('Soft scarf wrap',(0,.005,1.469+n*.012),.067+n*.002,.011,scarf);o.scale.y=.85
 if kind==1:
  for side in [-1,1]:
   panel=mesh('Open ranger jacket',[(side*.040,-.117,1.455 if CYCLE>=3 else 1.37),(side*.195,-.11,1.442 if CYCLE>=3 else 1.41),(side*.179,-.12,1.12),(side*.16,-.118,.95),(side*.060,-.13,.956)],[(0,1,2,3,4)],sage,2)
   panel.modifiers.new('Jacket thickness','SOLIDIFY').thickness=.007
  loft('Jacket back',[(.95,.16,.071,.05),(1.15,.171,.075,.05),(1.35,.188,.075,.04),(1.42,.17,.069,.04),(1.46,.10,.061,.025),(1.475,.061,.052,.01)],sage,fold=.003)
 if kind==3:
  skirt=mesh('Asymmetric forager wrap',[(-.15,-.104,.973),(.16,-.099,.995),(.15,-.15,.58),(-.05,-.155,.67),(-.18,-.12,.77)],[(0,1,2,3,4)],sage,2)
  skirt.modifiers.new('Wrap thickness','SOLIDIFY').thickness=.004
  wicker=mat('Willow basket fibers',(.28,.17,.069),.95,.2)
  loft('Forager basket',[(.94,.081,.065,.18),(1.0,.13,.088,.18),(1.20,.139,.10,.18),(1.30,.133,.09,.18)],wicker)
  for z in [1.0+i*.022 for i in range(14)]:
   pts=[(math.sin(a)*.137,.18+math.cos(a)*.097,z) for a in [i/32*math.tau for i in range(33)]];cord('Basket weave ring',pts,.0028,leather_edge)
  leafmat=mat('Fresh gathered herbs',(.085,.22,.033),.91)
  for i in range(10):
   x=(i-4.5)*.024;y=.18+math.sin(i*2)*.06
   cord('Herb stem',[(x,y,1.25),(x*1.25,y,1.45+(i%3)*.023)],.002,leafmat)
   for j in range(3):
    z=1.34+j*.039;o=ell('Herb leaf',(x+(-1)**j*.028,y,z),(.041,.011,.015),leafmat);o.rotation_euler.y=(-1)**j*.45
 if kind in [1,2]:
  bevelbox('Travel pack',(0,.17,1.18),(.24,.15,.29),leather,.025)
  if CYCLE>=4:
   bevelbox('Pack folded top flap',(0,.25,1.285),(.232,.018,.07),leather_edge,.012)
   cord('Pack stitched seam',[(-.098,.249,1.25),(-.098,.249,1.062),(.098,.249,1.062),(.098,.249,1.25)],.0018,thread)
   for x in [-.066,.066]:
    bevelbox('Pack closing strap',(x,.265,1.224),(.023,.01,.133),leather,.004)
    bevelbox('Pack brass buckle',(x,.273,1.20),(.031,.009,.028),brass,.003)
    bevelbox('Pack buckle center',(x,.279,1.20),(.020,.006,.017),leather,.001)

  roll=loft('Rolled wool bedroll',[(-.15,.064,.064,0),(-.145,.07,.07,0),(.145,.07,.07,0),(.15,.064,.064,0)],sage)
  roll.rotation_euler.y=math.pi/2;roll.location=(0,.19,1.40)
  for x in [-.08,.08]:cord('Bedroll straps',[(x,.13,1.4),(x,.17,1.46),(x,.25,1.4),(x,.19,1.34)],.006,leather)
 if kind==0:
  quiver=loft('Leather quiver',[(1.05,.055,.055,.16),(1.075,.054,.054,.16),(1.43,.059,.057,.16),(1.44,.063,.061,.16)],leather,center=(.10,0,0))
  for i in range(5):
   x=.08+(i%3)*.019;y=.15+(i//3)*.020
   cord('Arrow shaft',[(x,y,1.21),(x,y,1.64)],.0023,leather_edge)
   for side in [-1,1]:mesh('Arrow fletching',[(x,y,1.58),(x+side*.011,y,1.625),(x,y,1.64)],[(0,1,2)],thread)
  tube('Stowed wooden bow',[(-.16,.15,1.69),(-.215,.21,1.47),(-.19,.26,1.25),(-.16,.22,1.02),(-.10,.16,.91)],[.004,.011,.013,.010,.003],leather_edge,.7)
  cord('Bow string',[(-.16,.15,1.69),(-.10,.16,.91)],.0011,thread)

def configure_boar(kind):
 global fur,fur_light,fur_dark,nosemat,earinner
 colors=[(.225,.092,.032),(.52,.39,.23),(.13,.10,.067)][kind]
 fur=mat(ANIMAL_NAMES[kind]+' coat',colors,.92,.18)
 fur_light=mat(ANIMAL_NAMES[kind]+' guard hairs',tuple(c*1.5 for c in colors),.92)
 fur_dark=mat(ANIMAL_NAMES[kind]+' mane',(.047,.028,.015) if kind==0 else (.027,.025,.020),.93)
 no=(.26,.12,.08) if kind==1 else (.095,.049,.027)
 nosemat=mat(ANIMAL_NAMES[kind]+' nose',no,.57,.18);earinner=mat(ANIMAL_NAMES[kind]+' inner ear',no,.92)
 if kind==1:
  nodes=fur.node_tree.nodes;links=fur.node_tree.links;p=nodes.get('Principled BSDF');tex=nodes.new('ShaderNodeTexNoise');tex.inputs['Scale'].default_value=5;tex.inputs['Detail'].default_value=1.2
  ramp=nodes.new('ShaderNodeValToRGB');ramp.color_ramp.elements[0].position=.42;ramp.color_ramp.elements[0].color=(.10,.056,.029,1);ramp.color_ramp.elements[1].position=.52;ramp.color_ramp.elements[1].color=(*colors,1)
  links.new(tex.outputs['Fac'],ramp.inputs[0]);links.new(ramp.outputs[0],p.inputs['Base Color'])

def deer():
 root=group('MEADOW BUCK — authored study')
 coat=mat('Buck warm tawny coat',(.31,.17,.063),.91,.13);cream_deer=mat('Buck cream throat',(.62,.55,.37),.94,.1);antler=mat('Antler warm horn',(.31,.22,.11),.8,.12)
 parts=[ell('Deer barrel',(0,.08,.84),(.205,.44,.22),coat),ell('Deer haunch',(0,.35,.84),(.19,.22,.22),coat),ell('Deer shoulder',(0,-.23,.88),(.172,.21,.245),coat),ell('Neck base',(0,-.34,1.10),(.13,.16,.27),coat),ell('Upper neck',(0,-.47,1.33),(.088,.112,.23),coat),ell('Deer head',(0,-.59,1.51),(.111,.18,.115),coat),ell('Deer muzzle',(0,-.745,1.46),(.072,.137,.072),coat)]
 if CYCLE>=4:
  for old in parts[3:5]:bpy.data.objects.remove(old,do_unlink=True)
  parts=parts[:3]+parts[5:]
  parts.append(tube('Tapered deer neck',[(0,-.30,.95),(0,-.42,1.18),(0,-.51,1.41),(0,-.59,1.48)],[.13,.105,.077,.07],coat,1))
 body=fuse('Continuous buck anatomy',parts,coat,.006)
 if CYCLE>=3:
  # Interpolated vertex mask gives the throat a soft continuous boundary.
  mask=body.data.attributes.new('throat_blend','FLOAT','POINT')
  def smooth(a,b,x):
   t=max(0,min(1,(x-a)/(b-a)));return t*t*(3-2*t)
  samples=[(body.matrix_local@v.co,v.normal.copy()) for v in body.data.vertices]
  weights=[smooth(.99,1.08,pt.z)*(1-smooth(1.37,1.45,pt.z))*(1-smooth(.033,.073,abs(pt.x)))*smooth(.55,.83,-normal.y) for pt,normal in samples]
  mask.data.foreach_set('value',weights)
  nodes=coat.node_tree.nodes;links=coat.node_tree.links
  attribute=nodes.new('ShaderNodeAttribute');attribute.attribute_name='throat_blend'
  mix=nodes.new('ShaderNodeMixRGB');mix.inputs[1].default_value=(.31,.17,.063,1);mix.inputs[2].default_value=(.62,.55,.37,1)
  links.new(attribute.outputs['Fac'],mix.inputs[0]);links.new(mix.outputs[0],nodes.get('Principled BSDF').inputs['Base Color'])
 elif CYCLE>=2:
  body.data.materials.append(cream_deer)
  for poly in body.data.polygons:
   pt=body.matrix_local@poly.center
   if 1.02<pt.z<1.41 and poly.normal.y<-.65:poly.material_index=1
 for side in [-1,1]:
  for rear in [False,True]:
   x=side*.13;y=.34 if rear else -.24
   pts=[(x,y,.89),(x,y-(.055 if rear else 0),.57),(x,y+(.08 if rear else .016),.32),(x,y+(.075 if rear else .02),.080 if CYCLE>=2 else .105)]
   tube('Long deer leg',pts,[.061,.043,.025,.018],coat,.85)
   ell('Deer knee',(x,pts[2][1],.34),(.027,.034,.034),coat)
   for split in [-1,1]:bevelbox('Deer cloven hoof',(x+split*.014,pts[-1][1]-.014,.059),(.026,.062,.077),hoofmat,.009)
  ell('Deer eye',(side*.096,-.664,1.548),(.024,.021,.024),pupil)
  tube('Leaf-shaped deer ear',[(side*.074,-.49,1.574),(side*.196,-.44,1.666),(side*.246,-.435,1.73)],[.029,.057,.0005],coat,.34)
  tube('Pale inner deer ear',[(side*.096,-.515,1.60),(side*.192,-.468,1.665),(side*.229,-.458,1.708)],[.01,.033,.0005],cream_deer,.13)
  points=[(side*.063,-.503,1.60),(side*.096,-.49,1.76),(side*.19,-.44,1.92),(side*.24,-.38,2.07)]
  tube('Antler main beam',points,[.016,.014,.01,.0005],antler,1)
  tube('Antler brow tine',[points[1],(side*.12,-.62,1.85),(side*.145,-.67,1.93)],[.01,.006,.0005],antler,1)
  tube('Antler outer tine',[points[2],(side*.31,-.42,1.98),(side*.35,-.40,2.065)],[.009,.005,.0005],antler,1)
 ell('Deer soft nose',(0,-.858,1.463),(.062,.034,.044),nosemat)
 ell('Cream lower muzzle',(0,-.786,1.424),(.065,.080,.025),cream_deer)
 if CYCLE<2:tube('Cream throat patch',[(0,-.554,1.37),(0,-.494,1.235),(0,-.444,1.07)],[.036,.052,.018],cream_deer,.22)
 tube('Deer tail',[(0,.495,.88),(0,.60,.94),(0,.62,.87)],[.026,.052,.009],cream_deer,.6)
 root.location.x=2.10;root.rotation_euler.z=-.18
 return root

heroes=[];animals=[]
for kind in range(4):
 configure_hero(kind);heroes.append(scout(kind));print('BUILT',HERO_NAMES[kind],flush=True)
for kind in range(3):
 configure_boar(kind);animals.append(boar(kind));print('BUILT',ANIMAL_NAMES[kind],flush=True)
animals.append(deer());print('BUILT MEADOW BUCK',flush=True)
for o in animals:o.location.y=2.5
if CYCLE>=2:
 bpy.context.view_layer.update()
 for root in heroes+animals:
  members=[o for o in root.users_collection[0].objects if o.type=='MESH']
  low=min((o.matrix_world@Vector(corner)).z for o in members for corner in o.bound_box)
  root.location.z-=low

# Packed original references remain available in this authored source file.
refs=bpy.data.collections.new('APPROVED REFERENCES');scene.collection.children.link(refs)
for name in ['willow-scout-turnaround.png','first-wildlife-concepts.png','approved-character-options.png']:
 im=bpy.data.images.load(str(R/'docs/art'/name));im.pack()
 ob=bpy.data.objects.new(name,None);ob.empty_display_type='IMAGE';ob.data=im;ob.empty_display_size=3;ob.location=(0,3,1.5);ob.rotation_euler=(math.pi/2,0,0);refs.objects.link(ob)
refs.hide_viewport=True;refs.hide_render=True
# A consistent studio is used for every review pass.
group('STUDIO — never export')
bpy.ops.mesh.primitive_plane_add(size=200,location=(0,0,0 if CYCLE>=2 else -.015));own(bpy.context.object,'Review floor',mat('Warm gray studio',(.30,.28,.24),.92))
for name,loc,power,size in [('Key',(-3,-4,6),550,4),('Fill',(4,-3,3),250,4),('Rim',(1,3,5),650,3)]:
 d=bpy.data.lights.new(name,'AREA');d.energy=power;d.shape='DISK';d.size=size;o=bpy.data.objects.new(name,d);GROUP.objects.link(o);o.location=loc;o.rotation_euler=(Vector((0,0,.9))-o.location).to_track_quat('-Z','Y').to_euler()
d=bpy.data.cameras.new('Review camera');cam=bpy.data.objects.new('Review camera',d);GROUP.objects.link(cam);scene.camera=cam;d.type='ORTHO'

def view(target,offset,scale,file):
 cam.location=Vector(target)+Vector(offset);cam.rotation_euler=(Vector(target)-cam.location).to_track_quat('-Z','Y').to_euler();d.ortho_scale=scale
 scene.render.filepath=str(OUT/file);bpy.ops.render.render(write_still=True)

scene.render.resolution_x=2400;scene.render.resolution_y=1050
for name in ANIMAL_NAMES:bpy.data.collections[name+' — authored study'].hide_render=True
view((0,0,.94),(0,-8,1.00),5.8,'travelers.png')
for name in ANIMAL_NAMES:bpy.data.collections[name+' — authored study'].hide_render=False
for name in HERO_NAMES:bpy.data.collections[name+' — authored study'].hide_render=True
view((0,2.40,1.0),(0,-8,1.9),6.3,'wildlife.png')
for name in ANIMAL_NAMES:bpy.data.collections[name+' — authored study'].hide_render=True
bpy.data.collections['WILLOW SCOUT — authored study'].hide_render=False
scene.render.resolution_x=1000;scene.render.resolution_y=1000
view((-1.8,-.015,1.655),(.65,-4,.24),.55,'scout-face.png')
if CYCLE>=3:
 scene.render.resolution_x=2400;scene.render.resolution_y=1050
 for name in HERO_NAMES:bpy.data.collections[name+' — authored study'].hide_render=False
 view((0,0,.96),(.4,8,1.3),5.8,'travelers-rear.png')
 for name in HERO_NAMES:bpy.data.collections[name+' — authored study'].hide_render=True
 for name in ANIMAL_NAMES:bpy.data.collections[name+' — authored study'].hide_render=False
 # Turn each creature within its own place so all side profiles remain separate.
 saved_x=[root.location.x for root in animals]
 for i,root in enumerate(animals):
  root.rotation_euler.z=math.pi/2
  if CYCLE>=4:root.location.x=[-3.5,-1.2,1.1,3.5][i]
 if CYCLE>=4:scene.render.resolution_x=3600;scene.render.resolution_y=1000
 view((0,2.4,1.0),(0,-8,1.2),10 if CYCLE>=4 else 6.3,'wildlife-side.png')
 for i,root in enumerate(animals):root.rotation_euler.z=-.18;root.location.x=saved_x[i]
for name in HERO_NAMES+ANIMAL_NAMES:bpy.data.collections[name+' — authored study'].hide_render=False
cam.location=(4.5,-8,4.5);cam.rotation_euler=(Vector((0,1.25,1))-cam.location).to_track_quat('-Z','Y').to_euler();d.ortho_scale=7.4
for screen in bpy.data.screens:
 for area in screen.areas:
  if area.type=='VIEW_3D':
   sp=area.spaces.active;sp.shading.type='MATERIAL';sp.overlay.show_overlays=False;sp.region_3d.view_perspective='ORTHO';sp.region_3d.view_rotation=cam.rotation_euler.to_quaternion();sp.region_3d.view_location=Vector((0,1.25,.95));sp.region_3d.view_distance=7.4
bpy.ops.object.select_all(action='DESELECT')
notes=bpy.data.texts.new('REVIEW STATUS');notes.write(f'Cycle {CYCLE}: original Blender mesh and material studies. Not rigged, retopologized, or game-ready. World unchanged. References packed. Review actual renders before integration.')
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'characters.blend'),compress=True)
print('CHARACTER_CYCLE_COMPLETE',CYCLE,flush=True)
