"""Render rear and face inspection views without modifying the saved model source."""
from pathlib import Path
import bpy,sys
from mathutils import Vector
R=Path(__file__).resolve().parents[2]
PASS=int(next((a.split('=')[1] for a in sys.argv if a.startswith('--art-pass=')),'19'))
OUT=R/'art/blender/cycles'/f'cycle_{PASS:02d}'
bpy.ops.wm.open_mainfile(filepath=str(OUT/'characters.blend'))
N=['WILLOW SCOUT','HEARTHLAND RANGER','RIDGE WAYFARER','EMBER FORAGER'];A=['BRISTLEBACK BOAR','WOODLAND HOG','RIDGEBACK BOAR','MEADOW BUCK']
s=bpy.context.scene;s.cycles.samples=32;c=s.camera
for name in N:bpy.data.collections[name+' — authored study'].hide_render=True
def render(target,offset,scale,file,w=1100,h=1000):
 c.location=Vector(target)+Vector(offset);c.rotation_euler=(Vector(target)-c.location).to_track_quat('-Z','Y').to_euler();c.data.ortho_scale=scale;s.render.resolution_x=w;s.render.resolution_y=h;s.render.filepath=str(OUT/file);bpy.ops.render.render(write_still=True)
render((0,2.5,.98),(-.5,8,2.1),6.6,'wildlife-rear.png',2400,1100)
for name in A:bpy.data.collections[name+' — authored study'].hide_render=True
for i,name in enumerate(A):
 col=bpy.data.collections[name+' — authored study'];col.hide_render=False;root=next(o for o in col.objects if o.type=='EMPTY');target=root.matrix_world@Vector((0,-.62,.68 if i<3 else 1.52))
 render(target,(1.6,-3,.45),.90 if i<3 else .75,['bristleback','hog','ridgeback','buck'][i]+'-face.png')
 col.hide_render=True
print('WILDLIFE_DETAIL_RENDERS_COMPLETE',flush=True)
