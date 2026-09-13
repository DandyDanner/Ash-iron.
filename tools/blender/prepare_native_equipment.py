"""Prepare Rodin weapon/tool sources as contract-compatible Godot assets.

Run with Blender 5.2.1:
  Blender --background --factory-startup --python-exit-code 1 \
    --python tools/blender/prepare_native_equipment.py

An optional list after ``--`` limits the build to one or more keys below. The
pipeline preserves source polygons, UV loops, and native normal/roughness detail.
Its documented exceptions are the arrow cleanup and a luminance-preserving
copper grade on the upgrade axe head. It also gives the bow a bend skin.
"""
from __future__ import annotations

import hashlib
import json
import math
import sys
from pathlib import Path

import bpy
import bmesh
import numpy as np
from mathutils import Vector


ROOT = Path(__file__).resolve().parents[2]
SOURCE_ROOT = ROOT / "art/blender/equipment_rodin_refresh"
ASSET_ROOT = ROOT / "assets/equipment"

# Canonical Godot contracts after glTF's Blender-Z-up to Godot-Y-up conversion:
# axes/pick point +Y with the grip at zero, spear/arrow point -Z, bow limbs run Y.
CONFIGS = {
    "stone_axe": {
        "source_dir": "stone_axe", "asset": "stone_axe", "display": "Stone Axe",
        "kind": "hafted", "length": .72, "low": -.20, "expected_triangles": 12000,
    },
    "copper_axe": {
        "source_dir": "copper_axe", "asset": "copper_axe", "display": "Copper Axe",
        "kind": "hafted", "length": .72, "low": -.20, "expected_triangles": 12000,
    },
    "stone_pickaxe": {
        "source_dir": "stone_pickaxe", "asset": "stone_pickaxe", "display": "Stone Pickaxe",
        "kind": "hafted", "length": .72, "low": -.20, "expected_triangles": 12000,
    },
    "stone_spear": {
        "source_dir": "stone_spear", "asset": "stone_spear", "display": "Stone Spear",
        "kind": "projectile_axis", "length": 1.75, "low": -.47, "expected_triangles": 12000,
    },
    "bow": {
        "source_dir": "bow", "asset": "short_bow", "display": "Short Bow",
        "kind": "bow", "length": 1.36, "low": -.68, "expected_triangles": 12000,
    },
    "arrow": {
        "source_dir": "arrow", "asset": "arrow", "display": "Arrow",
        "kind": "projectile_axis", "length": .82, "low": -.335, "expected_triangles": 4000,
    },
}


def reset() -> None:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.context.preferences.filepaths.save_version = 0


def bounds(mesh: bpy.types.Object) -> tuple[Vector, Vector]:
    points = [mesh.matrix_world @ vertex.co for vertex in mesh.data.vertices]
    return (
        Vector(tuple(min(point[i] for point in points) for i in range(3))),
        Vector(tuple(max(point[i] for point in points) for i in range(3))),
    )


def source_triangles(mesh: bpy.types.Object) -> int:
    return sum(len(poly.vertices) - 2 for poly in mesh.data.polygons)


def validate_source(mesh: bpy.types.Object, key: str, config: dict) -> dict:
    """Reject wrong Rodin subjects before they can silently replace held art."""
    lo, hi = bounds(mesh)
    size = hi - lo
    triangles = source_triangles(mesh)
    failures = []
    if triangles != config["expected_triangles"]:
        failures.append(f"expected {config['expected_triangles']} triangles, found {triangles}")
    if len(mesh.data.uv_layers) < 1:
        failures.append("missing native UV layer")
    # Every approved prompt supplies the object upright. This catches the first
    # returned stone axe (embedded in a block) and bow (a complete workbench).
    if size.z < max(size.x, size.y) * 1.35:
        failures.append(f"upright Z is not the dominant axis: dimensions {tuple(round(v, 4) for v in size)}")
    # A spear/arrow must remain a narrow shaft through its middle. This catches
    # dagger-like spears and mid-shaft crossbars while allowing the point/fletching.
    if config["kind"] == "projectile_axis" and key != "arrow":
        middle = [vertex.co for vertex in mesh.data.vertices if .32 <= (vertex.co.z - lo.z) / size.z <= .68]
        if middle:
            middle_span = max(
                max(vertex.x for vertex in middle) - min(vertex.x for vertex in middle),
                max(vertex.y for vertex in middle) - min(vertex.y for vertex in middle),
            )
            if middle_span > size.z * .055:
                failures.append(f"middle shaft is too broad: {middle_span:.4f} across {size.z:.4f} length")
    if failures:
        raise RuntimeError(f"{key}: source QA failed: {'; '.join(failures)}")
    return {
        "dimensions": list(size),
        "checks": "upright, triangle budget, UV" + (", and shaft proportions" if config["kind"] == "projectile_axis" and key != "arrow" else ""),
    }


def clean_arrow_source(mesh: bpy.types.Object) -> dict:
    """Keep the native point/shaft but remove the malformed mid-shaft crossbar."""
    bm = bmesh.new()
    bm.from_mesh(mesh.data)
    unseen = set(bm.verts)
    components = []
    while unseen:
        seed = unseen.pop()
        queue = [seed]
        vertices = [seed]
        while queue:
            vertex = queue.pop()
            for edge in vertex.link_edges:
                neighbor = edge.other_vert(vertex)
                if neighbor in unseen:
                    unseen.remove(neighbor)
                    queue.append(neighbor)
                    vertices.append(neighbor)
        components.append(vertices)
    rejected = []
    for vertices in components:
        lo_z = min(vertex.co.z for vertex in vertices)
        hi_z = max(vertex.co.z for vertex in vertices)
        span = max(
            max(vertex.co.x for vertex in vertices) - min(vertex.co.x for vertex in vertices),
            max(vertex.co.y for vertex in vertices) - min(vertex.co.y for vertex in vertices),
        )
        center_x = sum(vertex.co.x for vertex in vertices) / len(vertices)
        center_y = sum(vertex.co.y for vertex in vertices) / len(vertices)
        if lo_z > -.19 and hi_z < -.09 and (span > .025 or math.hypot(center_x, center_y) > .05):
            rejected.extend(vertices)
    removed_vertices = len(set(rejected))
    if removed_vertices < 100:
        bm.free()
        raise RuntimeError(f"arrow: malformed crossbar cleanup found only {removed_vertices} vertices")
    bmesh.ops.delete(bm, geom=list(set(rejected)), context="VERTS")
    # The generated point consumed about one quarter of the object. Compress its
    # native vertices around the shaft junction so it reads as an arrowhead.
    head_base = .43
    compressed_vertices = 0
    for vertex in bm.verts:
        if vertex.co.z > head_base:
            vertex.co.z = head_base + (vertex.co.z - head_base) * .25
            compressed_vertices += 1
    bm.to_mesh(mesh.data)
    bm.free()
    mesh.data.update()
    return {
        "removed_midshaft_crossbar_vertices": removed_vertices,
        "compressed_native_head_vertices": compressed_vertices,
        "native_head_length_scale": .25,
    }


def slenderize_arrow(mesh: bpy.types.Object) -> dict:
    """Resize the retained native shaft/head radially to credible arrow dimensions."""
    # normalize() has already put the projectile along Blender Y. The compressed
    # native point occupies its final 8.5% of length; the rest is the wood shaft.
    lo, hi = bounds(mesh)
    length = hi.y - lo.y
    head_start = hi.y - length * .085
    transition_start = head_start - length * .025
    shaft_samples = [
        vertex.co for vertex in mesh.data.vertices
        if lo.y + length * .22 <= vertex.co.y <= lo.y + length * .70
    ]
    head_samples = [vertex.co for vertex in mesh.data.vertices if vertex.co.y >= head_start]
    if not shaft_samples or not head_samples:
        raise RuntimeError("arrow: cannot measure native shaft/head cross-sections")
    shaft_radius = max(math.hypot(vertex.x, vertex.z) for vertex in shaft_samples)
    head_radius = max(math.hypot(vertex.x, vertex.z) for vertex in head_samples)
    shaft_target = .0045  # 9 mm diameter
    head_target = .018  # 36 mm maximum point width
    shaft_factor = shaft_target / shaft_radius
    head_factor = head_target / head_radius
    for vertex in mesh.data.vertices:
        if vertex.co.y <= transition_start:
            factor = shaft_factor
        elif vertex.co.y >= head_start:
            factor = head_factor
        else:
            t = (vertex.co.y - transition_start) / (head_start - transition_start)
            factor = shaft_factor + (head_factor - shaft_factor) * t
        vertex.co.x *= factor
        vertex.co.z *= factor
    mesh.data.update()
    final_head_radius = max(
        math.hypot(vertex.co.x, vertex.co.z)
        for vertex in mesh.data.vertices if vertex.co.y >= head_start
    )
    return {
        "measured_native_shaft_diameter_before_m": shaft_radius * 2,
        "final_shaft_diameter_m": shaft_target * 2,
        "measured_native_head_width_before_m": head_radius * 2,
        "final_native_head_width_m": final_head_radius * 2,
    }


def add_arrow_fletching() -> bpy.types.Object:
    """Add three compact feather planes at the butt; the projectile axis is Blender Y."""
    vertices = []
    faces = []
    for vane in range(3):
        angle = vane * 2.09439510239
        radial = Vector((math.cos(angle), 0, math.sin(angle)))
        tangent = Vector((-math.sin(angle), 0, math.cos(angle))) * .0015
        start = len(vertices)
        outline = [
            radial * .012 + Vector((0, -.31, 0)),
            radial * .032 + Vector((0, -.285, 0)),
            radial * .032 + Vector((0, -.205, 0)),
            radial * .012 + Vector((0, -.19, 0)),
        ]
        vertices.extend([point + tangent for point in outline] + [point - tangent for point in outline])
        faces.extend([
            (start, start + 1, start + 2), (start, start + 2, start + 3),
            (start + 4, start + 6, start + 5), (start + 4, start + 7, start + 6),
        ])
        for edge in range(4):
            nxt = (edge + 1) % 4
            faces.extend([
                (start + edge, start + 4 + edge, start + 4 + nxt),
                (start + edge, start + 4 + nxt, start + nxt),
            ])
    data = bpy.data.meshes.new("Compact Feather Geometry")
    data.from_pydata(vertices, [], faces)
    data.validate(clean_customdata=False)
    data.update()
    feather = bpy.data.objects.new("Compact Brown Feather Fletching", data)
    bpy.context.collection.objects.link(feather)
    material = bpy.data.materials.new("Compact Brown Feather PBR")
    material.use_nodes = True
    shader = material.node_tree.nodes.get("Principled BSDF")
    shader.inputs["Base Color"].default_value = (.18, .095, .045, 1)
    shader.inputs["Roughness"].default_value = .86
    data.materials.append(material)
    return feather


def import_mesh(source: Path, display: str) -> bpy.types.Object:
    reset()
    bpy.ops.import_scene.gltf(filepath=str(source))
    meshes = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
    if len(meshes) != 1:
        raise RuntimeError(f"{source}: expected one mesh, found {len(meshes)}")
    mesh = meshes[0]
    bpy.context.view_layer.objects.active = mesh
    mesh.select_set(True)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    mesh.name = display + " Native Mesh"
    mesh.data.name = display + " Native Geometry"
    for polygon in mesh.data.polygons:
        polygon.use_smooth = True
    return mesh


def normalize(mesh: bpy.types.Object, config: dict) -> dict:
    """Map the prompt's upright +Z model to the established local art contract."""
    before_lo, before_hi = bounds(mesh)
    source_height = before_hi.z - before_lo.z
    if source_height <= 0:
        raise RuntimeError(f"{mesh.name}: zero source height")
    scale = config["length"] / source_height

    # The lower shaft is the reliable center landmark for hafted tools. Rodin's
    # axe blade intentionally extends left, so centering the entire bbox would
    # move the handle away from the palm.
    lower_cut = before_lo.z + source_height * .55
    lower_vertices = [vertex.co for vertex in mesh.data.vertices if vertex.co.z <= lower_cut]
    if config["kind"] == "hafted" and lower_vertices:
        center_x = sum(vertex.y for vertex in lower_vertices) / len(lower_vertices)
        center_y = sum(vertex.x for vertex in lower_vertices) / len(lower_vertices)
    elif config["kind"] == "bow":
        # The leather palm grip is the local landmark. On a curved bow it lies
        # near one edge of the overall depth, so the whole-object bbox center
        # would visibly float the grip away from the player's hand.
        grip_vertices = [
            vertex.co for vertex in mesh.data.vertices
            if .46 <= (vertex.co.z - before_lo.z) / source_height <= .54
        ]
        if not grip_vertices:
            raise RuntimeError(f"{mesh.name}: no vertices found around the bow grip")
        center_x = sorted(vertex.x for vertex in grip_vertices)[len(grip_vertices) // 2]
        center_y = sorted(vertex.y for vertex in grip_vertices)[len(grip_vertices) // 2]
    else:
        center_x = (before_lo.x + before_hi.x) * .5
        center_y = (before_lo.y + before_hi.y) * .5

    for vertex in mesh.data.vertices:
        longitudinal = (vertex.co.z - before_lo.z) * scale + config["low"]
        if config["kind"] == "hafted":
            # Rodin's broadside is generated in source Y. Put the head on local
            # X so the existing first/third-person rotations keep its edge forward.
            x = -(vertex.co.y - center_x) * scale
            depth = (vertex.co.x - center_y) * scale
            vertex.co = Vector((x, depth, longitudinal))
        elif config["kind"] == "projectile_axis":
            x = (vertex.co.x - center_x) * scale
            depth = (vertex.co.y - center_y) * scale
            # Blender +Y exports as Godot -Z. The generated point is source-up.
            vertex.co = Vector((x, longitudinal, -depth))
        else:  # bow: source broadside X becomes Godot depth; source Y stays thin.
            x = (vertex.co.y - center_y) * scale
            depth = -(vertex.co.x - center_x) * scale
            vertex.co = Vector((x, depth, longitudinal))
    mesh.data.update()
    after_lo, after_hi = bounds(mesh)
    return {
        "source_bounds": {"min": list(before_lo), "max": list(before_hi)},
        "game_blender_bounds": {"min": list(after_lo), "max": list(after_hi)},
        "uniform_scale": scale,
        "cross_section_landmark_source": [center_x, center_y],
        "contract": "grip at origin; point/head follows the existing held-art local axes",
    }


def texture_role(node: bpy.types.ShaderNodeTexImage) -> str:
    label = (node.image.name + " " + node.label + " " + node.name).lower()
    if "normal" in label:
        return "normal"
    if "metal" in label or "rough" in label or "orm" in label:
        return "metallic_roughness"
    return "albedo"


def preserve_native_materials(mesh: bpy.types.Object, asset: str, display: str) -> dict:
    ASSET_ROOT.mkdir(parents=True, exist_ok=True)
    textures: dict[str, dict] = {}
    for index, material in enumerate(mesh.data.materials):
        if material is None or not material.use_nodes:
            continue
        material.name = display + " Native PBR" + (f" {index + 1}" if len(mesh.data.materials) > 1 else "")
        for node in material.node_tree.nodes:
            if node.type != "TEX_IMAGE" or node.image is None:
                continue
            image = node.image
            role = texture_role(node)
            extension = ".jpg" if image.file_format in {"JPEG", "JPEG2000"} else ".png"
            suffix = f"_{index + 1}" if len(mesh.data.materials) > 1 else ""
            destination = ASSET_ROOT / f"{asset}_{role}{suffix}{extension}"
            if image.packed_file:
                destination.write_bytes(bytes(image.packed_file.data))
            else:
                image.save_render(str(destination))
            # Keep a short embedded name. Godot prefixes it with the GLB basename
            # when extracting, yielding the clean sibling path written above.
            image.filepath = f"//{role}{suffix}{extension}"
            image.name = role + suffix
            textures[role + suffix] = {
                "file": str(destination.relative_to(ROOT)),
                "size": list(image.size),
                "sha256": hashlib.sha256(destination.read_bytes()).hexdigest(),
            }
    required = {"albedo", "normal", "metallic_roughness"}
    if len(mesh.data.materials) == 1 and set(textures) != required:
        raise RuntimeError(f"{asset}: expected native PBR roles {sorted(required)}, found {sorted(textures)}")
    return textures


def add_copper_head_finish(mesh: bpy.types.Object) -> dict:
    """Tint the broad upper blade faces while retaining every native PBR map."""
    native = mesh.data.materials[0]
    finish = native.copy()
    finish.name = "Copper Axe Head Finish"
    shader = finish.node_tree.nodes.get("Principled BSDF")
    copper_factor = (1.0, .38, .10)
    shader.inputs["Base Color"].default_value = (1, 1, 1, 1)
    metallic_input = shader.inputs.get("Metallic IOR Level") or shader.inputs.get("Metallic")
    if metallic_input is not None:
        metallic_input.default_value = .82
    head_albedo = None
    for node in finish.node_tree.nodes:
        if node.type != "TEX_IMAGE" or node.image is None or texture_role(node) != "albedo":
            continue
        source_image = node.image
        head_albedo = source_image.copy()
        head_albedo.name = "head_albedo"
        pixels = np.empty(len(source_image.pixels), dtype=np.float32)
        source_image.pixels.foreach_get(pixels)
        rgba = pixels.reshape((-1, 4))
        luminance = rgba[:, :3] @ np.array((.2126, .7152, .0722), dtype=np.float32)
        rgba[:, 0] = np.clip(luminance * copper_factor[0], 0, 1)
        rgba[:, 1] = np.clip(luminance * copper_factor[1], 0, 1)
        rgba[:, 2] = np.clip(luminance * copper_factor[2], 0, 1)
        head_albedo.pixels.foreach_set(pixels)
        destination = ASSET_ROOT / "copper_axe_head_albedo.png"
        head_albedo.filepath_raw = str(destination)
        head_albedo.file_format = "PNG"
        head_albedo.save()
        # Short embedded names make Godot extract back to the same sibling path.
        head_albedo.filepath = "//head_albedo.png"
        head_albedo.name = "head_albedo"
        node.image = head_albedo
        break
    if head_albedo is None:
        raise RuntimeError("copper_axe: native albedo node unavailable for head grade")
    mesh.data.materials.append(finish)
    changed_triangles = 0
    for polygon in mesh.data.polygons:
        center_z = sum(mesh.data.vertices[index].co.z for index in polygon.vertices) / len(polygon.vertices)
        broad = max(abs(mesh.data.vertices[index].co.x) for index in polygon.vertices) > .045
        if center_z > .32 and broad:
            polygon.material_index = 1
            changed_triangles += len(polygon.vertices) - 2
    if changed_triangles < 1000:
        raise RuntimeError(f"copper_axe: only {changed_triangles} blade triangles received copper finish")
    return {
        "copper_head_finish_triangles": changed_triangles,
        "copper_head_luminance_grade": list(copper_factor),
        "copper_head_metallic_factor": .82,
        "copper_head_albedo": "assets/equipment/copper_axe_head_albedo.png",
        "copper_head_albedo_sha256": hashlib.sha256((ASSET_ROOT / "copper_axe_head_albedo.png").read_bytes()).hexdigest(),
        "copper_head_finish": "material split above the head socket; native albedo luminance and native normal/metallic-roughness texture detail retained",
    }


def rig_bow(mesh: bpy.types.Object) -> bpy.types.Object:
    """Add a tiny runtime skin: native wood bends while the existing string remains exact."""
    bpy.ops.object.armature_add(enter_editmode=True, location=(0, 0, 0))
    armature = bpy.context.object
    armature.name = "Short Bow Bend Rig"
    armature.data.name = "Short Bow Bend Skeleton"
    root = armature.data.edit_bones[0]
    root.name = "BowRoot"
    root.head = (0, 0, -.06)
    root.tail = (0, 0, .06)
    upper = armature.data.edit_bones.new("UpperLimb")
    upper.head = (0, 0, 0)
    upper.tail = (0, 0, .68)
    upper.parent = root
    lower = armature.data.edit_bones.new("LowerLimb")
    lower.head = (0, 0, 0)
    lower.tail = (0, 0, -.68)
    lower.parent = root
    bpy.ops.object.mode_set(mode="OBJECT")

    groups = {name: mesh.vertex_groups.new(name=name) for name in ["BowRoot", "UpperLimb", "LowerLimb"]}
    for vertex in mesh.data.vertices:
        height = vertex.co.z
        blend = min(1.0, max(0.0, (abs(height) - .045) / .14))
        groups["BowRoot"].add([vertex.index], 1.0 - blend, "REPLACE")
        groups["UpperLimb" if height >= 0 else "LowerLimb"].add([vertex.index], blend, "REPLACE")
    modifier = mesh.modifiers.new("Runtime bow bend", "ARMATURE")
    modifier.object = armature
    mesh.parent = armature
    return armature


def export_one(key: str, config: dict) -> dict:
    source = SOURCE_ROOT / config["source_dir"] / "source.glb"
    if not source.exists():
        raise FileNotFoundError(source)
    mesh = import_mesh(source, config["display"])
    triangles = source_triangles(mesh)
    source_qa = validate_source(mesh, key, config)
    modifications = clean_arrow_source(mesh) if key == "arrow" else {}
    normalization = normalize(mesh, config)
    if key == "arrow":
        modifications.update(slenderize_arrow(mesh))
    textures = preserve_native_materials(mesh, config["asset"], config["display"])
    if key == "copper_axe":
        modifications.update(add_copper_head_finish(mesh))
    selected: list[bpy.types.Object] = [mesh]
    if key == "arrow":
        feather = add_arrow_fletching()
        selected.append(feather)
        modifications["added_compact_feather_triangles"] = source_triangles(feather)
    bones: list[str] = []
    if config["kind"] == "bow":
        armature = rig_bow(mesh)
        selected.append(armature)
        bones = [bone.name for bone in armature.data.bones]

    source_dir = SOURCE_ROOT / config["source_dir"]
    bpy.ops.wm.save_as_mainfile(filepath=str(source_dir / f"{config['asset']}.blend"))
    bpy.ops.object.select_all(action="DESELECT")
    for obj in selected:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = mesh
    output = ASSET_ROOT / f"{config['asset']}.glb"
    bpy.ops.export_scene.gltf(
        filepath=str(output), export_format="GLB", use_selection=True,
        export_animations=False, export_yup=True,
    )
    report = {
        "key": key,
        "source": str(source.relative_to(ROOT)),
        "source_sha256": hashlib.sha256(source.read_bytes()).hexdigest(),
        "source_bytes": source.stat().st_size,
        "source_qa": source_qa,
        "triangles": triangles,
        "expected_triangles": config["expected_triangles"],
        "game_triangles": sum(source_triangles(obj) for obj in selected if obj.type == "MESH"),
        "vertices": len(mesh.data.vertices),
        "uv_layers": len(mesh.data.uv_layers),
        "materials": [material.name for material in mesh.data.materials if material],
        "textures": textures,
        "bones": bones,
        "modifications": modifications,
        "normalization": normalization,
        "output": str(output.relative_to(ROOT)),
        "output_bytes": output.stat().st_size,
    }
    (source_dir / "report.json").write_text(json.dumps(report, indent=2) + "\n")
    return report


def main() -> None:
    keys = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else list(CONFIGS)
    unknown = set(keys) - set(CONFIGS)
    if unknown:
        raise ValueError(f"unknown equipment keys: {sorted(unknown)}")
    reports = {key: export_one(key, CONFIGS[key]) for key in keys}
    print("NATIVE_EQUIPMENT_READY", json.dumps(reports), flush=True)


if __name__ == "__main__":
    main()
