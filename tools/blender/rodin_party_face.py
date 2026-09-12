"""Close-range face maps for each Rodin traveler.

The head skin becomes its own 'Rodin Face' material with a 1024 albedo, a tangent-space
normal map and a roughness map, packed from the head's own UV islands. Features are painted
from the same 600x900 front-view coordinates as the body atlas, so the eye, brow and mouth
landmarks stay exactly where they were measured against the sculpt.
"""
import bpy,numpy as np

S=900/2.3

def lin(h):
 c=np.array([int(h[j:j+2],16)/255 for j in (0,2,4)]);return np.where(c>.04045,((c+.055)/1.055)**2.4,c/12.92)

def smooth(t):
 t=np.clip(t,0,1);return t*t*(3-2*t)

def band(d,half,soft=.12):
 """1 within +-half of a curve (d is the signed distance), fading to 0 over `soft`."""
 return smooth((half-np.abs(d))/soft)

def mix(color,a,target):
 a=np.clip(a,0,1)[:,None];return color*(1-a)+np.asarray(target)*a

def pack_islands(me,mask,margin=.012):
 """Deterministic shelf packing of the UV islands formed by the masked polygons into the unit square.
 Blender's pack operator repacks the whole mesh from a background script, which would detach the
 body from its already baked atlas; only the head loops move here."""
 layer=me.uv_layers.active.data;uv=np.zeros(len(layer)*2,np.float32);layer.foreach_get('uv',uv);uv=uv.reshape(-1,2)
 faces=[int(f) for f in np.nonzero(mask)[0]];parent={f:f for f in faces}
 def find(a):
  while parent[a]!=a:parent[a]=parent[parent[a]];a=parent[a]
  return a
 owner={}
 for f in faces:
  p=me.polygons[f]
  for vi,li in zip(p.vertices,p.loop_indices):
   key=(vi,int(round(uv[li,0]*20000)),int(round(uv[li,1]*20000)))
   if key in owner:
    a,b=find(f),find(owner[key])
    if a!=b:parent[a]=b
   else:owner[key]=f
 groups={}
 for f in faces:groups.setdefault(find(f),[]).append(f)
 islands=[]
 for fs in groups.values():
  loops=np.array([li for f in fs for li in me.polygons[f].loop_indices]);pts=uv[loops]
  if np.ptp(pts[:,1])>np.ptp(pts[:,0]):uv[loops]=np.column_stack((pts[:,1],-pts[:,0]));pts=uv[loops]
  islands.append((loops,pts.min(0),pts.max(0)))
 sizes=np.array([mx-mn for _,mn,mx in islands]);order=np.argsort(-sizes[:,1])
 def layout(scale):
  placed={};x=y=margin;row=0.0
  for i in order:
   w,h=sizes[i]*scale
   if x+w+margin>1:x=margin;y+=row+margin;row=0.0
   if y+h+margin>1:return None
   placed[i]=(x,y);x+=w+margin;row=max(row,h)
  return placed
 lo,hi,best=0.0,1.0/max(float(sizes.max()),1e-9),None
 for _ in range(48):
  mid=(lo+hi)/2;placed=layout(mid)
  if placed:best=(mid,placed);lo=mid
  else:hi=mid
 scale,placed=best
 for i,(loops,mn,mx) in enumerate(islands):
  uv[loops]=(uv[loops]-mn)*scale+np.array(placed[i])
 layer.foreach_set('uv',uv.ravel())
 return scale,len(islands)

def rasterize(me,size,mask):
 """Per-texel positions and normals for the polygons flagged in `mask`."""
 me.calc_loop_triangles();uv=np.array([d.uv[:] for d in me.uv_layers.active.data])
 P=np.array([v.co[:] for v in me.vertices]);N=np.array([v.normal[:] for v in me.vertices])
 positions=np.zeros((size,size,3),np.float32);normals=np.zeros_like(positions);valid=np.zeros((size,size),bool)
 for tri in me.loop_triangles:
  if not mask[tri.polygon_index]:continue
  t=uv[list(tri.loops)]*size-.5;lo=np.maximum(np.floor(t.min(0)).astype(int),0);hi=np.minimum(np.ceil(t.max(0)).astype(int),size-1)
  if (hi<lo).any():continue
  xx,yy=np.meshgrid(np.arange(lo[0],hi[0]+1),np.arange(lo[1],hi[1]+1));a,b,c=t
  den=(b[1]-c[1])*(a[0]-c[0])+(c[0]-b[0])*(a[1]-c[1])
  if abs(den)<1e-9:continue
  w0=((b[1]-c[1])*(xx-c[0])+(c[0]-b[0])*(yy-c[1]))/den;w1=((c[1]-a[1])*(xx-c[0])+(a[0]-c[0])*(yy-c[1]))/den;w2=1-w0-w1
  inside=(w0>=-1e-5)&(w1>=-1e-5)&(w2>=-1e-5)
  xyz=P[list(tri.vertices)];ns=N[list(tri.vertices)]
  positions[yy[inside],xx[inside]]=(w0[...,None]*xyz[0]+w1[...,None]*xyz[1]+w2[...,None]*xyz[2])[inside]
  normals[yy[inside],xx[inside]]=(w0[...,None]*ns[0]+w1[...,None]*ns[1]+w2[...,None]*ns[2])[inside]
  valid[yy[inside],xx[inside]]=True
 return positions,normals,valid

def dilate(img,valid,steps=10):
 """Pad chart edges outward so filtering and mipmaps never sample unpainted texels."""
 img=img.copy();filled=valid.copy()
 for _ in range(steps):
  todo=~filled;acc=np.zeros_like(img);count=np.zeros(img.shape[:2],np.float32)
  for dy,dx in [(0,1),(0,-1),(1,0),(-1,0)]:
   m=np.roll(filled,(dy,dx),(0,1));acc+=np.roll(img,(dy,dx),(0,1))*m[...,None];count+=m
  new=todo&(count>0);img[new]=acc[new]/count[new,None];filled|=new
 return img

def srgb(c):
 c=np.clip(c,0,1);return np.where(c>.0031308,1.055*c**(1/2.4)-.055,c*12.92)

def save(name,size,rgb,path,colorspace):
 image=bpy.data.images.new(name,width=size,height=size,alpha=False);image.colorspace_settings.name=colorspace
 rgba=np.ones((size,size,4),np.float32);rgba[:,:,:3]=rgb;image.pixels.foreach_set(rgba.ravel())
 image.filepath_raw=str(path);image.file_format='PNG';image.save();image.pack();return image

def paint_face(P,N,k,paint,palette,eyes,mouth):
 """Return linear color, height (front-view pixels) and roughness for head-skin texels."""
 labels,color,_,names=paint(P,k,N)
 X,Y,Z=P.T;x=300+X*S;y=450-(Z-1.03)*S
 skin=labels==names.index('skin')
 front=skin&(Y<.10)&(N[:,1]<.3)
 h=np.zeros(len(P));rough=np.full(len(P),.62)
 hair=lin(palette['hair'])
 # Painted light from above: undersides of the nose, lips, chin and brow ridge darken.
 down=np.clip(-N[:,2],0,1);up=np.clip(N[:,2],0,1)
 color[skin]*=(1-.20*down[skin]**1.5+.04*up[skin])[:,None]
 # Soft mottling keeps broad skin from reading as plastic.
 mottle=np.sin(X*57+np.sin(Z*31)*2)*np.sin(Z*66+Y*40)
 color[skin]*=(1+.03*mottle[skin])[:,None]
 mx,my,mrx=mouth
 nose_tip=None
 between=front&(y>min(e[1] for e in eyes)+2)&(y<my-3)&(np.abs(x-mx)<mrx*.9)
 if between.any():
  i=np.argmin(np.where(between,Y,np.inf));nose_tip=P[i]
  d=np.linalg.norm(P-nose_tip,axis=1)
  color=mix(color,skin*.10*smooth(1-d/.02),lin('c96a58'))
  # Nostrils sit just behind and below the tip, on downward-facing skin.
  nostril=skin&(d<.024)&(Z<nose_tip[2]-.002)&(down>.35)
  color[nostril]*=(1-.30*down[nostril]**1.2)[:,None];h[nostril]-=1.2*down[nostril]**2
 # Cheeks and ears carry more blood than the forehead.
 for ex,ey,rx,ry in eyes:
  cheek=np.exp(-(((x-ex)/(1.3*rx))**2+((y-(ey+3.2*ry))/(2.2*ry))**2))
  color=mix(color,front*.12*cheek,lin('c96a58'))
 ears=skin&(np.abs(N[:,1])<.6)&(np.abs(N[:,0])>.55)&(Z>1.74)&(Z<1.90)&(Y>-.03)
 color=mix(color,ears*.12,lin('c96a58'))
 # Between the brows and the mouth the skin is a little oilier.
 tzone=front&(np.abs(x-mx)<3.5)&(y>min(e[1] for e in eyes)-8)&(y<my-2)
 rough[tzone]=.52
 for ex,ey,rx,ry in eyes:
  inner=1.0 if mx>=ex else -1.0
  u=(x-ex)/rx;v=(y-ey)/ry
  uin=np.clip((u*inner+1)/2,0,1)          # 0 at the outer corner, 1 at the inner corner
  span=np.clip(1-u*u,0,None)
  vtop=-.95*span**.8;vbot=.75*span**.9
  inside=front&(np.abs(u)<1)&(v>vtop)&(v<vbot)
  # Socket shading, slightly warm, around the whole eye.
  fall=np.exp(-((u/1.4)**2+((v+.35)/1.25)**2))
  color=mix(color,front*.11*fall,lin('8e5a47'))
  # Sclera: off-white, darker under the upper lid, warmer at the corners.
  white=lin(palette['eyes'])*.3+lin('e8e1d2')*.7
  sclera=white[None,:]*(1-.18*np.clip(1-(v-vtop)/.55,0,1))[:,None]
  corner=np.clip((np.abs(u)-.68)/.32,0,1)
  sclera=sclera*(1-.35*corner)[:,None]+lin('c9a08e')*(.35*corner)[:,None]
  color[inside]=sclera[inside]
  # Iris: limbal ring, radial fibers, brighter lower half, soft pupil.
  cx=ex+.9;cy=ey;rix=.95*ry;riy=1.05*ry
  r=np.sqrt(((x-cx)/rix)**2+((y-cy)/riy)**2);theta=np.arctan2((y-cy)/riy,(x-cx)/rix)
  iris=inside&(r<1)
  shade=(.55+.45*np.sqrt(np.clip(1-r,0,1)))*(1+.10*np.sin(theta*26+1.5*np.sin(theta*7)))*(1+.18*np.clip((y-cy)/riy,0,1))
  shade*=1-.55*smooth((r-.80)/.14)
  color[iris]=lin(palette['iris'])[None,:]*shade[iris,None]
  pupil=smooth((.46-r)/.10)
  color[iris]=color[iris]*(1-pupil[iris,None])+lin(palette['pupil'])*pupil[iris,None]
  # The upper lid shadows the eyeball.
  color[inside]*=(1-.22*np.clip(1-(v-vtop)/.45,0,1))[inside,None]
  # Catchlight and a faint secondary reflection.
  cat=smooth((1-np.sqrt(((x-(cx-.35*rix))/(.27*rix))**2+((y-(cy-.42*riy))/(.25*riy))**2))/.25)
  color=mix(color,inside*cat*.95,lin('f3eee4'))
  cat2=smooth((1-np.sqrt(((x-(cx+.40*rix))/(.14*rix))**2+((y-(cy+.42*riy))/(.13*riy))**2))/.35)
  color=mix(color,inside*cat2*.45,lin('f3eee4'))
  # Eyeball surface: glossy, with a cornea bulge in the height field.
  rough[inside]=.12
  h[inside]+=.35*np.clip(1-(u*u+(v/.85)**2),0,None)[inside]+.5*np.clip(1-r*r,0,None)[inside]
  # Upper lash line: thickest toward the outer corner, with a small outer flick.
  reach=front&(np.abs(u)<1.14)
  thick=.14+.24*(1-uin)**.7
  dtop=v-vtop-(.18*np.clip(np.abs(u)-.95,0,None)*3)
  lash=reach&(dtop>-thick-.10)&(dtop<.12)
  a=smooth((thick+.10+dtop)/.14)*smooth((.12-dtop)/.10)
  color=mix(color,lash*a*.92,hair*.55)
  h-=.6*np.where(reach,np.exp(-(dtop/.16)**2),0);rough[lash&(a>.5)]=.6
  # Lid fold above the lashes, with the lid itself catching light.
  crease=reach&(np.abs(u)<1.05)
  dcr=v-(vtop-.85)
  color=mix(color,crease*band(dcr,.14,.16)*.30,lin(palette['skin'])*.68)
  lid=crease&(v>vtop-.85)&(v<vtop)
  color[lid]*=(1.05)
  h+=np.where(crease&(dcr>0)&(v<vtop),np.sin(np.pi*np.clip((v-vtop)/-.85,0,1))*1.0,0)
  h-=.35*np.where(crease,np.exp(-(dcr/.15)**2),0)
  # Lower lash line, outer two thirds only.
  dbot=v-vbot
  lower=reach&(uin<.72)&(np.abs(u)<1.0)
  color=mix(color,lower*band(dbot-.10,.10,.10)*.42*(1-uin/.72),hair*.85)
  h+=np.where(lower&(dbot>0)&(dbot<.5),np.sin(np.pi*np.clip(dbot/.5,0,1))*.4,0)
  # Tear duct.
  duct=inside&(uin>.9)
  color=mix(color,duct*.5,lin('c07a6a'))
  # Brow: arched, thick at the inner end, tapering to a tail.
  ub=np.clip(uin,0,1)
  yb=ey-6.0+.8*u-.9*span
  half=.22+.50*ub**.8
  brow=front&(u*inner>-1.28)&(u*inner<1.05)
  a=smooth((half-np.abs(y-yb))/.22)*(.85+.15*np.sin(u*rx*2.1+v*1.3))
  color=mix(color,brow*a*.92,hair*.9)
  h+=np.where(brow,.5*np.exp(-((y-yb)/1.2)**2),0)
 # Mouth: cupid's bow, fuller lower lip with a highlight, dark parting line.
 lip_col=lin(['9a6451','81503a','563527','a56c59'][k])
 dx=(x-mx)/mrx;along=np.clip(1-dx*dx,0,None)
 yl=my-.010*(x-mx)**2
 hu=1.3*along**.7-.35*np.exp(-((x-mx)/1.5)**2)
 hl=1.9*along**.6
 near=front&(np.abs(dx)<1.06)
 upper=near&(y<yl)&(y>yl-hu)
 lower=near&(y>=yl)&(y<yl+hl)
 color=mix(color,upper*.55*smooth((y-(yl-hu))/.25),lip_col*.85)
 color=mix(color,lower*.55*smooth(((yl+hl)-y)/.3),lip_col)
 shine=lower&(np.abs(y-(yl+.45*hl))<.35)
 color[shine]*=1.12
 color=mix(color,near*band(y-yl,.28,.14)*.85,lip_col*.45)
 corners=front&(np.sqrt(((x-mx)**2)/(mrx*1.02)**2*0+((np.abs(x-mx)-mrx*1.02)**2)+(y-yl)**2)<.7)
 color[corners]*=.82
 rough[upper|lower]=.45;rough[shine]=.40
 h+=np.where(lower,np.sin(np.pi*np.clip((y-yl)/np.maximum(hl,1e-3),0,1))*1.0,0)
 h+=np.where(upper,np.sin(np.pi*np.clip((yl-y)/np.maximum(hu,1e-3),0,1))*.6,0)
 h-=.8*np.where(near,np.exp(-((y-yl)/.2)**2),0)
 philtrum=front&(np.abs(x-mx)<1.6)&(y<yl-hu)&(y>yl-4.5)
 h-=np.where(philtrum,.3*np.exp(-((x-mx)/.5)**2),0)
 return color,h,rough

def face_material(o,k,paint,palette,eyes,mouth,head_x,out,slug,size=1024,strength=2.0):
 me=o.data
 # Blender suffixes repeated names across figures ('Rodin Skin.001'); match by prefix.
 skin_slot=next(i for i,m in enumerate(me.materials) if m.name.startswith('Rodin Skin'))
 C=np.array([p.center[:] for p in me.polygons]);idx=np.array([p.material_index for p in me.polygons])
 mask=(idx==skin_slot)&(C[:,2]>1.58)&(np.abs(C[:,0]-head_x)<.24)&(C[:,1]<.22)
 mat=bpy.data.materials.new('Rodin Face');mat.use_nodes=True;mat.use_backface_culling=False;me.materials.append(mat);slot=len(me.materials)-1
 material_index=idx.copy();material_index[mask]=slot;me.polygons.foreach_set('material_index',material_index)
 # Repack only the head islands so the face owns a full map of its own.
 scale,islands=pack_islands(me,mask)
 positions,normals,valid=rasterize(me,size,mask)
 print('FACE PAINT',k,'polygons',int(mask.sum()),'islands',islands,'scale %.2f'%scale,'covered',int(valid.sum()),'of',size*size,flush=True)
 rgb=np.zeros((size,size,3),np.float32);height=np.zeros((size,size),np.float32);rough=np.full((size,size),.62,np.float32)
 ys,xs=np.nonzero(valid)
 for start in range(0,len(ys),150000):
  sy,sx=ys[start:start+150000],xs[start:start+150000]
  c,hh,rr=paint_face(positions[sy,sx],normals[sy,sx],k,paint,palette,eyes,mouth)
  rgb[sy,sx]=c;height[sy,sx]=hh;rough[sy,sx]=rr
 rgb=dilate(rgb,valid);height=dilate(height[...,None],valid)[...,0];rough=dilate(rough[...,None],valid)[...,0]
 gy,gx=np.gradient(height)
 n=np.stack([-gx*strength,-gy*strength,np.ones_like(gx)],-1);n/=np.linalg.norm(n,axis=-1,keepdims=True)
 albedo=save(slug+'_face_albedo',size,srgb(rgb),out/(slug+'_face_albedo.png'),'sRGB')
 normal=save(slug+'_face_normal',size,n*.5+.5,out/(slug+'_face_normal.png'),'Non-Color')
 roughness=save(slug+'_face_rough',size,np.repeat(rough[...,None],3,-1),out/(slug+'_face_rough.png'),'Non-Color')
 nt=mat.node_tree;p=nt.nodes.get('Principled BSDF');p.inputs['Roughness'].default_value=.62
 ta=nt.nodes.new('ShaderNodeTexImage');ta.image=albedo;nt.links.new(ta.outputs['Color'],p.inputs['Base Color'])
 tr=nt.nodes.new('ShaderNodeTexImage');tr.image=roughness;nt.links.new(tr.outputs['Color'],p.inputs['Roughness'])
 tn=nt.nodes.new('ShaderNodeTexImage');tn.image=normal;nm=nt.nodes.new('ShaderNodeNormalMap');nm.inputs['Strength'].default_value=1.0
 nt.links.new(tn.outputs['Color'],nm.inputs['Color']);nt.links.new(nm.outputs['Normal'],p.inputs['Normal'])
 return dict(face_polygons=int(mask.sum()),face_islands=islands,face_texels=int(valid.sum()),face_map=size)
