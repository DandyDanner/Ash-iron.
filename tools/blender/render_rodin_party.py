"""Render the actual prepared party together, without modifying its saved rig scene."""
import bpy
from pathlib import Path
from mathutils import Vector
R=Path(__file__).resolve().parents[2]
bpy.ops.wm.open_mainfile(filepath=str(R/'art/blender/rodin_party/travelers.blend'))
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=32;scene.cycles.use_denoising=True;scene.render.resolution_x=1600;scene.render.resolution_y=900;scene.render.resolution_percentage=100;scene.world.color=(.08,.08,.08)
center=Vector((0,0,1))
for offset,energy,size in [((-4,-5,6),900,5),((4,-3,4),650,5),((0,4,5),1000,5)]:
 bpy.ops.object.light_add(type='AREA',location=offset);l=bpy.context.object;l.data.energy=energy;l.data.size=size;l.rotation_euler=(center-l.location).to_track_quat('-Z','Y').to_euler()
bpy.ops.object.camera_add(location=(0,-8,1.4));cam=bpy.context.object;scene.camera=cam;cam.rotation_euler=(center-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=6.1
bpy.ops.mesh.primitive_plane_add(size=200);floor=bpy.context.object;mat=bpy.data.materials.new('Review ground');mat.diffuse_color=(.13,.14,.13,1);floor.data.materials.append(mat)
scene.render.filepath=str(R/'docs/art/rodin-party/four-travelers.png');bpy.ops.render.render(write_still=True)

# Reuse the saved rigs for matching individual rest views without rebuilding skins.
if '--portraits' in __import__('sys').argv:
 rigs=sorted([o for o in scene.objects if o.type=='ARMATURE'],key=lambda o:o.name)
 slugs=['willow_scout','hearthland_ranger','ridge_wayfarer','ember_forager']
 scene.render.resolution_x=600;scene.render.resolution_y=900;scene.cycles.samples=20
 floor.hide_render=True
 for k,rig in enumerate(rigs):
  for o in scene.objects:
   if o.type=='MESH' and o!=floor:o.hide_render=o.parent!=rig
  old=rig.location.copy();rig.location.x=0
  for name,offset,span,aim in [('front',(0,-4,0),2.3,Vector((0,0,1.03))),('back',(0,4,0),2.3,Vector((0,0,1.03))),('face',(0,-4,0),.52,Vector((.04,0,1.86)))]:
   cam.data.ortho_scale=span;cam.location=aim+Vector(offset);cam.rotation_euler=(aim-cam.location).to_track_quat('-Z','Y').to_euler();scene.render.filepath=str(R/'docs/art/rodin-party'/(slugs[k]+'-'+name+'.png'));bpy.ops.render.render(write_still=True)
  rig.location=old
