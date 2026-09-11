"""Render the complete saved study without changing the native source."""
from pathlib import Path
import bpy,sys
from mathutils import Vector
R=Path(__file__).resolve().parents[2]
PASS=int(next((a.split('=')[1] for a in sys.argv if a.startswith('--art-pass=')),'26'))
folder=R/'art/blender/cycles'/f'cycle_{PASS:02d}'
bpy.ops.wm.open_mainfile(filepath=str(folder/'characters.blend'))
scene=bpy.context.scene;cam=scene.camera
cam.location=(4.5,-8,4.5);cam.rotation_euler=(Vector((0,1.25,1))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.ortho_scale=7.4
scene.cycles.samples=24;scene.render.resolution_x=2400;scene.render.resolution_y=1600;scene.render.filepath=str(folder/'all-eight.png')
bpy.ops.render.render(write_still=True)
print('SAVED_SOURCE_OVERVIEW_RENDERED',PASS,flush=True)
