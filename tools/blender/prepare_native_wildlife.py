"""Prepare the three native-textured Rodin wildlife sculpts for Godot.

Run with Blender 5.2.1:
  blender --background --factory-startup --python-exit-code 1 \
    --python tools/blender/prepare_native_wildlife.py

An optional argument after ``--`` limits the build to boar, deer, or wolf. The
pipeline preserves source polygons, UV loops, and PBR pixels. It only applies a
uniform scale/ground offset, welds coincident UV-split positions before assigning
weights, adds a measured prototype skeleton, and exports the original material.
"""
from __future__ import annotations

import hashlib
import json
import math
import sys
from pathlib import Path

import bpy
import numpy as np
from mathutils import Vector


ROOT = Path(__file__).resolve().parents[2]
SOURCE_ROOT = ROOT / "art/blender/creature_rodin_refresh"
ASSET_ROOT = ROOT / "assets/creatures"
GENERATIONS = ROOT / "docs/art/creature-rodin-refresh/generations.json"


CONFIGS = {
    "boar": {
        "slug": "bristleback",
        "display": "Bristleback",
        "height": 1.20,
        "body_radius": 0.34,
        "leg_radius": 0.105,
        "leg_attach": 0.72,
        "front_split": 0.02,
        "head_force_y": -0.50,
        "head_force_z": 0.48,
        "tail_force_y": 0.67,
        "tail_force_z": 0.48,
        "tail_half_width": 0.14,
        "points": {
            "Root": (0, 0.28, 0.74), "Spine": (0, 0.02, 0.80),
            "Chest": (0, -0.28, 0.82), "Neck": (0, -0.47, 0.77),
            "Head": (0, -0.64, 0.69), "Muzzle": (0, -0.91, 0.57),
            "TailBase": (0, 0.67, 0.75), "TailTip": (0, 0.91, 0.70),
            "FrontUpper": (0.22, -0.34, 0.75), "FrontLower": (0.22, -0.36, 0.40),
            "FrontPaw": (0.22, -0.37, 0.10), "FrontToe": (0.22, -0.46, 0.035),
            "HindUpper": (0.22, 0.39, 0.72), "HindLower": (0.23, 0.42, 0.40),
            "HindPaw": (0.23, 0.43, 0.11), "HindToe": (0.23, 0.34, 0.035),
        },
        "states": ["idle", "approach", "return", "warn", "charge", "recover"],
    },
    "deer": {
        "slug": "meadow_buck",
        "display": "Meadow Buck",
        "height": 2.00,
        "body_radius": 0.39,
        "leg_radius": 0.105,
        "leg_attach": 1.25,
        "front_split": 0.0,
        "head_force_y": -0.29,
        "head_force_z": 1.31,
        "rigid_antler_z": 1.43,
        "tail_force_y": 0.38,
        "tail_force_z": 0.88,
        "tail_half_width": 0.22,
        "points": {
            "Root": (0, 0.18, 1.15), "Spine": (0, 0.04, 1.21),
            "Chest": (0, -0.17, 1.27), "Neck": (0, -0.30, 1.42),
            "Head": (0, -0.39, 1.61), "Muzzle": (0, -0.51, 1.47),
            "TailBase": (0, 0.39, 1.21), "TailTip": (0, 0.51, 1.08),
            "FrontUpper": (0.31, -0.22, 1.26), "FrontLower": (0.31, -0.23, 0.71),
            "FrontPaw": (0.31, -0.23, 0.17), "FrontToe": (0.31, -0.29, 0.035),
            "HindUpper": (0.31, 0.25, 1.18), "HindLower": (0.31, 0.16, 0.70),
            "HindPaw": (0.31, 0.27, 0.29), "HindToe": (0.31, 0.20, 0.035),
        },
        "states": ["idle", "walk", "trot", "alert", "flee"],
    },
    "wolf": {
        "slug": "hollow_wolf",
        "display": "Hollow Wolf",
        "height": 1.25,
        "body_radius": 0.30,
        "leg_radius": 0.09,
        "leg_attach": 0.78,
        "front_split": 0.0,
        "head_force_y": -0.52,
        "head_force_z": 0.60,
        "tail_force_y": 0.58,
        "tail_force_z": 0.17,
        "tail_half_width": 0.13,
        "points": {
            "Root": (0, 0.24, 0.73), "Spine": (0, 0.02, 0.79),
            "Chest": (0, -0.28, 0.84), "Neck": (0, -0.49, 0.90),
            "Head": (0, -0.68, 0.88), "Muzzle": (0, -0.92, 0.73),
            "TailBase": (0, 0.58, 0.72), "TailTip": (0, 0.91, 0.36),
            "FrontUpper": (0.16, -0.35, 0.80), "FrontLower": (0.16, -0.38, 0.45),
            "FrontPaw": (0.16, -0.39, 0.12), "FrontToe": (0.16, -0.50, 0.035),
            "HindUpper": (0.16, 0.35, 0.73), "HindLower": (0.17, 0.26, 0.43),
            "HindPaw": (0.17, 0.42, 0.15), "HindToe": (0.17, 0.34, 0.035),
        },
        "states": ["idle", "walk", "trot", "alert", "flee"],
    },
}


def segment_distance(points: np.ndarray, start: np.ndarray, end: np.ndarray) -> np.ndarray:
    direction = end - start
    factor = np.clip(((points - start) @ direction) / max(float(direction @ direction), 1e-8), 0.0, 1.0)
    closest = start + factor[:, None] * direction
    return np.linalg.norm(points - closest, axis=1)


def smoothstep(edge0: float, edge1: float, values: np.ndarray) -> np.ndarray:
    factor = np.clip((values - edge0) / (edge1 - edge0), 0.0, 1.0)
    return factor * factor * (3.0 - 2.0 * factor)


def extract_native_textures(material: bpy.types.Material, slug: str) -> dict:
    ASSET_ROOT.mkdir(parents=True, exist_ok=True)
    result = {}
    for node in material.node_tree.nodes if material.use_nodes else []:
        if node.type != "TEX_IMAGE" or not node.image:
            continue
        image = node.image
        lower = image.name.lower()
        role = "normal" if "normal" in lower else "metallic_roughness" if "metal" in lower or "rough" in lower else "albedo"
        extension = ".jpg" if image.file_format in {"JPEG", "JPEG2000"} else ".png"
        # Blender's glTF importer preserves the original image identity on export;
        # Godot therefore extracts GLB stem + embedded image name. Write that exact
        # canonical sibling up front so the build contains one matching PBR set.
        destination = ASSET_ROOT / f"{slug}_{slug}_{role}{extension}"
        if image.packed_file:
            destination.write_bytes(bytes(image.packed_file.data))
        else:
            image.save_render(str(destination))
        # Godot prefixes the embedded image name with the GLB stem. Keep the
        # Blender export identity single-prefixed while archiving the exact sibling
        # file under the final double-prefixed name expected by the importer.
        image.filepath = str(ASSET_ROOT / f"{slug}_{role}{extension}")
        image.name = role
        result[role] = {"file": str(destination.relative_to(ROOT)), "size": list(image.size), "sha256": hashlib.sha256(destination.read_bytes()).hexdigest()}
    return result


def normalized_source(species: str, config: dict) -> tuple[bpy.types.Object, dict]:
    source = SOURCE_ROOT / species / "source.glb"
    if not source.exists():
        raise FileNotFoundError(source)
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.context.preferences.filepaths.save_version = 0
    bpy.ops.import_scene.gltf(filepath=str(source))
    meshes = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
    if len(meshes) != 1:
        raise RuntimeError(f"{species}: expected one mesh, found {len(meshes)}")
    mesh = meshes[0]
    bpy.context.view_layer.objects.active = mesh
    mesh.select_set(True)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    original_points = [mesh.matrix_world @ vertex.co for vertex in mesh.data.vertices]
    source_lo = np.min(np.array(original_points), axis=0)
    source_hi = np.max(np.array(original_points), axis=0)
    source_dimensions = source_hi - source_lo
    scale = config["height"] / source_dimensions[2]
    center_x = (source_lo[0] + source_hi[0]) * 0.5
    center_y = (source_lo[1] + source_hi[1]) * 0.5
    for vertex in mesh.data.vertices:
        vertex.co.x = (vertex.co.x - center_x) * scale
        vertex.co.y = (vertex.co.y - center_y) * scale
        vertex.co.z = (vertex.co.z - source_lo[2]) * scale
    mesh.name = config["display"] + " Native Mesh"
    mesh.data.name = config["display"] + " Native Geometry"
    triangles_before = sum(len(poly.vertices) - 2 for poly in mesh.data.polygons)
    vertices_before = len(mesh.data.vertices)
    # Blender stores UV per loop. Welding exact spatial duplicates gives every later
    # GLB seam split one shared set of weights without collapsing the UV islands.
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.mesh.remove_doubles(threshold=1e-6)
    bpy.ops.object.mode_set(mode="OBJECT")
    if sum(len(poly.vertices) - 2 for poly in mesh.data.polygons) != triangles_before:
        raise RuntimeError(f"{species}: seam weld changed polygon topology")
    material = mesh.data.materials[0]
    material.name = config["display"] + " Native PBR"
    textures = extract_native_textures(material, config["slug"])
    if set(textures) != {"albedo", "normal", "metallic_roughness"}:
        raise RuntimeError(f"{species}: incomplete native PBR set: {sorted(textures)}")
    return mesh, {
        "source": str(source.relative_to(ROOT)),
        "source_sha256": hashlib.sha256(source.read_bytes()).hexdigest(),
        "source_bounds": {"min": source_lo.tolist(), "max": source_hi.tolist(), "dimensions": source_dimensions.tolist()},
        "normalization_scale": float(scale),
        "height_m": config["height"],
        "triangles": triangles_before,
        "vertices_before_weld": vertices_before,
        "vertices_after_weld": len(mesh.data.vertices),
        "welded_seam_vertices": vertices_before - len(mesh.data.vertices),
        "textures": textures,
        "material": material.name,
    }


def scaled_points(config: dict) -> dict[str, np.ndarray]:
    return {name: np.array(value, dtype=float) for name, value in config["points"].items()}


def create_rig(mesh: bpy.types.Object, species: str, config: dict) -> tuple[bpy.types.Object, list[str], dict]:
    points = scaled_points(config)
    armature_data = bpy.data.armatures.new(config["display"] + " Rig")
    armature = bpy.data.objects.new(config["display"] + " Rig", armature_data)
    bpy.context.scene.collection.objects.link(armature)
    bpy.context.view_layer.objects.active = armature
    armature.select_set(True)
    bpy.ops.object.mode_set(mode="EDIT")
    definitions = [
        ("Root", "Root", "Spine", None),
        ("Spine", "Spine", "Chest", "Root"),
        ("Chest", "Chest", "Neck", "Spine"),
        ("Neck", "Neck", "Head", "Chest"),
        ("Head", "Head", "Muzzle", "Neck"),
        ("TailBase", "TailBase", "TailTip", "Root"),
        ("TailTip", "TailTip", None, "TailBase"),
    ]
    for side_name, sign in (("L", -1.0), ("R", 1.0)):
        for end_name in ("Front", "Hind"):
            definitions += [
                (f"{end_name}{side_name}Upper", end_name + "Upper", end_name + "Lower", "Chest" if end_name == "Front" else "Root"),
                (f"{end_name}{side_name}Lower", end_name + "Lower", end_name + "Paw", f"{end_name}{side_name}Upper"),
                (f"{end_name}{side_name}Paw", end_name + "Paw", end_name + "Toe", f"{end_name}{side_name}Lower"),
            ]
    bones = {}
    endpoints = {}
    for name, start_key, end_key, parent_name in definitions:
        start = points[start_key].copy()
        end = points[end_key].copy() if end_key else start + np.array((0, 0.08, -0.04))
        if name.endswith(("LUpper", "LLower", "LPaw")):
            start[0] *= -1
            end[0] *= -1
        bone = armature_data.edit_bones.new(name)
        bone.head = Vector(start)
        bone.tail = Vector(end)
        bone.parent = bones.get(parent_name)
        bone.use_connect = False
        bones[name] = bone
        endpoints[name] = (start, end)
    bpy.ops.object.mode_set(mode="OBJECT")

    vertices = np.array([vertex.co[:] for vertex in mesh.data.vertices], dtype=float)
    names = [definition[0] for definition in definitions]
    weights = np.zeros((len(vertices), len(names)), dtype=float)
    index = {name: i for i, name in enumerate(names)}
    for name in names[:7]:
        start, end = endpoints[name]
        radius = config["body_radius"] * (0.68 if name in {"Neck", "Head", "TailBase", "TailTip"} else 1.0)
        weights[:, index[name]] = np.exp(-np.square(segment_distance(vertices, start, end) / radius))

    x = vertices[:, 0]
    y = vertices[:, 1]
    z = vertices[:, 2]
    attach = config["leg_attach"]
    limb_vertical = 1.0 - smoothstep(attach - 0.18, attach + 0.12, z)
    for side_name, sign in (("L", -1.0), ("R", 1.0)):
        side_factor = smoothstep(-0.02, 0.10, x * sign)
        for end_name, front in (("Front", True), ("Hind", False)):
            longitudinal = (1.0 - smoothstep(config["front_split"] - 0.10, config["front_split"] + 0.10, y)) if front else smoothstep(config["front_split"] - 0.10, config["front_split"] + 0.10, y)
            region = limb_vertical * side_factor * longitudinal
            for suffix in ("Upper", "Lower", "Paw"):
                name = f"{end_name}{side_name}{suffix}"
                start, end = endpoints[name]
                distance = segment_distance(vertices, start, end)
                weights[:, index[name]] = np.exp(-np.square(distance / config["leg_radius"])) * region * 18.0

    # The whole skull, ears, and antlers follow Head rigidly; the neck blend remains
    # below it. Tail points receive the corresponding two-bone chain explicitly.
    head_mask = ((y < config["head_force_y"]) & (z > config["head_force_z"])) | ((y < config["head_force_y"] + 0.10) & (z > points["Neck"][2]))
    if "rigid_antler_z" in config:
        head_mask |= z > config["rigid_antler_z"]
    weights[head_mask] = 0.0
    weights[head_mask, index["Head"]] = 1.0
    tail_mask = (y > config["tail_force_y"]) & (z > config["tail_force_z"]) & (np.abs(x) < config["tail_half_width"])
    if np.any(tail_mask):
        tail_dist_base = segment_distance(vertices[tail_mask], *endpoints["TailBase"])
        tail_dist_tip = segment_distance(vertices[tail_mask], *endpoints["TailTip"])
        weights[tail_mask] = 0.0
        weights[tail_mask, index["TailBase"]] = 1.0 / np.maximum(tail_dist_base, 0.015)
        weights[tail_mask, index["TailTip"]] = 1.0 / np.maximum(tail_dist_tip, 0.015)

    # Low lateral geometry is hoof/paw anatomy even when a long muzzle happens to
    # project nearby in Y. Exclude axial controls before selecting the top weights.
    low_feet = (z < 0.25) & (np.abs(x) > 0.10)
    weights[np.ix_(low_feet, [index["Head"], index["TailBase"], index["TailTip"]])] = 0.0

    empty = weights.sum(axis=1) < 1e-8
    weights[empty, index["Root"]] = 1.0
    if weights.shape[1] > 4:
        remove = np.argsort(weights, axis=1)[:, :-4]
        np.put_along_axis(weights, remove, 0.0, axis=1)
    weights /= weights.sum(axis=1)[:, None]
    for bone_index, name in enumerate(names):
        group = mesh.vertex_groups.new(name=name)
        for vertex_index in np.flatnonzero(weights[:, bone_index] > 1e-5):
            group.add([int(vertex_index)], float(weights[vertex_index, bone_index]), "REPLACE")
    modifier = mesh.modifiers.new("Native wildlife skin", "ARMATURE")
    modifier.object = armature
    mesh.parent = armature
    armature["wildlife_species"] = species
    armature["asset_slug"] = config["slug"]
    mesh["native_pbr"] = True
    return armature, names, {name: [list(endpoints[name][0]), list(endpoints[name][1])] for name in names}


def write_asset(species: str, generations: dict) -> dict:
    config = CONFIGS[species]
    mesh, report = normalized_source(species, config)
    armature, bones, pivots = create_rig(mesh, species, config)
    generation = generations.get("jobs", {}).get(species, {})
    armature["generation_id"] = generation.get("generation_id", "")
    bpy.ops.object.select_all(action="DESELECT")
    mesh.select_set(True)
    armature.select_set(True)
    bpy.context.view_layer.objects.active = armature
    asset_path = ASSET_ROOT / f"{config['slug']}.glb"
    ASSET_ROOT.mkdir(parents=True, exist_ok=True)
    bpy.ops.export_scene.gltf(
        filepath=str(asset_path), export_format="GLB", use_selection=True,
        export_animations=False, export_skins=True, export_all_influences=False,
        export_def_bones=True, export_materials="EXPORT", export_attributes=False,
        export_yup=True, export_extras=True,
    )
    blend_path = SOURCE_ROOT / species / f"{config['slug']}.blend"
    bpy.ops.wm.save_as_mainfile(filepath=str(blend_path))
    report.update({
        "species": species,
        "display_name": config["display"],
        "generation_id": generation.get("generation_id", ""),
        "asset": str(asset_path.relative_to(ROOT)),
        "editable_blend": str(blend_path.relative_to(ROOT)),
        "asset_bytes": asset_path.stat().st_size,
        "bones": bones,
        "pivots_blender_z_up_front_minus_y": pivots,
        "godot_orientation": "+Y up, +Z forward",
        "states": config["states"],
        "shape_changes": "Uniform scale, X/Y recentering, ground offset, and coincident-position seam weld at 1e-6 m. No repaint, sculpting, remesh, or decimation; source triangles and loop UVs are preserved.",
        "prototype_limits": ["No foot IK or terrain adaptation", "Procedural runtime poses rather than authored animation clips", "Automatic regional weights favor stable seams and silhouettes over production muscle deformation"],
    })
    report_path = SOURCE_ROOT / species / "report.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n")
    print("NATIVE_WILDLIFE_READY " + json.dumps(report), flush=True)
    return report


generations = json.loads(GENERATIONS.read_text()) if GENERATIONS.exists() else {}
requested = [arg for arg in (sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []) if arg in CONFIGS]
for requested_species in requested or list(CONFIGS):
    write_asset(requested_species, generations)
