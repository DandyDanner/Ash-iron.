"""Prepare Rodin workbench and bloomery sources as native Godot station assets.

Run with Blender 5.2.1:
  blender --background --factory-startup --python tools/blender/prepare_native_stations.py

Optional station names after ``--`` limit the build to ``workbench`` or ``furnace``.
The parent task owns each immutable ``source.glb``. This script preserves exterior mesh
topology and UVs, removes the furnace's bounded baked-fire cluster, scales native
PBR images to at most 2K, grounds the model, and
writes a packed editable .blend, gameplay .glb, texture archive, and JSON report.
"""

import bpy
import bmesh
import hashlib
import json
import sys
from pathlib import Path

from mathutils import Matrix, Vector


ROOT = Path(__file__).resolve().parents[2]
SOURCE_ROOT = ROOT / "art" / "blender" / "equipment_rodin_refresh"
ASSET_ROOT = ROOT / "assets" / "props"
CONFIGS = {
    "workbench": {
        "display": "Native Timber Workbench",
        "target_width": 1.65,
        "max_depth": 0.90,
        "max_height": 1.10,
    },
    "furnace": {
        "display": "Native Clay Stone Bloomery",
        "target_height": 1.22,
        "max_footprint": 0.96,
    },
}


def triangles(meshes: list[bpy.types.Object]) -> int:
    return sum(len(poly.vertices) - 2 for obj in meshes for poly in obj.data.polygons)


def upstream_image(socket: bpy.types.NodeSocket) -> bpy.types.Image | None:
    """Find the image feeding a Principled socket through mapping/separator nodes."""
    pending = [link.from_node for link in socket.links]
    visited = set()
    while pending:
        node = pending.pop(0)
        if node.as_pointer() in visited:
            continue
        visited.add(node.as_pointer())
        if node.type == "TEX_IMAGE" and node.image:
            return node.image
        for input_socket in node.inputs:
            pending.extend(link.from_node for link in input_socket.links)
    return None


def material_images(material: bpy.types.Material) -> dict[str, bpy.types.Image]:
    if not material or not material.use_nodes:
        return {}
    principled = next((node for node in material.node_tree.nodes if node.type == "BSDF_PRINCIPLED"), None)
    if principled is None:
        return {}
    images = {}
    for role, socket_name in (
        ("albedo", "Base Color"),
        ("normal", "Normal"),
        ("metallic_roughness", "Roughness"),
    ):
        image = upstream_image(principled.inputs[socket_name])
        if image:
            images[role] = image
    if "metallic_roughness" not in images:
        image = upstream_image(principled.inputs["Metallic"])
        if image:
            images["metallic_roughness"] = image
    return images


def source_points(meshes: list[bpy.types.Object]) -> list[Vector]:
    return [obj.matrix_world @ vertex.co for obj in meshes for vertex in obj.data.vertices]


def bounds(points: list[Vector]) -> tuple[Vector, Vector]:
    return (
        Vector(tuple(min(point[axis] for point in points) for axis in range(3))),
        Vector(tuple(max(point[axis] for point in points) for axis in range(3))),
    )


def orient_workbench(points: list[Vector]) -> tuple[list[Vector], Matrix, str]:
    lo, hi = bounds(points)
    if hi.x - lo.x >= hi.y - lo.y:
        return points, Matrix.Identity(4), "source X retained as width"
    # Rotate -90 degrees around Z so the longest horizontal dimension is gameplay X.
    orientation = Matrix.Rotation(-1.5707963267948966, 4, "Z")
    return [orientation @ point for point in points], orientation, "source Y rotated to gameplay width"


def normalization(station: str, points: list[Vector]) -> tuple[Matrix, float, dict]:
    config = CONFIGS[station]
    orientation = "source axes retained"
    orientation_matrix = Matrix.Identity(4)
    if station == "workbench":
        points, orientation_matrix, orientation = orient_workbench(points)
    lo, hi = bounds(points)
    dimensions = hi - lo
    if min(dimensions) <= 0.0:
        raise RuntimeError(f"{station}: source has a zero-size axis: {tuple(dimensions)}")
    if station == "workbench":
        scale = min(
            config["target_width"] / dimensions.x,
            config["max_depth"] / dimensions.y,
            config["max_height"] / dimensions.z,
        )
    else:
        scale = min(
            config["target_height"] / dimensions.z,
            config["max_footprint"] / max(dimensions.x, dimensions.y),
        )
    center = Vector(((lo.x + hi.x) * 0.5, (lo.y + hi.y) * 0.5, lo.z))
    result = [(point - center) * scale for point in points]
    result_lo, result_hi = bounds(result)
    transform = Matrix.Scale(scale, 4) @ Matrix.Translation(-center) @ orientation_matrix
    return transform, scale, {
        "orientation": orientation,
        "source_bounds": {"min": list(lo), "max": list(hi), "dimensions": list(dimensions)},
        "game_bounds_blender_z_up": {"min": list(result_lo), "max": list(result_hi), "dimensions": list(result_hi - result_lo)},
    }


def clean_fixed_furnace_fire(meshes: list[bpy.types.Object]) -> tuple[int, int]:
    """Remove the bounded baked fire cluster and finish the cavity as cold refractory."""
    removed_triangles = 0
    for obj in list(meshes):
        bm = bmesh.new()
        bm.from_mesh(obj.data)
        faces = []
        for face in bm.faces:
            center = face.calc_center_median()
            if abs(center.x) < 0.19 and -0.24 < center.y < 0.18 and 0.55 < center.z < 0.86:
                faces.append(face)
                removed_triangles += len(face.verts) - 2
        bmesh.ops.delete(bm, geom=faces, context="FACES_ONLY")
        bm.to_mesh(obj.data)
        bm.free()
        obj.data.update()
    if removed_triangles == 0:
        raise RuntimeError("furnace: bounded generated fire cleanup selected no faces")
    charcoal = bpy.data.materials.new("Cold charcoal chamber")
    charcoal.use_nodes = True
    principled = charcoal.node_tree.nodes.get("Principled BSDF")
    principled.inputs["Base Color"].default_value = (0.018, 0.010, 0.006, 1.0)
    principled.inputs["Metallic"].default_value = 0.0
    principled.inputs["Roughness"].default_value = 1.0
    added_triangles = 0
    for name, location, dimensions in (
        ("Upper chamber refractory back", (0.0, -0.13, 0.70), (0.30, 0.025, 0.28)),
        ("Upper chamber cold cap", (0.0, -0.01, 0.835), (0.28, 0.30, 0.025)),
    ):
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=location)
        baffle = bpy.context.object
        baffle.name = name
        baffle.dimensions = dimensions
        bpy.context.view_layer.objects.active = baffle
        bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
        baffle.data.materials.append(charcoal)
        meshes.append(baffle)
        added_triangles += triangles([baffle])
    return removed_triangles, added_triangles


def archive_images(station: str, meshes: list[bpy.types.Object]) -> dict:
    ASSET_ROOT.mkdir(parents=True, exist_ok=True)
    found = {}
    material_index = 0
    for obj in meshes:
        for material in obj.data.materials:
            roles = material_images(material)
            if not roles:
                continue
            material.name = f"{CONFIGS[station]['display']} Native PBR {material_index + 1}"
            for role, image in roles.items():
                key = role if role not in found else f"{role}_{material_index + 1}"
                if max(image.size) > 2048:
                    factor = 2048.0 / max(image.size)
                    image.scale(max(1, round(image.size[0] * factor)), max(1, round(image.size[1] * factor)))
                # Godot prefixes embedded GLB images with the GLB basename.
                # Archive that exact sibling here, then keep the embedded image
                # identity short so an editor import reuses this one PBR set.
                destination = ASSET_ROOT / f"{station}_{key}.png"
                image.filepath_raw = str(destination)
                image.file_format = "PNG"
                image.save()
                image.pack()
                image.filepath = f"//{key}.png"
                image.name = key
                found[key] = {
                    "file": str(destination.relative_to(ROOT)),
                    "size": list(image.size),
                    "sha256": hashlib.sha256(destination.read_bytes()).hexdigest(),
                }
            material_index += 1
    required = {"albedo", "normal", "metallic_roughness"}
    if not required.issubset(found):
        raise RuntimeError(f"{station}: native PBR set incomplete, found {sorted(found)}")
    return found


def prepare(station: str) -> dict:
    config = CONFIGS[station]
    source = SOURCE_ROOT / station / "source.glb"
    if not source.exists():
        raise FileNotFoundError(source)
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.context.preferences.filepaths.save_version = 0
    bpy.ops.import_scene.gltf(filepath=str(source))
    meshes = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
    if not meshes:
        raise RuntimeError(f"{station}: source contains no meshes")
    before_triangles = triangles(meshes)
    before_vertices = sum(len(obj.data.vertices) for obj in meshes)
    source_meshes = list(meshes)
    original_points = source_points(meshes)
    normalize, scale, spatial = normalization(station, original_points)
    for mesh_index, obj in enumerate(meshes):
        # Baking the full source transform together with normalization preserves
        # authored vertex normals while moving every mesh into one station space.
        obj.data.transform(normalize @ obj.matrix_world)
        obj.matrix_world = Matrix.Identity(4)
        obj.name = f"{config['display']} Mesh {mesh_index + 1}"
        obj.data.name = f"{config['display']} Geometry {mesh_index + 1}"
        obj.data.validate(clean_customdata=False)
        obj.data.update()
    removed_fire_triangles, added_baffle_triangles = clean_fixed_furnace_fire(meshes) if station == "furnace" else (0, 0)
    textures = archive_images(station, meshes)
    if triangles(source_meshes) != before_triangles - removed_fire_triangles:
        raise RuntimeError(f"{station}: topology changed during normalization")
    root = bpy.data.objects.new(config["display"], None)
    bpy.context.scene.collection.objects.link(root)
    root["native_pbr"] = True
    root["station"] = station
    for obj in meshes:
        obj.parent = root
    # Remove generated source lights/cameras/empties without touching the prepared meshes.
    for obj in list(bpy.context.scene.objects):
        if obj != root and obj not in meshes:
            bpy.data.objects.remove(obj, do_unlink=True)
    SOURCE_ROOT.joinpath(station).mkdir(parents=True, exist_ok=True)
    ASSET_ROOT.mkdir(parents=True, exist_ok=True)
    blend_path = SOURCE_ROOT / station / f"{station}.blend"
    asset_path = ASSET_ROOT / f"{station}.glb"
    bpy.ops.wm.save_as_mainfile(filepath=str(blend_path))
    bpy.ops.object.select_all(action="DESELECT")
    root.select_set(True)
    for obj in meshes:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = root
    bpy.ops.export_scene.gltf(
        filepath=str(asset_path),
        export_format="GLB",
        use_selection=True,
        export_animations=False,
        export_materials="EXPORT",
        export_yup=True,
        export_extras=True,
    )
    report = {
        "station": station,
        "display_name": config["display"],
        "source": str(source.relative_to(ROOT)),
        "source_sha256": hashlib.sha256(source.read_bytes()).hexdigest(),
        "source_bytes": source.stat().st_size,
        "asset": str(asset_path.relative_to(ROOT)),
        "asset_bytes": asset_path.stat().st_size,
        "editable_blend": str(blend_path.relative_to(ROOT)),
        "mesh_count": len(meshes),
        "triangles": before_triangles,
        "game_triangles": triangles(meshes),
        "vertices": before_vertices,
        "normalization_scale": scale,
        **spatial,
        "textures": textures,
        "removed_fixed_fire_triangles": removed_fire_triangles,
        "added_charcoal_baffle_triangles": added_baffle_triangles,
        "godot_orientation": "+Y up, +Z forward",
        "shape_changes": (
            "Uniform scale, horizontal recentering, and ground offset. The bounded generated upper fire cluster was removed and two 12-triangle matte charcoal baffles finish that cavity as cold refractory; the native exterior topology, UVs, and PBR atlas are unchanged. No repaint, remesh, weld, or decimation."
            if added_baffle_triangles
            else "Uniform scale, horizontal recentering, ground offset, and optional quarter-turn only. Source topology and UVs are unchanged; no sculpt, repaint, remesh, weld, or decimation."
        ),
        "runtime_contract": "Gameplay body retains its existing collision, interaction, placement, persistence, and crafting/smelting logic. Copper kit and furnace fire remain runtime overlays.",
    }
    report_path = SOURCE_ROOT / station / "report.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n")
    print("NATIVE_STATION_READY " + json.dumps(report), flush=True)
    return report


requested = [arg for arg in (sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []) if arg in CONFIGS]
for station_name in requested or list(CONFIGS):
    prepare(station_name)
