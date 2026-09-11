"""Export optimized, vertex-colored skinned travelers from the preserved cycle 26 study.
Source is never saved or changed. Output GLBs are driven by Godot's existing movement/tool rig.
"""
from pathlib import Path
import bpy,math,json
from mathutils import Vector,Matrix
R=Path(__file__).resolve().parents[2]
OUT=R/'assets/characters';OUT.mkdir(parents=True,exist_ok=True)
N=['WILLOW SCOUT','HEARTHLAND RANGER','RIDGE WAYFARER','EMBER FORAGER']
SLUG=['willow_scout','hearthland_ranger','ridge_wayfarer','ember_forager']
LEG=('Canvas trouser','Rolled trouser','Exposed ankle','Shaped leather boot','Folded boot','Layered boot','Crossed flax','Canvas pocket','Pocket seam')
ARM=('Gathered woven sleeve','Rolled fabric cuff','Sleeve underarm','Forearm','Leather wrist')
CAPE=('Tailored shoulder cape','Closed asymmetric wayfarer poncho','Bound tailored cape','Cape opening','Poncho woven','Flat embroidered cape','Tailored cape','Hanging folded hood','Hood center')
OMIT=('Leather quiver','Arrow shaft','Arrow fletching','Stowed wooden bow','Bow string')

def smooth(v):
 v=max(0,min(1,v));return v*v*(3-2*v)
def weights(name,p,center):
 side='Left' if center.x<0 else 'Right'
 if name.startswith(('Relaxed finger','Thumb','Palm')):return {side+'Hand':1}
 if name.startswith(LEG):
  if name.startswith(('Canvas pocket','Pocket seam')):return {side+'Leg':1}
  knee=smooth((p.z-.49)/.10);hip=smooth((p.z-.88)/.12)
  return {side+'Knee':1-knee,side+'Leg':knee*(1-hip),'Body':knee*hip}
 if name.startswith(ARM):
  elbow=smooth((p.z-1.15)/.085);shoulder=smooth((p.z-1.40)/.055)
  return {side+'Elbow':1-elbow,side+'Arm':elbow*(1-shoulder),'Torso':elbow*shoulder}
 if name.startswith(CAPE):return {'Cape':1}
 if ('hair' in name.lower() or name.startswith(('Sculpted swept','Crown to nape','Scout loose','Scout tied','Scout fabric','Rounded copper','Forager side','Forager crown','Woven crown','Long gathered','Surface freckle','Surface-following')) or name.startswith(tuple(N))):return {'Head':1}
 if name.startswith('Neck'):
  w=smooth((p.z-1.47)/.075);return {'Torso':1-w,'Head':w}
 if center.z<1.08:return {'Body':1}
 return {'Torso':1}

def bones():
 points={'Body':(0,0,.97),'Torso':(0,0,1.0),'Head':(0,0,1.53),'Cape':(0,0,1.50)}
 for side,x in [('Left',-1),('Right',1)]:
  points.update({side+'Leg':(x*.10,0,.96),side+'Knee':(x*.10,-.007,.54),side+'Arm':(x*.151,0,1.442),side+'Elbow':(x*.267,-.005,1.188),side+'Hand':(x*.310,-.018,.931)})
 return points

def runtime_material(name,rough,metal=0):
 m=bpy.data.materials.new('Game '+name);m.use_nodes=True;p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(1,1,1,1);p.inputs['Roughness'].default_value=rough;p.inputs['Metallic'].default_value=metal
 a=m.node_tree.nodes.new('ShaderNodeVertexColor');a.layer_name='GameColor';m.node_tree.links.new(a.outputs['Color'],p.inputs['Base Color']);m.use_backface_culling=False
 return m

report=[]
for kind,name in enumerate(N):
 bpy.ops.wm.open_mainfile(filepath=str(R/'art/blender/cycles/cycle_26/characters.blend'))
 col=bpy.data.collections[name+' — authored study'];root=next(o for o in col.objects if o.type=='EMPTY');scale=Vector(root.scale)*1.14
 output=bpy.data.collections.new('GAME EXPORT');bpy.context.scene.collection.children.link(output)
 mats=[runtime_material('Fabric',.90),runtime_material('Skin',.67),runtime_material('Hair',.66),runtime_material('Brass',.4,.55),runtime_material('Eyes',.35)]
 groups={'Traveler':[],'LeftFingers':[],'RightFingers':[]};points=bones();exported=[]
 for source in list(col.objects):
  if source.type not in ['MESH','CURVE'] or source.name.startswith(OMIT):continue
  if source.type=='CURVE':source.data.bevel_resolution=0;source.data.resolution_u=2
  for mod in source.modifiers:
   if mod.type=='SUBSURF':mod.levels=0;mod.render_levels=0
  bpy.context.view_layer.update();ev=source.evaluated_get(bpy.context.evaluated_depsgraph_get());md=bpy.data.meshes.new_from_object(ev,preserve_all_data_layers=True,depsgraph=bpy.context.evaluated_depsgraph_get())
  if not len(md.polygons):bpy.data.meshes.remove(md);continue
  local=root.matrix_world.inverted()@source.matrix_world
  md.transform(local)
  obj=bpy.data.objects.new(source.name+' game',md);output.objects.link(obj)
  bpy.context.view_layer.objects.active=obj;obj.select_set(True)
  triangles=sum(len(p.vertices)-2 for p in md.polygons)
  limit=18000 if 'continuous facial planes' in source.name else (10000 if source.name.startswith(CAPE) else 5000)
  if triangles>limit:
   dec=obj.modifiers.new('Game triangle budget','DECIMATE');dec.ratio=limit/triangles;bpy.ops.object.modifier_apply(modifier=dec.name);md=obj.data
  center=sum((v.co for v in md.vertices),Vector())/len(md.vertices)
  oldmats=list(md.materials)
  colorattr=md.color_attributes.get('Face warmth');radial=md.attributes.get('Eye radial coordinate')
  colors=md.color_attributes.new(name='GameColor',type='FLOAT_COLOR',domain='CORNER')
  categories=[]
  for poly in md.polygons:
   original=oldmats[min(poly.material_index,len(oldmats)-1)] if oldmats else None
   base=original.diffuse_color[:] if original else (.5,.5,.5,1)
   matname=original.name.lower() if original else ''
   category=4 if 'iris and sclera' in matname else 3 if 'brass' in matname else 2 if ('hair' in matname or 'stubble' in matname) else 1 if ('skin' in matname or 'lip' in matname or 'freckle' in matname) else 0
   ramp=next((n.color_ramp for n in original.node_tree.nodes if n.type=='VALTORGB'),None) if original and original.use_nodes else None
   for index in poly.loop_indices:
    vertex=md.loops[index].vertex_index;color=base
    if colorattr:color=colorattr.data[vertex if colorattr.domain=='POINT' else index].color[:]
    elif radial and ramp:color=ramp.evaluate(radial.data[vertex].vector.length)
    colors.data[index].color=color
   categories.append(category);poly.use_smooth=True
  for attr in list(md.color_attributes):
   if attr.name!='GameColor':md.color_attributes.remove(attr)
  md.color_attributes.active_color=md.color_attributes['GameColor']
  md.materials.clear()
  for m in mats:md.materials.append(m)
  for poly,category in zip(md.polygons,categories):poly.material_index=category
  vg={b:obj.vertex_groups.new(name=b) for b in points}
  for v in md.vertices:
   for bone,w in weights(source.name,v.co,center).items():
    if w>0.0001:vg[bone].add([v.index],w,'REPLACE')
   v.co=Vector((v.co.x*scale.x,v.co.y*scale.y,v.co.z*scale.z))
  key=('LeftFingers' if center.x<0 else 'RightFingers') if source.name.startswith(('Relaxed finger','Thumb')) else 'Traveler'
  groups[key].append(obj);obj.select_set(False)
 arm_data=bpy.data.armatures.new('TravelerRig');arm=bpy.data.objects.new('TravelerRig',arm_data);output.objects.link(arm);bpy.context.view_layer.objects.active=arm;arm.select_set(True);bpy.ops.object.mode_set(mode='EDIT')
 for bone,p in points.items():
  b=arm_data.edit_bones.new(bone);b.head=Vector((p[0]*scale.x,p[1]*scale.y,p[2]*scale.z));b.tail=b.head+Vector((0,0,.10))
 bpy.ops.object.mode_set(mode='OBJECT');arm.select_set(False)
 for key,objects in groups.items():
  bpy.ops.object.select_all(action='DESELECT')
  for o in objects:o.select_set(True)
  bpy.context.view_layer.objects.active=objects[0];bpy.ops.object.join();o=bpy.context.object;o.name=key;o.data.name=key
  mod=o.modifiers.new('Traveler skin','ARMATURE');mod.object=arm;o.parent=arm;exported.append(o)
 bpy.ops.object.select_all(action='DESELECT');arm.select_set(True)
 for o in exported:o.select_set(True)
 # Export only runtime geometry and its rig, with the baked vertex palette.
 path=OUT/(SLUG[kind]+'.glb')
 bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,export_animations=False,export_skins=True,export_all_influences=False,export_def_bones=True,export_materials='EXPORT',export_attributes=False,export_yup=True)
 tri=sum(sum(len(p.vertices)-2 for p in o.data.polygons) for o in exported)
 report.append({'design':SLUG[kind],'triangles':tri,'bytes':path.stat().st_size,'bones':len(points),'scale':list(scale)})
 print('PLAYABLE_EXPORTED',report[-1],flush=True)
(OUT/'export_report.json').write_text(json.dumps({'source':'art/blender/cycles/cycle_26/characters.blend','models':report},indent=2)+'\n')
