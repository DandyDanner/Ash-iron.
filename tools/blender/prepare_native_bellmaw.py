"""Prepare the single native-PBR Bellmaw for the existing sixteen combat controls.
Run in Blender: --background --factory-startup --python tools/blender/prepare_native_bellmaw.py
Source shape/UVs/textures remain intact apart from uniform grounding and seam welding.
"""
import bpy, bmesh, json, hashlib
import numpy as np
from pathlib import Path
from mathutils import Vector
R = Path(__file__).resolve().parents[2]
OUT = R / 'art/blender/creature_rodin_refresh/bellmaw'
SOURCE = OUT / 'source.glb'
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
bpy.ops.import_scene.gltf(filepath=str(SOURCE))
meshes = [o for o in bpy.context.scene.objects if o.type == 'MESH']
assert len(meshes) == 1, 'Expected one Bellmaw, not a concept sheet'
obj = meshes[0]
bpy.context.view_layer.objects.active = obj
obj.select_set(True)
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
before_weld = len(obj.data.vertices)
bm = bmesh.new()
bm.from_mesh(obj.data)
bmesh.ops.remove_doubles(bm, verts=list(bm.verts), dist=1e-6)
bm.to_mesh(obj.data)
bm.free()
P = np.array([v.co[:] for v in obj.data.vertices])
lo, hi = P.min(0), P.max(0)
center = (lo + hi) / 2
center[2] = lo[2]
scale = 1.34 / (hi[2] - lo[2])
P = (P - center) * scale
obj.data.vertices.foreach_set('co', P.ravel())
obj.data.update()
obj.name = 'BellmawSkin'
assert len(obj.data.materials) == 1
material = obj.data.materials[0]
material.name = 'Bellmaw Native PBR'
textures = {}
for n in material.node_tree.nodes:
    if n.type != 'TEX_IMAGE':
        continue
    name = n.image.name.lower()
    role = 'normal' if 'normal' in name else 'metallic_roughness' if 'roughness' in name else 'albedo'
    n.image.name = 'bellmaw_native_' + role
    textures[role] = {'name': n.image.name, 'size': list(n.image.size)}
assert set(textures) == {'normal', 'metallic_roughness', 'albedo'}
# Rest positions intentionally match Godot's named controls. The new source already
# has the same broad quadruped proportions; no anisotropic shape fitting is applied.
points = {'Root': (0,0,0), 'Spine': (0,.05,.83), 'Head': (0,-.73,1.04), 'Throat': (0,-.98,.60)}
for side, sign in [('L',-1), ('R',1)]:
    for end, y in [('Front',-.68), ('Rear',.87)]:
        key = end + side
        points[key+'Upper'] = (sign*.64,y,.83)
        points[key+'Lower'] = (sign*.84,y-.03,.37)
        points[key+'Foot'] = (sign*.84,y-.13,.085)
bones = list(points)
index = {name:i for i,name in enumerate(bones)}
x,y,z = P.T
def smooth(t):
    t = np.clip(t,0,1)
    return t*t*(3-2*t)
weights = np.zeros((len(P),len(bones)))
for side, sign in [('L',-1), ('R',1)]:
    for end in ['Front','Rear']:
        key = end+side
        domain = (x*sign >= 0) & ((y < .1) if end == 'Front' else (y >= .1))
        limb = smooth((np.abs(x)-.36)/.26)*smooth((1.07-z)/.43)
        limb *= smooth((y-.16)/.33) if end == 'Rear' else 1-smooth((y+.40)/.40)
        lower = 1-smooth((z-.26)/.33)
        foot = 1-smooth((z-.10)/.17)
        weights[domain,index[key+'Upper']] = (limb*(1-lower))[domain]
        weights[domain,index[key+'Lower']] = (limb*lower*(1-foot))[domain]
        weights[domain,index[key+'Foot']] = (limb*lower*foot)[domain]
limb = weights.sum(1)
head = (1-smooth((y+.68)/.56))*(1-limb)
throat = (1-smooth((y+1.04)/.42))*(1-smooth((z-.74)/.22))*(1-smooth((np.abs(x)-.40)/.18))
throat = np.minimum(throat, 1-limb)
weights[:,index['Throat']] = throat
weights[:,index['Head']] = np.maximum(0,head-throat)
weights[:,index['Spine']] = np.maximum(0,1-weights.sum(1))
# Feet must not tear under planted impacts; face follows the head, not the throat.
face = (y < -.40) & (z > .96) & (np.abs(x) < .46)
weights[face] = 0
weights[face,index['Head']] = 1
edges = np.array([tuple(e.vertices) for e in obj.data.edges])
a,b = edges.T
counts = np.bincount(np.r_[a,b], minlength=len(P))
for _ in range(6):
    previous = weights.copy()
    for j in range(len(bones)):
        average = np.bincount(np.r_[a,b], weights=np.r_[previous[b,j],previous[a,j]], minlength=len(P))/np.maximum(counts,1)
        weights[:,j] = .6*previous[:,j] + .4*average
    weights[face] = 0
    weights[face,index['Head']] = 1
order = np.argsort(weights,axis=1)[:,:-4]
np.put_along_axis(weights,order,0,axis=1)
weights /= weights.sum(1)[:,None]
for j,name in enumerate(bones):
    group = obj.vertex_groups.new(name=name)
    for i in np.nonzero(weights[:,j] > 1e-6)[0]:
        group.add([int(i)],float(weights[i,j]),'REPLACE')
armdata = bpy.data.armatures.new('BellmawRig')
arm = bpy.data.objects.new('BellmawRig',armdata)
bpy.context.scene.collection.objects.link(arm)
bpy.ops.object.select_all(action='DESELECT')
arm.select_set(True)
bpy.context.view_layer.objects.active = arm
bpy.ops.object.mode_set(mode='EDIT')
for name,p in points.items():
    bone = armdata.edit_bones.new(name)
    bone.head = p
    bone.tail = Vector(p)+Vector((0,0,.16))
bpy.ops.object.mode_set(mode='OBJECT')
modifier = obj.modifiers.new('Bellmaw native skin','ARMATURE')
modifier.object = arm
obj.parent = arm
obj.select_set(True)
arm['generation_id'] = '2d8dcd9c-7db7-44a1-9aa5-14fd5802c9d1'
path = R/'assets/creatures/bellmaw.glb'
bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,export_animations=False,export_skins=True,export_all_influences=False,export_yup=True,export_extras=True)
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'bellmaw.blend'))
report = {'source_sha256':hashlib.sha256(SOURCE.read_bytes()).hexdigest(),'generation_id':arm['generation_id'],'height_m':1.34,'runtime_scale':4,'source_center':center.tolist(),'uniform_scale':float(scale),'triangles':sum(len(p.vertices)-2 for p in obj.data.polygons),'bones':bones,'pivots_blender':points,'welded_seam_vertices':before_weld-len(P),'material':material.name,'textures':textures,'max_weights':int((weights>1e-6).sum(1).max()),'shape_changes':'Uniform normalization and coincident seam welding only; no remesh, decimation or repaint.','limitations':['Procedural combat-driven poses, no baked animation clips','No terrain foot IK or independent toes','Generated topology and broad shoulder weights need further polish'],'bytes':path.stat().st_size}
(OUT/'report.json').write_text(json.dumps(report,indent=2)+'\n')
print('BELLMAW NATIVE READY',json.dumps(report),flush=True)
