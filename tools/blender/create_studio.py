"""Create a reference/modeling workspace from our existing Godot prototypes.
Run with Blender --background --factory-startup --python this_file.py.
This creates a baseline comparison file, not a new sculpt or game replacement.
"""
from pathlib import Path
import math
import sys
import bpy
from mathutils import Vector

REPO = Path(__file__).resolve().parents[2]
OUTPUT = REPO / 'art' / 'blender'
OUTPUT.mkdir(parents=True, exist_ok=True)
if (OUTPUT / "ash_iron_character_studio.blend").exists() and "--replace-baseline" not in sys.argv:
    raise SystemExit("Studio already exists. Preserve manual edits; use --replace-baseline only to rebuild the generated comparison file.")
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
scene = bpy.context.scene
scene.name = 'Ash & Iron — Character Studio'
scene.unit_settings.system = 'METRIC'
scene.render.engine = 'CYCLES'
scene.cycles.samples = 24
scene.render.resolution_x = 1600
scene.render.resolution_y = 1000
scene.render.resolution_percentage = 100
scene.world.color = (0.18, 0.18, 0.18)

models = []
for name, title, x in [('willow_scout', 'Willow Scout — EXISTING PROTOTYPE', -0.95), ('bristleback', 'Bristleback — EXISTING PROTOTYPE', 1.0)]:
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=str(OUTPUT / 'baseline' / (name + '.glb')))
    imported = set(bpy.data.objects) - before
    collection = bpy.data.collections.new(title)
    scene.collection.children.link(collection)
    handle = bpy.data.objects.new(title, None)
    collection.objects.link(handle)
    for obj in imported:
        for existing in list(obj.users_collection): existing.objects.unlink(obj)
        collection.objects.link(obj)
        if obj.parent is None: obj.parent = handle
    handle.location.x = x
    handle['purpose'] = 'Baseline for comparison. Replace through deliberate modeling against the approved concept.'
    models.extend(imported)
    models.append(handle)

references = bpy.data.collections.new('APPROVED REFERENCES — toggle screen icon to show')
scene.collection.children.link(references)
for filename, title, x, width in [
    ('willow-scout-turnaround.png', 'Willow Scout — approved front / side / back', -3.9, 3.5),
    ('first-wildlife-concepts.png', 'Wildlife reference — build ONLY #1 Bristleback', 3.9, 3.5),
]:
    image = bpy.data.images.load(str(REPO / 'docs' / 'art' / filename), check_existing=True)
    image.pack()
    obj = bpy.data.objects.new(title, None)
    obj.empty_display_type = 'IMAGE'
    obj.data = image
    obj.empty_display_size = width
    obj.location = (x, 0.7, 1.4)
    obj.rotation_euler = (math.pi / 2, 0, 0)
    obj.empty_image_depth = 'BACK'
    references.objects.link(obj)
references.hide_viewport = True
references.hide_render = True

studio = bpy.data.collections.new('STUDIO — review only; never export to the game')
scene.collection.children.link(studio)

def move_to_studio(obj):
    for collection in list(obj.users_collection): collection.objects.unlink(obj)
    studio.objects.link(obj)

bpy.ops.mesh.primitive_plane_add(size=200, location=(0, 0, -0.025))
ground = bpy.context.object
ground.name = 'Neutral review floor'
move_to_studio(ground)
mat = bpy.data.materials.new('Studio warm gray')
mat.diffuse_color = (0.30, 0.28, 0.24, 1)
ground.data.materials.append(mat)
for title, location, power, size in [('Key', (-3, -4, 6), 600, 5), ('Fill', (4, -2, 3), 300, 4), ('Rim', (1, 3, 5), 500, 3)]:
    data = bpy.data.lights.new(title, 'AREA')
    data.energy = power
    data.shape = 'DISK'
    data.size = size
    light = bpy.data.objects.new(title, data)
    studio.objects.link(light)
    light.location = location
    light.rotation_euler = (Vector((0, 0, 1)) - light.location).to_track_quat('-Z', 'Y').to_euler()
camera_data = bpy.data.cameras.new('Review camera')
camera = bpy.data.objects.new('Review camera', camera_data)
studio.objects.link(camera)
camera.location = (3.6, -8, 3.5)
camera.rotation_euler = (Vector((0, 0, 1)) - camera.location).to_track_quat('-Z', 'Y').to_euler()
camera_data.type = 'ORTHO'
camera_data.ortho_scale = 4.7
scene.camera = camera

notes = bpy.data.texts.new('START HERE — Character and Boar.txt')
notes.write('''ASH & IRON — CHARACTER MODELING WORKSPACE

These are the existing procedural prototypes imported for scale and rig comparison.
They are NOT newly sculpted or finished models.

Approved image references are packed into this file. Toggle the screen icon on the
APPROVED REFERENCES collection to view them beside the characters.

Art target: faithful Willow Scout and Bristleback #1 shapes, authored textures,
and deformation suitable for animation. Keep the established outfit and identity.
Do not change the world, combat, inventory, or saves during this work.

Keep this baseline file; save new authored versions under distinct names.
Game export must exclude references, studio cameras/lights, and floor. The GLB
beside this file is only a pipeline round-trip check, not a live game asset.
''')
# Store a useful front three-quarter modeling view, with material colors.
for screen in bpy.data.screens:
    for area in screen.areas:
        if area.type == 'VIEW_3D':
            space = area.spaces.active
            space.shading.type = 'MATERIAL'
            space.shading.color_type = 'MATERIAL'
            space.shading.light = 'STUDIO'
            space.overlay.show_floor = False
            space.overlay.show_axis_x = False
            space.overlay.show_axis_y = False
            space.region_3d.view_perspective = 'ORTHO'
            space.region_3d.view_rotation = camera.rotation_euler.to_quaternion()
            space.region_3d.view_location = Vector((0, 0, 1))
            space.region_3d.view_distance = 5.6
# Export only model objects, with no scene/studio content.
bpy.ops.object.select_all(action='DESELECT')
for obj in models: obj.select_set(True)
bpy.context.view_layer.objects.active = models[0]
bpy.ops.export_scene.gltf(filepath=str(OUTPUT / 'pipeline_check.glb'), export_format='GLB', use_selection=True, export_animations=False)
bpy.ops.object.select_all(action='DESELECT')
# Hide distracting lights/camera/floor from the modeling viewport, retain for rendering.
for obj in studio.objects: obj.hide_set(True)
bpy.ops.wm.save_as_mainfile(filepath=str(OUTPUT / 'ash_iron_character_studio.blend'))
print('ASH_IRON_STUDIO_READY', len(models), 'model objects; packed references; GLB check exported')
