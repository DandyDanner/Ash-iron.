"""Rasterize authored 3D surface paint into a portable UV albedo, without baked lighting."""
import bpy,numpy as np,math
from mathutils import Vector

def texture(obj,paint,k,path,size=2048):
 me=obj.data
 bpy.context.view_layer.objects.active=obj
 if not me.uv_layers:
  bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT');bpy.ops.uv.smart_project(angle_limit=math.radians(66),island_margin=.012);bpy.ops.object.mode_set(mode='OBJECT')
 # Repack this figure's UVs; the source atlas also held seven other figures.
 bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT');bpy.ops.uv.select_all(action='SELECT');bpy.ops.uv.pack_islands(rotate=True,margin=.006);bpy.ops.object.mode_set(mode='OBJECT')
 me.calc_loop_triangles();uv=np.array([d.uv[:] for d in me.uv_layers.active.data]);P=np.array([v.co[:] for v in me.vertices]);N=np.array([v.normal[:] for v in me.vertices])
 positions=np.zeros((size,size,3),np.float32);normals=np.zeros_like(positions);valid=np.zeros((size,size),bool)
 for tri in me.loop_triangles:
  t=uv[list(tri.loops)]*size-.5;lo=np.maximum(np.floor(t.min(0)).astype(int),0);hi=np.minimum(np.ceil(t.max(0)).astype(int),size-1)
  if (hi<lo).any():continue
  xx,yy=np.meshgrid(np.arange(lo[0],hi[0]+1),np.arange(lo[1],hi[1]+1));a,b,c=t
  den=(b[1]-c[1])*(a[0]-c[0])+(c[0]-b[0])*(a[1]-c[1])
  if abs(den)<1e-9:continue
  w0=((b[1]-c[1])*(xx-c[0])+(c[0]-b[0])*(yy-c[1]))/den;w1=((c[1]-a[1])*(xx-c[0])+(a[0]-c[0])*(yy-c[1]))/den;w2=1-w0-w1
  inside=(w0>=-1e-5)&(w1>=-1e-5)&(w2>=-1e-5)
  xyz=P[list(tri.vertices)];pos=w0[...,None]*xyz[0]+w1[...,None]*xyz[1]+w2[...,None]*xyz[2]
  ns=N[list(tri.vertices)];normal=w0[...,None]*ns[0]+w1[...,None]*ns[1]+w2[...,None]*ns[2]
  normals[yy[inside],xx[inside]]=normal[inside]
  positions[yy[inside],xx[inside]]=pos[inside];valid[yy[inside],xx[inside]]=True
 print('UV PAINT',k,'covered',int(valid.sum()),'of',size*size,flush=True)
 rgba=np.zeros((size,size,4),np.float32);rgba[:,:,3]=1
 # Bound memory while applying the editable surface selections.
 ys,xs=np.nonzero(valid)
 for start in range(0,len(ys),150000):
  sy,sx=ys[start:start+150000],xs[start:start+150000];_,colors,_,_=paint(positions[sy,sx],k,normals[sy,sx]);rgba[sy,sx,:3]=colors
 # Eight pixels of chart padding prevent dark UV edges at distance.
 filled=valid.copy()
 for _ in range(10):
  todo=~filled;acc=np.zeros((size,size,3),np.float32);count=np.zeros((size,size),np.float32)
  for dy,dx in [(0,1),(0,-1),(1,0),(-1,0)]:
   mask=np.roll(filled,(dy,dx),(0,1));acc+=np.roll(rgba[:,:,:3],(dy,dx),(0,1))*mask[:,:,None];count+=mask
  new=todo&(count>0);rgba[new,:3]=acc[new]/count[new,None];filled|=new
 # Generated image pixel storage is encoded sRGB; the paint function uses linear color.
 rgba[:,:,:3]=np.where(rgba[:,:,:3]>.0031308,1.055*np.maximum(rgba[:,:,:3],0)**(1/2.4)-.055,rgba[:,:,:3]*12.92)
 image=bpy.data.images.new(path.stem,width=size,height=size,alpha=False);image.colorspace_settings.name='sRGB';image.pixels.foreach_set(rgba.ravel());image.filepath_raw=str(path);image.file_format='PNG';image.save();image.pack()
 for mat in me.materials:
  nt=mat.node_tree;p=nt.nodes.get('Principled BSDF');tex=nt.nodes.new('ShaderNodeTexImage');tex.image=image;nt.links.new(tex.outputs['Color'],p.inputs['Base Color'])
 # COLOR_0 stays enabled in Godot; white avoids multiplying the albedo twice.
 for attr in me.color_attributes:
  if attr.name=='GameColor':attr.data.foreach_set('color',np.ones(len(attr.data)*4,dtype=np.float32))
 return image
