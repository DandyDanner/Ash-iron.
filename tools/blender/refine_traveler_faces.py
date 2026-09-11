"""Refine traveler facial surfaces in a saved Blender study; preserve all other art.
Run with Blender --background --python this_file -- --art-pass=5 [--refinement=2].
The source is cycle_04, whose approved progress remains untouched.
"""
from pathlib import Path
import bpy, bmesh, math, random, sys, json
from mathutils import Vector
R=Path(__file__).resolve().parents[2]
PASS=int(next((a.split('=')[1] for a in sys.argv if a.startswith('--art-pass=')),'5'))
REFINE=int(next((a.split('=')[1] for a in sys.argv if a.startswith('--refinement=')),'1'))
OUT=R/'art/blender/cycles'/f'cycle_{PASS:02d}'
OUT.mkdir(parents=True,exist_ok=True)
if (OUT/'characters.blend').exists():raise RuntimeError('Preserve saved pass; choose another number')
bpy.ops.wm.open_mainfile(filepath=str(R/'art/blender/cycles/cycle_04/characters.blend'))
scene=bpy.context.scene;scene.cycles.samples=32
NAMES=['WILLOW SCOUT','HEARTHLAND RANGER','RIDGE WAYFARER','EMBER FORAGER']
ANIMALS=['BRISTLEBACK BOAR','WOODLAND HOG','RIDGEBACK BOAR','MEADOW BUCK']
col=None;root=None

def material(name,color,rough=.55):
 m=bpy.data.materials.new(name);m.diffuse_color=(*color,1);m.use_nodes=True
 p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*color,1);p.inputs['Roughness'].default_value=rough;p.inputs['Specular IOR Level'].default_value=.3
 return m

def mesh(name,verts,faces,mat,sub=0):
 d=bpy.data.meshes.new(name);d.from_pydata(verts,[],faces);d.update()
 bm=bmesh.new();bm.from_mesh(d);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(d);bm.free()
 o=bpy.data.objects.new(name,d);col.objects.link(o);o.parent=root;d.materials.append(mat)
 for p in d.polygons:p.use_smooth=True
 if sub:
  mod=o.modifiers.new('Continuous facial surface','SUBSURF');mod.levels=sub
 return o

def curve(name,points,radius,mat):
 d=bpy.data.curves.new(name,'CURVE');d.dimensions='3D';d.resolution_u=12;d.bevel_depth=radius;d.bevel_resolution=3
 sp=d.splines.new('BEZIER');sp.bezier_points.add(len(points)-1)
 for p,co in zip(sp.bezier_points,points):p.co=co;p.handle_left_type='AUTO';p.handle_right_type='AUTO'
 o=bpy.data.objects.new(name,d);col.objects.link(o);o.parent=root;d.materials.append(mat)
 return o

def gauss(x,z,cx,cz,sx,sz):return math.exp(-((x-cx)/sx)**2-((z-cz)/sz)**2)

def interp(z,rings,idx):
 for i in range(len(rings)-1):
  if z<=rings[i+1][0]:
   t=max(0,(z-rings[i][0])/(rings[i+1][0]-rings[i][0]));a=rings[max(i-1,0)][idx];b=rings[i][idx];c=rings[i+1][idx];d=rings[min(i+2,len(rings)-1)][idx]
   if REFINE<2:return .5*(2*b+(c-a)*t+(2*a-5*b+4*c-d)*t*t+(-a+3*b-3*c+d)*t*t*t)
   left=max(i-1,0);right=min(i+2,len(rings)-1);span=rings[i+1][0]-rings[i][0]
   m0=(c-a)/(rings[i+1][0]-rings[left][0]);m1=(d-b)/(rings[right][0]-rings[i][0])
   return (2*t**3-3*t*t+1)*b+(t**3-2*t*t+t)*span*m0+(-2*t**3+3*t*t)*c+(t**3-t*t)*span*m1
 return rings[-1][idx]

for kind,name in enumerate(NAMES):
 col=bpy.data.collections[name+' — authored study'];root=next(o for o in col.objects if o.type=='EMPTY')
 remove=['Continuous face and nose sculpt','Ear','Eye','Iris','Pupil','Upper eyelid','Upper lash line','Lower eyelid','Shaped eyebrow','Nostril','Mouth line','Lower lip','Freckle','Short ranger beard']
 for ob in list(col.objects):
  if any(ob.name==p or ob.name.startswith(p+'.') or (p=='Ear' and ob.name.startswith('Ear hollow')) for p in remove):bpy.data.objects.remove(ob,do_unlink=True)
 colors=[(.48,.285,.16),(.45,.24,.12),(.19,.088,.040),(.62,.37,.21)]
 skin=material(name+' refined skin',colors[kind]);skin.node_tree.nodes.get('Principled BSDF').inputs['Subsurface Weight'].default_value=.065
 plain_skin=skin if REFINE<2 else material(name+' ear and eyelid skin',colors[kind])
 lipcolor=tuple(a*.78+b*.22 for a,b in zip(colors[kind],(.42,.11,.085)))
 lipmat=material(name+' natural lip',lipcolor,.6);shadow=material(name+' crease shadow',tuple(c*.35 for c in lipcolor),.85)
 hair=bpy.data.materials[name+' hair']
 # Shorter lower face, independent jaw width and mid-face volume per design.
 jaw=([.060,.071,.078,.059] if REFINE>=2 else [.052,.069,.077,.052])[kind];cheek=[.092,.096,.100,.094][kind]
 rings=[(1.529,.018,.028,-.008),(1.541,.041,.050,-.008),(1.558,jaw,.061,-.003),(1.598,.080 if kind in [0,3] else .089,.077,.001),(1.636,cheek,.084,.004),(1.680,.097,.088,.005),(1.721,.096,.087,.009),(1.752,.075,.070,.010),(1.779,.01,.017,.010)]
 def face_y(x,z):
  width=max(.012,interp(z,rings,1));depth=interp(z,rings,2);cy=interp(z,rings,3)
  y=cy-depth*math.sqrt(max(0,1-(x/width)**2))
  # Continuous sculpted nose bridge, tip and alar wings; no spherical nose pieces.
  y-=[.014,.020,.019,.013][kind]*gauss(x,z,0,1.661,.014,.037)
  y-=[.020,.024,.025,.019][kind]*gauss(x,z,0,1.641,.019,.012)
  for side in [-1,1]:
   y-=.006*gauss(x,z,side*.015,1.636,.010,.008)
   y-=.0045*gauss(x,z,side*.060,1.644,.025,.021)
   y+=.003*gauss(x,z,side*.042,1.678,.029,.016)
   y-=.004*gauss(x,z,side*.041,1.703,.029,.010)
  y-=.005*gauss(x,z,0,1.600,.036,.013)
  y-=(.0008 if REFINE>=2 else .003)*gauss(x,z,0,1.556,.027,.016)
  return y
 verts=[];faces=[];nz=104;na=160
 for iz in range(nz+1):
  z=1.529+(1.779-1.529)*iz/nz;w=interp(z,rings,1);d=interp(z,rings,2);cy=interp(z,rings,3)
  for ia in range(na):
   a=ia/na*math.tau;x=w*math.sin(a)
   y=face_y(x,z) if math.cos(a)>0 else cy-d*math.cos(a)
   verts.append((x,y,z))
 for iz in range(nz):
  for ia in range(na):a=iz*na+ia;b=iz*na+(ia+1)%na;faces.append((a,b,b+na,a+na))
 faces += [tuple(range(na-1,-1,-1)),tuple(nz*na+i for i in range(na))]
 head=mesh(name+' continuous facial planes',verts,faces,skin,1)
 # Mild warm cheek tint embedded in a vertex attribute, with no separate cheek pieces.
 attr=head.data.color_attributes.new(name='Face warmth',type='FLOAT_COLOR',domain='POINT')
 for (x,y,z),v in zip(verts,attr.data):
  warmth=max(gauss(x,z,-.058,1.643,.025,.023),gauss(x,z,.058,1.643,.025,.023))*(1 if y<0 else 0)*.14
  v.color=(*tuple(c*(1-warmth)+warmth*t for c,t in zip(colors[kind],(.55,.17,.11))),1)
 nd=skin.node_tree.nodes;lk=skin.node_tree.links;a=nd.new('ShaderNodeVertexColor');a.layer_name='Face warmth';lk.new(a.outputs['Color'],nd.get('Principled BSDF').inputs['Base Color'])
 # The visible sclera is an almond-shaped surface fitted inside the facial planes.
 # Its boundary meets the eyelid rim, eliminating the old protruding white eyeballs.
 for side in [-1,1]:
  cx=side*.042;cz=1.678;halfwidth=.027;upper=([.013,.011,.0115,.0135] if REFINE>=2 else [.011,.0095,.010,.0115])[kind];lower=.009 if REFINE>=2 else .008
  def eye_co(u,v):
   x=cx+side*u*halfwidth;mid=cz+.0025*u
   amp=max(0,1-u*u)**.78
   z=mid+(upper if v>=0 else lower)*amp*v
   y=face_y(x,z)-.0015-.004*(1-u*u)*(1-v*v)
   return x,y,z
  ev=[];ef=[];coord=[];nu=60;nv=24
  for j in range(nv+1):
   for i in range(nu+1):
    u=-1+2*i/nu;v=-1+2*j/nv;pt=eye_co(u,v);ev.append(pt);coord.append(((pt[0]-cx)/(.013 if REFINE>=2 else .0105),(pt[2]-cz)/(.013 if REFINE>=2 else .0105),0))
  for j in range(nv):
   for i in range(nu):a=j*(nu+1)+i;ef.append((a,a+1,a+nu+2,a+nu+1))
  eye=material(name+' iris and sclera '+str(side),(.75,.70,.58),.25)
  nd=eye.node_tree.nodes;lk=eye.node_tree.links;at=nd.new('ShaderNodeAttribute');at.attribute_name='Eye radial coordinate';dist=nd.new('ShaderNodeVectorMath');dist.operation='LENGTH';lk.new(at.outputs['Vector'],dist.inputs[0]);ramp=nd.new('ShaderNodeValToRGB')
  stops=[(0,(.007,.005,.003,1)),(.40,(.007,.005,.003,1)),(.47,(.18,.075,.013,1)),(.77,(.24,.112,.023,1)),(.90,(.045,.026,.01,1)),(.98,(.048,.032,.02,1)),(1,(.74,.70,.58,1))]
  cr=ramp.color_ramp;cr.elements.remove(cr.elements[1]);cr.elements[0].position=0;cr.elements[0].color=stops[0][1]
  for pos,c in stops[1:]:el=cr.elements.new(pos);el.color=c
  lk.new(dist.outputs['Value'],ramp.inputs[0]);lk.new(ramp.outputs['Color'],nd.get('Principled BSDF').inputs['Base Color'])
  ob=mesh(name+' fitted almond eye '+str(side),ev,ef,eye,0);att=ob.data.attributes.new('Eye radial coordinate','FLOAT_VECTOR','POINT');att.data.foreach_set('vector',[q for pt in coord for q in pt])
  for top in [True,False]:
   pts=[eye_co(-1+2*j/24,1 if top else -1) for j in range(25)]
   curve(name+' fine upper eyelid' if top else name+' fine lower eyelid',[(x,y-.0003,z) for x,y,z in pts],.00115 if top else .0007,plain_skin)
   if top:curve(name+' lash edge',[(x,y-.001,z-.00035) for x,y,z in pts],.00065,hair)
  # Brows are tapered ribbons resting on the brow ridge.
  bv=[];bf=[]
  for i in range(21):
   t=i/20;x=side*(.017+t*.055);z=1.704+.004*math.sin(math.pi*t)-.006*t;thick=(.0029 if kind in [1,2] else .0021)*math.sin(math.pi*t)**.5
   for dz in [-thick,thick]:bv.append((x,face_y(x,z+dz)-.001,z+dz))
  for i in range(20):bf.append((2*i,2*i+1,2*i+3,2*i+2))
  mesh(name+' resting eyebrow',bv,bf,hair,1)
  nx=side*.010;nz0=1.633
  curve(name+' underside nostril',[(nx+side*.004,face_y(nx+side*.004,nz0)-.0005,nz0),(nx,face_y(nx,nz0)-.001,nz0-.001),(nx-side*.003,face_y(nx-side*.003,nz0)-.0006,nz0)],.0010,shadow)
  # Shallow folded ear surface with a defined helix and concha.
  earverts=[];earfaces=[];nr=10;nt=40
  for j in range(nr+1):
   r=j/nr
   for i in range(nt):
    a=i/nt*math.tau;x=side*(.101+math.cos(a)*.016*r);z=1.656+math.sin(a)*.028*r;y=.002-.009*math.sin(math.pi*r)+.003*r
    earverts.append((x,y,z))
  for j in range(nr):
   for i in range(nt):a=j*nt+i;b=j*nt+(i+1)%nt;earfaces.append((a,b,b+nt,a+nt))
  mesh(name+' folded ear',earverts,earfaces,plain_skin,1)
  pts=[(side*(.101+math.cos(a)*.014),-.001,1.656+math.sin(a)*.025) for a in [i/24*math.tau for i in range(25)]]
  curve(name+' ear helix',pts,.0023,plain_skin)
 # Upper cupid bow and lower lip are broad curved surfaces, not a pasted smile cord.
 mouthwidth=[.027,.031,.031,.028][kind];mz=1.601
 def mouthline(u):return mz+.003*u*u
 for upperlip in [True,False]:
  lv=[];lf=[]
  for j in range(9):
   v=j/8
   for i in range(49):
    u=-1+2*i/48;x=u*mouthwidth;line=mouthline(u)
    h=(.0048*(1-.36*math.exp(-(u/.22)**2)) if upperlip else -.0052)*(1-u*u)
    z=line+h*v;y=face_y(x,z)-.0008-.0028*math.sin(math.pi*v)*(1-u*u)
    lv.append((x,y,z))
  for j in range(8):
   for i in range(48):a=j*49+i;lf.append((a,a+1,a+50,a+49))
  mesh(name+' shaped upper lip' if upperlip else name+' shaped lower lip',lv,lf,lipmat,1)
 pts=[]
 for i in range(25):
  u=-1+2*i/24;x=u*mouthwidth;z=mouthline(u);pts.append((x,face_y(x,z)-.0011,z))
 curve(name+' fine mouth separation',pts,.00055,shadow)
 if kind==3:
  random.seed(441)
  for i in range(34):
   x=random.choice([-1,1])*random.uniform(.032,.071);z=random.uniform(1.641,1.654)
   r=random.uniform(.0005,.0009);mesh('Surface freckle',[(x+math.cos(a)*r,face_y(x,z)-.0007,z+math.sin(a)*r) for a in [j/8*math.tau for j in range(8)]],[tuple(range(8))],lipmat)
 if kind==1:
  random.seed(441)
  for i in range(520):
   x=random.uniform(-.077,.077);z=random.uniform(1.549,1.625)
   if abs(x)<.034 and z>1.587:continue
   width=interp(z,rings,1)
   if abs(x)>.92*width:continue
   y=face_y(x,z)
   curve('Surface-following ranger beard',[(x,y-.0007,z),(x+.001,y-.001,z-.0025)],.00028,hair)
 print('REFINED_FACE',name,flush=True)

# Render the actual saved geometry in unchanged studio lighting.
cam=scene.camera
for name in ANIMALS:bpy.data.collections[name+' — authored study'].hide_render=True

def render(target,offset,scale,file,w=1200,h=1200):
 cam.location=Vector(target)+Vector(offset);cam.rotation_euler=(Vector(target)-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.ortho_scale=scale
 scene.render.resolution_x=w;scene.render.resolution_y=h;scene.render.filepath=str(OUT/file);bpy.ops.render.render(write_still=True)

for name in NAMES:bpy.data.collections[name+' — authored study'].hide_render=False
render((0,0,.94),(0,-8,1),5.8,'travelers.png',2400,1050)
for name in NAMES:bpy.data.collections[name+' — authored study'].hide_render=True
for kind,name in enumerate(NAMES):
 col=bpy.data.collections[name+' — authored study'];col.hide_render=False;root=next(o for o in col.objects if o.type=='EMPTY');target=root.matrix_world@Vector((0,-.015,1.66))
 render(target,(.55,-4,.10),.36,['scout-face.png','ranger-face.png','wayfarer-face.png','forager-face.png'][kind],1000,1000)
 col.hide_render=True
bpy.data.collections[NAMES[0]+' — authored study'].hide_render=False
render((-1.8,0,1.66),(4,-.9,.15),.38,'scout-profile.png',1000,1000)
for name in NAMES+ANIMALS:bpy.data.collections[name+' — authored study'].hide_render=False
cam.location=(4.5,-8,4.5);cam.rotation_euler=(Vector((0,1.25,1))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.ortho_scale=7.4
notes=bpy.data.texts.get('REVIEW STATUS');notes.clear();notes.write(f'Cycle {PASS}: continuous face planes and fitted almond eyes, differentiated jaws, shaped lips and folded ears. Source cycle_04 preserved; outfits/hair/animals unchanged. Unrigged offline art studies. Inspect actual renders before approval.')
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'characters.blend'),compress=True)
print('FACE_PASS_COMPLETE',PASS,flush=True)
