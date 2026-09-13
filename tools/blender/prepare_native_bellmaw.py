"""Prepare the single native-PBR Bellmaw for the existing sixteen combat controls.
Run in Blender: --background --factory-startup --python tools/blender/prepare_native_bellmaw.py
Source shape/UVs/textures remain intact apart from uniform grounding, seam welding,
and the optional Blink shape key at nonzero values.
"""
import bpy, bmesh, json, hashlib, heapq
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
def segment_distance(samples, start, end):
    start = np.asarray(start, dtype=float)
    delta = np.asarray(end, dtype=float) - start
    t = np.clip(((samples-start)@delta)/(delta@delta),0,1)
    return np.linalg.norm(samples-(start+t[:,None]*delta),axis=1)
adjacency = [[] for _ in obj.data.vertices]
for edge in obj.data.edges:
    a,b = edge.vertices
    length = float(np.linalg.norm(P[a]-P[b]))
    adjacency[a].append((b,length))
    adjacency[b].append((a,length))
def surface_distance(seeds):
    distances = np.full(len(P),np.inf)
    queue = []
    for seed in seeds:
        distances[seed] = 0
        heapq.heappush(queue,(0,int(seed)))
    while queue:
        distance,vertex = heapq.heappop(queue)
        if distance != distances[vertex]:
            continue
        for neighbor,length in adjacency[vertex]:
            candidate = distance+length
            if candidate < distances[neighbor]:
                distances[neighbor] = candidate
                heapq.heappush(queue,(candidate,neighbor))
    return distances
body_distance = surface_distance(np.nonzero(np.abs(x) < .26)[0])
anatomical_fields = {}
for side,sign in [('L',-1),('R',1)]:
    for end in ['Front','Rear']:
        key = end+side
        end_seed = y < .08 if end == 'Front' else y >= .08
        seeds = np.nonzero((x*sign > .70)&end_seed&(z < .68))[0]
        limb_distance = surface_distance(seeds)
        finite = np.isfinite(body_distance)&np.isfinite(limb_distance)
        ownership = np.ones(len(P))
        ownership[finite] = smooth((body_distance[finite]-limb_distance[finite]+.05)/.30)
        anatomical_fields[key] = ownership
weights = np.zeros((len(P),len(bones)))
for side, sign in [('L',-1), ('R',1)]:
    for end in ['Front','Rear']:
        key = end+side
        upper = np.asarray(points[key+'Upper'])
        lower = np.asarray(points[key+'Lower'])
        foot = np.asarray(points[key+'Foot'])
        toe = foot + np.asarray((0,-.16 if end == 'Front' else .28,0))
        centerline = np.minimum.reduce((
            segment_distance(P,upper,lower),
            segment_distance(P,lower,foot),
            segment_distance(P,foot,toe),
        ))
        # The source's legs are thick, but each remains a distinct anatomical
        # column. Bound the field around that column before blending it into the
        # torso so moving one shoulder cannot drag the chest or opposite quarter.
        radial = 1-smooth((centerline-.18)/.24)
        lateral = smooth((x*sign-.32)/.30)
        height = 1-smooth((z-.79)/.25)
        end_gate = (1-smooth((y+.04)/.32)) if end == 'Front' else smooth((y-.02)/.32)
        ownership = anatomical_fields[key]
        limb = np.clip(radial*lateral*height*end_gate*ownership,0,1)
        # Bellmaw's palms and low forearms flare beyond their joint centerlines
        # and overlap the throat in XYZ space. Surface distance distinguishes
        # the true limb shell from the nearby body, then gives that distal shell
        # full ownership below the wrist. The ramp fades through the forearm and
        # does not alter the soft shoulder transition.
        side_gate = smooth((x*sign-.30)/.14)
        distal_ownership = (1-smooth((z-.54)/.18))*smooth((ownership-.25)/.45)*side_gate*end_gate
        limb = np.maximum(limb,distal_ownership)
        foot_share = 1-smooth((z-.10)/.15)
        upper_share = smooth((z-.32)/.25)
        lower_share = np.maximum(0,1-foot_share-upper_share)
        shares = foot_share+lower_share+upper_share
        weights[:,index[key+'Upper']] = limb*upper_share/shares
        weights[:,index[key+'Lower']] = limb*lower_share/shares
        weights[:,index[key+'Foot']] = limb*foot_share/shares
limb = weights.sum(1)
head = (1-smooth((y+.68)/.56))*(1-limb)
throat = (1-smooth((y+1.04)/.42))*(1-smooth((z-.74)/.22))*(1-smooth((np.abs(x)-.40)/.18))
throat = np.minimum(throat, 1-limb)
weights[:,index['Throat']] = throat
weights[:,index['Head']] = np.maximum(0,head-throat)
weights[:,index['Spine']] = np.maximum(0,1-weights.sum(1))
# The face follows the head rigidly. Weight fields are already continuous in
# model space, so topology diffusion is intentionally omitted: diffusion was
# pulling shoulder influence into the torso and across the front/rear boundary.
face = (y < -.40) & (z > .96) & (np.abs(x) < .46)
weights[face] = 0
weights[face,index['Head']] = 1
order = np.argsort(weights,axis=1)[:,:-4]
np.put_along_axis(weights,order,0,axis=1)
weights /= weights.sum(1)[:,None]
for j,name in enumerate(bones):
    group = obj.vertex_groups.new(name=name)
    for i in np.nonzero(weights[:,j] > 1e-6)[0]:
        group.add([int(i)],float(weights[i,j]),'REPLACE')
# The sculpt includes asymmetric upper/lower lid folds around both eyes. Closing
# those native folds produces a subtle blink without overlay geometry, eyeball
# scaling, repainting, or any change to the neutral Basis geometry.
obj.shape_key_add(name='Basis')
blink = obj.shape_key_add(name='Blink')
blink_displacements = []
for i,vertex in enumerate(obj.data.vertices):
    p = vertex.co
    eye_x,eye_y,eye_z,seam_z = ((.302,-.895,1.122,1.117) if p.x >= 0 else (-.225,-.930,1.108,1.103))
    dx,dy,dz = abs(p.x-eye_x),abs(p.y-eye_y),abs(p.z-eye_z)
    lid_distance = (dx/.105)**2+(dy/.078)**2+(dz/.086)**2
    if lid_distance >= 1:
        continue
    lid = (1-lid_distance)**2
    inner_distance = (dx/.078)**2+(dy/.060)**2+(dz/.061)**2
    inner = max(0,1-inner_distance)**2
    target = blink.data[i].co
    target.z += (seam_z-p.z)*.88*lid
    target.y += .026*inner
    blink_displacements.append(float((target-p).length))
blink.value = 0
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
bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,export_animations=False,export_skins=True,export_all_influences=False,export_yup=True,export_extras=True,export_morph=True,export_morph_normal=True,export_morph_tangent=False)
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'bellmaw.blend'))
weight_extents = {}
distal_residuals = {}
for end in ['Front','Rear']:
    for side in ['L','R']:
        key = end+side
        mask = weights[:,index[key+'Upper']] > .1
        weight_extents[key+'Upper'] = {'vertices_over_10pct':int(mask.sum()),'bounds_over_10pct':[P[mask].min(0).tolist(),P[mask].max(0).tolist()]}
        limb_indices = [index[key+'Upper'],index[key+'Lower'],index[key+'Foot']]
        end_region = y < -.04 if end == 'Front' else y >= .30
        distal = (anatomical_fields[key] > .95)&(z < .54)&(x*(-1 if side == 'L' else 1) > .44)&end_region
        residual = 1-weights[:,limb_indices].sum(1)
        distal_residuals[key] = {'region':'geodesic ownership > 0.95, z < 0.54 m, signed x > 0.44 m, inside the fully gated front/rear quarter','vertices':int(distal.sum()),'min_limb_weight':float(weights[:,limb_indices].sum(1)[distal].min()),'max_spine_weight':float(weights[distal,index['Spine']].max()),'max_head_or_throat_weight':float(weights[distal][:,[index['Head'],index['Throat']]].sum(1).max()),'max_non_limb_weight':float(residual[distal].max())}
report = {'source_sha256':hashlib.sha256(SOURCE.read_bytes()).hexdigest(),'generation_id':arm['generation_id'],'height_m':1.34,'runtime_scale':4,'source_center':center.tolist(),'uniform_scale':float(scale),'triangles':sum(len(p.vertices)-2 for p in obj.data.polygons),'bones':bones,'pivots_blender':points,'welded_seam_vertices':before_weld-len(P),'material':material.name,'textures':textures,'max_weights':int((weights>1e-6).sum(1).max()),'weighting':{'method':'Surface-geodesic anatomical ownership gating with bounded shoulder-elbow-paw fields','topology_smoothing_passes':0,'distal_ownership':'Front paw and forearm shells are fully limb-owned below 0.54 m; geodesic body seeds exclude nearby throat geometry and the ramp fades through the upper forearm to the shoulder. Rear limbs retain their softer gait-oriented boundary.','distal_residuals':distal_residuals,'upper_limb_extents':weight_extents},'morphs':{'Blink':{'interface':'0 = unchanged native open eyes; 1 = locally closed native lids','moved_vertices':len(blink_displacements),'max_displacement_m':max(blink_displacements),'mean_displacement_m':sum(blink_displacements)/len(blink_displacements),'neutral_basis_unchanged':True}},'shape_changes':'Uniform normalization and coincident seam welding; Blink changes only the existing local eye/lid vertices at nonzero values. No remesh, decimation or repaint.','limitations':['Procedural combat-driven poses, no baked animation clips','No terrain foot IK or independent toes','Blink is a local sculpted lid closure; no gaze, pupil or independent eyelid controls'],'bytes':path.stat().st_size}
(OUT/'report.json').write_text(json.dumps(report,indent=2)+'\n')
print('BELLMAW NATIVE READY',json.dumps(report),flush=True)
