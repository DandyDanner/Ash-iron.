"""Build the original first-person hand asset used by first_person_hand.gd.

Run with Blender 4.x:
  blender --background --python generate_first_person_hands.py

Coordinates in this file are written in Godot's Y-up convention.  The helpers
convert them to Blender coordinates before construction and glTF export.
"""

from __future__ import annotations

import math
from pathlib import Path

import bpy
import bmesh
from mathutils import Vector


HERE = Path(__file__).resolve().parent
BLEND_PATH = HERE / "first_person_hands.blend"
GLB_PATH = HERE.parents[1] / "models" / "first_person_hands.glb"


def bvec(point):
    """Godot (X, Y, Z) -> Blender (X, -Z, Y)."""
    return Vector((point[0], -point[2], point[1]))


def bscale(dimensions):
    return (dimensions[0], dimensions[2], dimensions[1])


def material(name, color, roughness=0.88):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = (*color, 1.0)
    mat.roughness = roughness
    mat.use_nodes = True
    shader = mat.node_tree.nodes.get("Principled BSDF")
    shader.inputs["Base Color"].default_value = (*color, 1.0)
    shader.inputs["Roughness"].default_value = roughness
    shader.inputs["Specular IOR Level"].default_value = 0.22
    return mat


SKIN = material("SkinTint", (0.74, 0.40, 0.24), 0.90)
NAIL = material("NailTint", (0.77, 0.44, 0.29), 0.82)
CLOTH = material("ClothTint", (0.22, 0.35, 0.34))
CUFF = material("CuffTint", (0.67, 0.59, 0.43))


def ellipsoid(name, center, radii, mat, segments=16, rings=10):
    bpy.ops.mesh.primitive_uv_sphere_add(
        segments=segments,
        ring_count=rings,
        location=bvec(center),
    )
    obj = bpy.context.object
    obj.name = name
    obj.scale = bscale(radii)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(mat)
    return obj


def cylinder_between(name, start, end, radius, mat, vertices=14):
    a = bvec(start)
    b = bvec(end)
    direction = b - a
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=vertices,
        radius=radius,
        depth=direction.length,
        location=(a + b) * 0.5,
    )
    obj = bpy.context.object
    obj.name = name
    obj.rotation_mode = "QUATERNION"
    obj.rotation_quaternion = direction.to_track_quat("Z", "Y")
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    obj.data.materials.append(mat)
    return obj


def tapered_chain(prefix, points, radii, depth_scale, mat):
    pieces = []
    for index, point in enumerate(points):
        radius = radii[index]
        pieces.append(
            ellipsoid(
                f"{prefix}_Joint_{index}",
                point,
                (radius, radius, radius * depth_scale),
                mat,
            )
        )
    for index, (start, end) in enumerate(zip(points, points[1:])):
        pieces.append(
            cylinder_between(
                f"{prefix}_Bone_{index}",
                start,
                end,
                min(radii[index], radii[index + 1]) * 0.92,
                mat,
            )
        )
    return pieces


def join_voxel_smooth(parts, name, mat, voxel=0.0032, decimate=0.34):
    bpy.ops.object.select_all(action="DESELECT")
    for part in parts:
        part.select_set(True)
    bpy.context.view_layer.objects.active = parts[0]
    bpy.ops.object.join()
    obj = bpy.context.object
    obj.name = name
    obj.data.remesh_voxel_size = voxel
    bpy.ops.object.voxel_remesh()

    smooth = obj.modifiers.new("Anatomical smoothing", "SMOOTH")
    smooth.factor = 0.58
    smooth.iterations = 3
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.modifier_apply(modifier=smooth.name)

    reducer = obj.modifiers.new("Game mesh reduction", "DECIMATE")
    reducer.ratio = decimate
    bpy.ops.object.modifier_apply(modifier=reducer.name)

    # A light relaxation after edge collapse removes tiny local folds without
    # softening the knuckle and fingertip silhouette.
    finish = obj.modifiers.new("Post-reduction relaxation", "SMOOTH")
    finish.factor = 0.16
    finish.iterations = 2
    bpy.ops.object.modifier_apply(modifier=finish.name)
    for polygon in obj.data.polygons:
        polygon.use_smooth = True
    obj.data.materials.clear()
    obj.data.materials.append(mat)
    return obj


def repair_tiny_folds(obj):
    """Collapse only edge-collapse slivers that would appear as culled holes."""
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    repairs = 0
    for _iteration in range(64):
        bm.normal_update()
        candidates = []
        for edge in bm.edges:
            if len(edge.link_faces) != 2:
                continue
            first, second = edge.link_faces
            alignment = first.normal.dot(second.normal)
            smaller = first if first.calc_area() < second.calc_area() else second
            if alignment < -0.50 and smaller.calc_area() < 0.00003:
                candidates.append((alignment, smaller))
        if not candidates:
            break
        _alignment, folded_face = min(candidates, key=lambda candidate: candidate[0])
        shortest = min(folded_face.edges, key=lambda edge: edge.calc_length())
        bmesh.ops.collapse(bm, edges=[shortest], uvs=False)
        repairs += 1
    bm.normal_update()
    bm.to_mesh(obj.data)
    bm.free()
    obj.data.update()
    print(f"TOPOLOGY {obj.name}: repaired_tiny_folds={repairs}")


def validate_surface(obj, require_single_manifold=False, reject_tiny_folds=False):
    """Report topology and reject the near-opposite slivers that cull as holes."""
    mesh = obj.data
    bm = bmesh.new()
    bm.from_mesh(mesh)
    remaining = set(bm.verts)
    components = 0
    while remaining:
        components += 1
        stack = [remaining.pop()]
        while stack:
            vertex = stack.pop()
            for edge in vertex.link_edges:
                other = edge.other_vert(vertex)
                if other in remaining:
                    remaining.remove(other)
                    stack.append(other)
    non_manifold = sum(1 for edge in bm.edges if not edge.is_manifold)
    bm.free()

    edge_faces = {}
    for polygon in mesh.polygons:
        vertices = list(polygon.vertices)
        for index, start in enumerate(vertices):
            end = vertices[(index + 1) % len(vertices)]
            key = (min(start, end), max(start, end))
            edge_faces.setdefault(key, []).append(polygon.index)
    tiny_folds = []
    minimum_dot = 1.0
    for faces in edge_faces.values():
        if len(faces) != 2:
            continue
        first = mesh.polygons[faces[0]]
        second = mesh.polygons[faces[1]]
        alignment = first.normal.dot(second.normal)
        minimum_dot = min(minimum_dot, alignment)
        # Broad grip concavities are valid; a tiny edge-collapse sliver with
        # opposing neighbors is not. These caused visible one-triangle holes.
        if alignment < -0.50 and min(first.area, second.area) < 0.00003:
            tiny_folds.append((faces, alignment, first.area, second.area))

    print(
        f"TOPOLOGY {obj.name}: polygons={len(mesh.polygons)} components={components} "
        f"non_manifold={non_manifold} min_neighbor_dot={minimum_dot:.5f} "
        f"tiny_opposed_folds={len(tiny_folds)}"
    )
    if require_single_manifold:
        assert components == 1, f"{obj.name} split into {components} components"
        assert non_manifold == 0, f"{obj.name} has {non_manifold} non-manifold edges"
    if reject_tiny_folds:
        assert not tiny_folds, f"{obj.name} contains decimation folds: {tiny_folds[:6]}"


def relaxed_hand():
    parts = [
        # The wrist curves out of the cuff and broadens through the thenar pads.
        ellipsoid("Relaxed_WristRear", (0.0, -0.078, 0.064), (0.031, 0.031, 0.022), SKIN),
        ellipsoid("Relaxed_Wrist", (0.0, -0.050, 0.046), (0.036, 0.037, 0.025), SKIN),
        ellipsoid("Relaxed_PalmHeel", (0.0, -0.012, 0.029), (0.050, 0.055, 0.026), SKIN),
        ellipsoid("Relaxed_Palm", (0.0, 0.035, 0.024), (0.053, 0.054, 0.025), SKIN),
        ellipsoid("Relaxed_KnucklePlane", (0.0, 0.069, 0.021), (0.050, 0.033, 0.023), SKIN),
        ellipsoid("Relaxed_Thenar", (-0.033, 0.004, 0.034), (0.027, 0.042, 0.025), SKIN),
    ]

    xs = (-0.036, -0.012, 0.013, 0.036)
    lengths = (0.074, 0.103, 0.094, 0.069)
    radii = (0.0130, 0.0144, 0.0138, 0.0118)
    for index, (x, length, root_radius) in enumerate(zip(xs, lengths, radii)):
        root_y = 0.061 + (0.003 if index in (1, 2) else 0.0)
        points = [
            (x, root_y, 0.024),
            (x, root_y + length * 0.36, 0.021),
            (x, root_y + length * 0.70, 0.013),
            (x, root_y + length * 0.94, 0.003),
            (x, root_y + length, -0.004),
        ]
        rs = (root_radius, root_radius * 0.94, root_radius * 0.83, root_radius * 0.72, root_radius * 0.56)
        parts.extend(tapered_chain(f"Relaxed_Finger_{index}", points, rs, 0.76, SKIN))
        # A small root pad and web close every finger-to-palm gap after remeshing.
        parts.append(ellipsoid(f"Relaxed_Web_{index}", (x, root_y - 0.004, 0.020), (root_radius * 1.15, 0.020, 0.016), SKIN))

    thumb = [
        (-0.034, -0.002, 0.036),
        (-0.058, 0.016, 0.027),
        (-0.075, 0.041, 0.010),
        (-0.077, 0.062, -0.008),
    ]
    parts.extend(tapered_chain("Relaxed_Thumb", thumb, (0.020, 0.018, 0.014, 0.009), 0.82, SKIN))
    hand = join_voxel_smooth(parts, "RelaxedHand", SKIN)

    nails = []
    for index, (x, length, root_radius) in enumerate(zip(xs, lengths, radii)):
        y = 0.061 + (0.003 if index in (1, 2) else 0.0) + length * 0.935
        surface_z = 0.003 - root_radius * 0.72 * 0.76
        nails.append(ellipsoid(f"Relaxed_Nail_{index}", (x, y, surface_z + 0.00025), (root_radius * 0.32, root_radius * 0.48, 0.00065), NAIL, 14, 8))
    nails.append(ellipsoid("Relaxed_ThumbNail", (-0.078, 0.057, -0.0151), (0.0035, 0.0055, 0.00065), NAIL, 14, 8))
    nail_obj = join_objects(nails, "RelaxedNails", NAIL)
    return hand, nail_obj


def grip_hand():
    parts = [
        ellipsoid("Grip_WristRear", (0.0, -0.078, 0.064), (0.031, 0.031, 0.022), SKIN),
        ellipsoid("Grip_Wrist", (0.0, -0.050, 0.050), (0.037, 0.037, 0.025), SKIN),
        ellipsoid("Grip_PalmHeel", (0.0, -0.022, 0.048), (0.049, 0.050, 0.026), SKIN),
        ellipsoid("Grip_Palm", (0.0, 0.015, 0.048), (0.052, 0.058, 0.026), SKIN),
        ellipsoid("Grip_KnucklePlane", (0.015, 0.040, 0.046), (0.043, 0.044, 0.025), SKIN),
        ellipsoid("Grip_Thenar", (-0.030, 0.027, 0.048), (0.028, 0.040, 0.026), SKIN),
    ]
    ys = (0.054, 0.025, -0.006, -0.035)
    radii = (0.0132, 0.0145, 0.0138, 0.0118)
    for index, (y, root_radius) in enumerate(zip(ys, radii)):
        # Inner surfaces stay just outside a radius-.025 shaft around the Y axis.
        points = [
            (0.034, y, 0.046),
            (0.048, y, 0.035),
            (0.054, y, 0.006),
            (0.044, y, -0.027),
            (0.018, y, -0.043),
            (-0.009, y, -0.034),
        ]
        rs = (root_radius, root_radius * 0.92, root_radius * 0.85, root_radius * 0.78, root_radius * 0.65, root_radius * 0.47)
        parts.extend(tapered_chain(f"Grip_Finger_{index}", points, rs, 0.82, SKIN))
        parts.append(ellipsoid(f"Grip_Web_{index}", (0.027, y, 0.045), (0.024, root_radius * 1.07, 0.018), SKIN))

    thumb = [
        (-0.033, 0.036, 0.052),
        (-0.047, 0.060, 0.036),
        (-0.038, 0.072, 0.008),
        (-0.014, 0.066, -0.019),
        (0.008, 0.056, -0.027),
    ]
    parts.extend(tapered_chain("Grip_Thumb", thumb, (0.020, 0.018, 0.015, 0.012, 0.008), 0.84, SKIN))
    hand = join_voxel_smooth(parts, "GripHand", SKIN)

    nails = []
    for index, (y, root_radius) in enumerate(zip(ys, radii)):
        surface_z = -0.034 - root_radius * 0.47 * 0.82
        nail = ellipsoid(f"Grip_Nail_{index}", (-0.009, y, surface_z + 0.00025), (root_radius * 0.30, root_radius * 0.44, 0.00065), NAIL, 14, 8)
        nail.rotation_euler.z = 0.26
        bpy.context.view_layer.objects.active = nail
        bpy.ops.object.transform_apply(location=False, rotation=True, scale=False)
        nails.append(nail)
    thumb_nail = ellipsoid("Grip_ThumbNail", (0.008, 0.056, -0.0334), (0.0034, 0.0052, 0.00065), NAIL, 14, 8)
    thumb_nail.rotation_euler.z = -0.28
    bpy.context.view_layer.objects.active = thumb_nail
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=False)
    nails.append(thumb_nail)
    nail_obj = join_objects(nails, "GripNails", NAIL)
    return hand, nail_obj


def join_objects(parts, name, mat):
    bpy.ops.object.select_all(action="DESELECT")
    for part in parts:
        part.select_set(True)
    bpy.context.view_layer.objects.active = parts[0]
    bpy.ops.object.join()
    result = bpy.context.object
    result.name = name
    result.data.materials.clear()
    result.data.materials.append(mat)
    for polygon in result.data.polygons:
        polygon.use_smooth = True
    return result


def sleeve_and_cuff():
    sleeve_parts = []
    # The rig places the cuff at the wrist, then aims/scales local +Z to its
    # camera-space elbow target.  Slight offsets create cloth folds without
    # weakening that simple 0.50-unit fitting axis.
    path = [(0.0, 0.0, 0.0), (0.006, 0.002, 0.16), (-0.005, -0.003, 0.33), (0.0, 0.0, 0.50)]
    radii = (0.044, 0.048, 0.054, 0.058)
    sleeve_parts.extend(tapered_chain("Sleeve", path, radii, 0.92, CLOTH))
    sleeve = join_voxel_smooth(sleeve_parts, "ArmSleeve", CLOTH, voxel=0.0040, decimate=0.22)

    cuff_parts = [
        ellipsoid("CuffBody", (0.0, 0.0, 0.006), (0.054, 0.052, 0.025), CUFF),
        ellipsoid("CuffFold", (0.0, 0.0, -0.008), (0.058, 0.056, 0.014), CUFF),
    ]
    cuff = join_voxel_smooth(cuff_parts, "Cuff", CUFF, voxel=0.0036, decimate=0.36)
    return sleeve, cuff


def organize(objects, collection_name):
    collection = bpy.data.collections.new(collection_name)
    bpy.context.scene.collection.children.link(collection)
    for obj in objects:
        for owner in list(obj.users_collection):
            owner.objects.unlink(obj)
        collection.objects.link(obj)


def point_camera(camera, target):
    camera.rotation_euler = (bvec(target) - camera.location).to_track_quat("-Z", "Y").to_euler()


def render_previews():
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_WORKBENCH"
    scene.render.resolution_x = 900
    scene.render.resolution_y = 900
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.display.shading.light = "STUDIO"
    scene.display.shading.color_type = "MATERIAL"
    scene.display.shading.show_shadows = True
    scene.display.shading.show_cavity = True
    scene.display.shading.cavity_type = "BOTH"
    scene.display.shading.curvature_ridge_factor = 1.7
    scene.display.shading.curvature_valley_factor = 1.4
    scene.display.shading.background_type = "VIEWPORT"
    scene.display.shading.background_color = (0.025, 0.035, 0.050)

    camera_data = bpy.data.cameras.new("PreviewCamera")
    camera = bpy.data.objects.new("PreviewCamera", camera_data)
    bpy.context.scene.collection.objects.link(camera)
    camera_data.lens = 58
    camera.location = bvec((0.35, 0.13, -0.52))
    point_camera(camera, (0.0, 0.020, 0.018))
    scene.camera = camera

    preview_dir = HERE / "previews"
    preview_dir.mkdir(parents=True, exist_ok=True)
    arm_collection = bpy.data.collections["Arm"]
    arm_collection.hide_render = True
    for collection_name, file_name in [
        ("RelaxedPose", "relaxed-hand-closeup.png"),
        ("GripPose", "grip-hand-closeup.png"),
    ]:
        bpy.data.collections["RelaxedPose"].hide_render = collection_name != "RelaxedPose"
        bpy.data.collections["GripPose"].hide_render = collection_name != "GripPose"
        shaft = None
        if collection_name == "GripPose":
            wood = material("PreviewShaft", (0.23, 0.10, 0.035), 0.72)
            shaft = cylinder_between("PreviewShaft", (0.0, -0.11, 0.0), (0.0, 0.12, 0.0), 0.025, wood, 18)
        scene.render.filepath = str(preview_dir / file_name)
        bpy.ops.render.render(write_still=True)
        if shaft is not None:
            bpy.data.objects.remove(shaft, do_unlink=True)
    print(f"WROTE {preview_dir}")


def main():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for collection in list(bpy.data.collections):
        if collection.name != "Collection":
            bpy.data.collections.remove(collection)

    relaxed = relaxed_hand()
    grip = grip_hand()
    sleeve = sleeve_and_cuff()
    repair_tiny_folds(relaxed[0])
    repair_tiny_folds(grip[0])
    validate_surface(relaxed[0], require_single_manifold=True, reject_tiny_folds=True)
    validate_surface(grip[0], require_single_manifold=True, reject_tiny_folds=True)
    validate_surface(sleeve[0], require_single_manifold=True)
    validate_surface(sleeve[1], require_single_manifold=True)
    organize(relaxed, "RelaxedPose")
    organize(grip, "GripPose")
    organize(sleeve, "Arm")

    GLB_PATH.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(BLEND_PATH))
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.export_scene.gltf(
        filepath=str(GLB_PATH),
        export_format="GLB",
        use_selection=True,
        export_apply=True,
        export_yup=True,
        export_materials="EXPORT",
    )
    render_previews()

    for obj in sorted(bpy.context.scene.objects, key=lambda item: item.name):
        if obj.type == "MESH":
            obj.data.calc_loop_triangles()
            print(f"ASSET {obj.name}: {len(obj.data.loop_triangles)} triangles")
    print(f"WROTE {BLEND_PATH}")
    print(f"WROTE {GLB_PATH}")


if __name__ == "__main__":
    main()
