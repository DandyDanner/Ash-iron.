"""Prepare Dallon's supplied backpack as a reusable Godot asset, preserving the download.
Blender --background --factory-startup --python this_file -- /absolute/path/to/source.glb
The asset is not yet attached to a playable traveler.
"""
import bpy,bmesh,json,sys,hashlib
from pathlib import Path
from mathutils import Vector
R=Path(__file__).resolve().parents[2]
SOURCE=Path(sys.argv[sys.argv.index('--')+1]) if '--' in sys.argv else Path('/Users/dallonanderson/Downloads/Meshy_AI_Vintage_Leather_Backp_0911235900_texture.glb')
OUT=R/'assets/equipment';OUT.mkdir(parents=True,exist_ok=True)
REVIEW=R/'docs/art/leather-backpack';REVIEW.mkdir(parents=True,exist_ok=True);(REVIEW/'.gdignore').touch()
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
bpy.ops.import_scene.gltf(filepath=str(SOURCE));obj=next(o for o in bpy.context.scene.objects if o.type=='MESH');obj.name='LeatherBackpack'
original_triangles=sum(len(p.vertices)-2 for p in obj.data.polygons)
# Weld duplicated UV-boundary vertices without removing their per-loop UV coordinates.
bm=bmesh.new();bm.from_mesh(obj.data);bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=.000001);bm.to_mesh(obj.data);bm.free()
bpy.context.view_layer.objects.active=obj
mod=obj.modifiers.new('Equipment triangle budget','DECIMATE');mod.ratio=20000/len(obj.data.polygons);bpy.ops.object.modifier_apply(modifier=mod.name)
lo=Vector([min(v.co[i] for v in obj.data.vertices) for i in range(3)]);hi=Vector([max(v.co[i] for v in obj.data.vertices) for i in range(3)])
center=Vector(((lo.x+hi.x)*.5,(lo.y+hi.y)*.5,lo.z));factor=.60/(hi.z-lo.z)
for v in obj.data.vertices:v.co=(v.co-center)*factor
for p in obj.data.polygons:p.use_smooth=True
for mat in obj.data.materials:
 mat.name='Worn leather and brass'
 for node in mat.node_tree.nodes:
  if node.type=='TEX_IMAGE' and node.image:
   im=node.image
   if max(im.size)>2048:im.scale(2048,2048)
   im.pack()
obj.data.validate(clean_customdata=False);obj.data.update()
bpy.ops.object.select_all(action='DESELECT');obj.select_set(True)
bpy.ops.export_scene.gltf(filepath=str(OUT/'leather_backpack.glb'),export_format='GLB',use_selection=True,export_animations=False,export_yup=True,export_image_format='JPEG',export_jpeg_quality=92)
report={'source_filename':SOURCE.name,'source_sha256':hashlib.sha256(SOURCE.read_bytes()).hexdigest(),'source_bytes':SOURCE.stat().st_size,'source_triangles':original_triangles,'game_triangles':sum(len(p.vertices)-2 for p in obj.data.polygons),'game_bytes':(OUT/'leather_backpack.glb').stat().st_size,'game_height_m':.60,'textures_px':2048,'status':'Reusable project asset; not yet worn by the player','source_note':'Supplied by Dallon as a free backpack model; no author or license metadata was embedded in the GLB','remaining':['Fit shoulder straps to traveler torso/cape','Resolve existing backpack/quiver overlap before wearable integration']}
(REVIEW/'inspection.json').write_text(json.dumps(report,indent=2)+'\n')
# Matched source-review framing and lights, scaled to the normalized asset.
points=[obj.matrix_world@Vector(c) for c in obj.bound_box];lo=Vector([min(p[i] for p in points) for i in range(3)]);hi=Vector([max(p[i] for p in points) for i in range(3)]);center=(lo+hi)*.5;span=max(hi-lo)
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.device='CPU';scene.cycles.samples=16;scene.cycles.use_denoising=True;scene.render.resolution_x=850;scene.render.resolution_y=850;scene.render.resolution_percentage=100;scene.world.color=(.25,.25,.25);scene.view_settings.view_transform='AgX'
bpy.ops.mesh.primitive_plane_add(size=200*span,location=(center.x,center.y,lo.z-.003*span));mat=bpy.data.materials.new('Review ground');mat.diffuse_color=(.095,.11,.13,1);bpy.context.object.data.materials.append(mat)
for offset,energy,size in [((-2,-3,4),450,3),((3,-1,2),220,3),((0,3,3),500,2)]:
 bpy.ops.object.light_add(type='AREA',location=center+Vector(offset)*span);light=bpy.context.object;light.data.energy=energy*span*span;light.data.shape='DISK';light.data.size=size*span;light.rotation_euler=(center-light.location).to_track_quat('-Z','Y').to_euler()
bpy.ops.object.camera_add();cam=bpy.context.object;scene.camera=cam;cam.data.type='ORTHO';cam.data.ortho_scale=1.28*span
for name,offset in [('front',(1.6,-2.5,1.2)),('back',(-1.6,2.5,1.2))]:
 cam.location=center+Vector(offset)*span;cam.rotation_euler=(center-cam.location).to_track_quat('-Z','Y').to_euler();scene.render.filepath=str(REVIEW/('optimized-'+name+'.png'));bpy.ops.render.render(write_still=True)
print('BACKPACK_READY',json.dumps(report))
