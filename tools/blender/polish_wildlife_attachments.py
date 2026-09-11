"""Correct attachment and material faults found in cycle 19 face/rear review."""
from pathlib import Path
import bpy,sys
from mathutils import Vector
R=Path(__file__).resolve().parents[2]
PASS=int(next((a.split('=')[1] for a in sys.argv if a.startswith('--art-pass=')),'20'))
REV=4
OUT=R/'art/blender/cycles'/f'cycle_{PASS:02d}';OUT.mkdir(parents=True,exist_ok=True)
if (OUT/'characters.blend').exists():raise RuntimeError('Preserve saved source; choose a fresh cycle')
bpy.ops.wm.open_mainfile(filepath=str(R/'art/blender/cycles/cycle_19/characters.blend'))
N=['WILLOW SCOUT','HEARTHLAND RANGER','RIDGE WAYFARER','EMBER FORAGER'];A=['BRISTLEBACK BOAR','WOODLAND HOG','RIDGEBACK BOAR','MEADOW BUCK']
for kind,name in enumerate(A):
 col=bpy.data.collections[name+' — authored study']
 eyes=[sum((v.co for v in o.data.vertices),Vector())/len(o.data.vertices) for o in col.objects if o.name.startswith('Surface fitted almond wildlife eye')]
 removed=0
 for o in col.objects:
  if o.type=='CURVE' and o.name.startswith(('Laid body coat','Fine coat highlights','Brushed dark ridge')):
   for sp in list(o.data.splines):
    if any((Vector(p.co[:3])-e).length<.050 for p in sp.points for e in eyes):o.data.splines.remove(sp);removed+=1
  if kind==3 and o.type=='MESH':
   if o.name.startswith(('Curving antler beam','Forward brow tine','Outer antler fork')):
    for v in o.data.vertices:v.co.z-=.060
   if o.name.startswith(('Cupped wildlife ear','Inset ear velvet')):
    for v in o.data.vertices:v.co.z-=.020
 hooves=[o for o in col.objects if o.name.startswith('Shaped cloven hoof')]
 m=hooves[0].data.materials[0].copy();m.name=name+' matte hoof horn';p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(.043,.028,.017,1);p.inputs['Roughness'].default_value=.76;p.inputs['Specular IOR Level'].default_value=.20
 for o in hooves:o.data.materials[0]=m
 print('EYE_CLEARANCE_STRANDS_REMOVED',name,removed,flush=True)
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
notes=bpy.data.texts.get('REVIEW STATUS');notes.clear();notes.write(f'Cycle {PASS}: cycle 19 wildlife with antler/ear seating, eye/fur clearance and matte hoof corrections. Travelers preserved from cycle 15. Offline unrigged studies. Review actual silhouette/fur and remaining illustration-fidelity gap.')
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'characters.blend'),compress=True)
print('WILDLIFE_PASS_COMPLETE',PASS,flush=True)
