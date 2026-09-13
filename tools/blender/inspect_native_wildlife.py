"""Print source GLB geometry/material facts without modifying the source files."""
import json
import sys
from pathlib import Path

import bpy
from mathutils import Vector


def render_turnaround(path: Path, meshes: list, lo: list, hi: list) -> None:
    """Render a neutral three-quarter inspection frame beside the source GLB."""
    center = Vector(tuple((lo[i] + hi[i]) * 0.5 for i in range(3)))
    extent = max(hi[i] - lo[i] for i in range(3))
    world = bpy.context.scene.world or bpy.data.worlds.new("Inspection World")
    bpy.context.scene.world = world
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.035, 0.045, 0.06, 1)
    world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.35
    camera_data = bpy.data.cameras.new("Inspection Camera")
    camera = bpy.data.objects.new("Inspection Camera", camera_data)
    bpy.context.scene.collection.objects.link(camera)
    camera.location = center + Vector((extent * 1.25, -extent * 1.8, extent * 0.65))
    camera.rotation_euler = (center - camera.location).to_track_quat("-Z", "Y").to_euler()
    camera_data.type = "ORTHO"
    camera_data.ortho_scale = extent * 1.28
    bpy.context.scene.camera = camera
    for location, energy, size in [((2.5, -3.0, 4.0), 1300, 3.0), ((-3.0, -1.0, 2.0), 700, 2.0), ((0.0, 3.0, 3.0), 900, 2.5)]:
        data = bpy.data.lights.new("Inspection Softbox", "AREA")
        data.energy = energy
        data.shape = "DISK"
        data.size = size
        lamp = bpy.data.objects.new("Inspection Softbox", data)
        lamp.location = center + Vector(location) * extent * 0.45
        lamp.rotation_euler = (center - lamp.location).to_track_quat("-Z", "Y").to_euler()
        bpy.context.scene.collection.objects.link(lamp)
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE"
    scene.render.resolution_x = 720
    scene.render.resolution_y = 720
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.film_transparent = False
    scene.render.filepath = str(path.parent / "source-inspection.png")
    scene.view_settings.look = "AgX - Medium High Contrast"
    bpy.ops.render.render(write_still=True)


def inspect(path: Path, should_render: bool) -> dict:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(path))
    meshes = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
    world_points = [obj.matrix_world @ vertex.co for obj in meshes for vertex in obj.data.vertices]
    lo = [min(point[i] for point in world_points) for i in range(3)]
    hi = [max(point[i] for point in world_points) for i in range(3)]
    if should_render:
        render_turnaround(path, meshes, lo, hi)
    materials = []
    for material in {slot.material for obj in meshes for slot in obj.material_slots if slot.material}:
        images = []
        if material.use_nodes:
            for node in material.node_tree.nodes:
                if node.type == "TEX_IMAGE" and node.image:
                    images.append({"name": node.image.name, "size": list(node.image.size), "filepath": node.image.filepath})
        materials.append({"name": material.name, "images": images})
    return {
        "path": str(path),
        "objects": [{"name": obj.name, "vertices": len(obj.data.vertices), "polygons": len(obj.data.polygons), "dimensions": list(obj.dimensions), "location": list(obj.location), "rotation": list(obj.rotation_euler), "scale": list(obj.scale)} for obj in meshes],
        "vertices": sum(len(obj.data.vertices) for obj in meshes),
        "triangles": sum(sum(len(poly.vertices) - 2 for poly in obj.data.polygons) for obj in meshes),
        "bounds_min": lo,
        "bounds_max": hi,
        "dimensions": [hi[i] - lo[i] for i in range(3)],
        "materials": materials,
    }


args = sys.argv[sys.argv.index("--") + 1:]
should_render = "--render" in args
for source in [arg for arg in args if not arg.startswith("--")]:
    print("WILDLIFE_SOURCE " + json.dumps(inspect(Path(source), should_render)), flush=True)
