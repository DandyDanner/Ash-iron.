extends SceneTree
const Paths = preload("res://tests/test_paths.gd")
const Profile = preload("res://scripts/character_profile.gd")
const Save = preload("res://scripts/game_save.gd")
const Props = preload("res://scripts/imported_props.gd")
var failures := 0
func _initialize() -> void:
	Profile.storage_path = Paths.path("imported_props_profile.json")
	Save.storage_path = Paths.path("imported_props_save.json")
	Save.clear()
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func frames(n: int = 4) -> void:
	for i in range(n):
		await physics_frame
		await process_frame
func triangles(node: MeshInstance3D) -> int:
	var n := 0
	for surface in range(node.mesh.get_surface_count()): n += node.mesh.surface_get_arrays(surface)[Mesh.ARRAY_INDEX].size() / 3
	return n
func cavity_floor(body: MeshInstance3D) -> float:
	var highest := -10.0
	for surface in range(body.mesh.get_surface_count()):
		var arrays := body.mesh.surface_get_arrays(surface)
		var points: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		for i in range(0, indices.size(), 3):
			var hit = Geometry3D.ray_intersects_triangle(Vector3(0, 1, 0), Vector3.DOWN, points[indices[i]], points[indices[i+1]], points[indices[i+2]])
			if hit != null: highest = maxf(highest, hit.y)
	return highest
func run() -> void:
	change_scene_to_file("res://scenes/main.tscn")
	await scene_changed
	var player: Node3D = current_scene.get_node("Player")
	player._capture_controls(false)
	await frames()
	var tree: Node3D = current_scene.get_node("PracticePine")
	var near: MeshInstance3D = tree.find_child("PineNear", true, false)
	var far: MeshInstance3D = tree.find_child("PineFar", true, false)
	check(near != null and far != null, "Harvest tree did not receive imported near/far meshes")
	check(triangles(near) <= 8100 and triangles(far) <= 1500, "Tree exceeds its repeated-forest geometry budget")
	check(near.visibility_range_end == far.visibility_range_begin and near.visibility_range_end > 0, "Tree distance ranges leave a gap or both meshes always visible")
	check(near.get_active_material(0).albedo_texture != null, "Tree lost supplied color texture")
	var chest := preload("res://scripts/storage_chest.gd").new()
	current_scene.add_child(chest)
	chest.position = Vector3(12, .2, 12)
	chest.storage.add("copper_ore", 3)
	var body: MeshInstance3D = chest.find_child("ChestBody", true, false)
	check(chest.lid != null and body != null and chest.lid != body, "Chest does not have a separate imported lid")
	var floor_height := cavity_floor(body)
	check(floor_height > .04 and floor_height < .15, "Open chest has a solid cap or missing interior floor: %s" % floor_height)
	var pivot: Vector3 = chest.lid.global_position
	var tip: Vector3 = chest.lid.to_global(Vector3(0, .04, .55))
	chest.set_open(true)
	await frames(22)
	check(chest.lid.to_global(Vector3(0, .04, .55)).y > tip.y + .4 and chest.lid.global_position.distance_to(pivot) < .001, "Lid does not lift around a fixed rear hinge")
	chest.set_open(false)
	await frames(22)
	check(absf(chest.lid.rotation.x) < .001 and chest.storage.count("copper_ore") == 3, "Closing the new lid changed contents or left it open")
	var materials: Array = []
	for kind in ["stone", "copper_ore", "iron_ore"]:
		var rock := Props.rock(current_scene, Vector3.ONE, kind)
		var mesh: MeshInstance3D = rock.find_child("RockNear", true, false)
		check(triangles(mesh) <= 6100, "Rock exceeds gameplay geometry budget")
		var material: ShaderMaterial = mesh.material_override
		check(material.get_shader_parameter("surface_texture") != null and material.get_shader_parameter("normal_texture") != null, "Rock palette discarded its detail textures")
		materials.append(material)
		rock.queue_free()
	check(materials[0] != materials[1] and materials[1] != materials[2], "Ore variants share a mutable palette")
	check(materials[0].get_shader_parameter("mineral_amount") == 0.0 and materials[1].get_shader_parameter("mineral_color") != materials[2].get_shader_parameter("mineral_color"), "Stone and metal seams are not visually differentiated")
	# New art follows the existing depleted state and does not respawn or duplicate resources.
	tree.restore(0)
	var rock: Node3D = current_scene.get_node("Rock1")
	rock.restore(0)
	var vein: Node3D = current_scene.get_node("IronVein1")
	vein.restore(0)
	await frames()
	check(not is_instance_valid(tree.crown) and rock.collision.disabled and vein.collision.disabled, "Imported art broke depleted resource states")
	check(current_scene.save_game() == OK, "New prop visuals broke saving")
	change_scene_to_file("res://scenes/main.tscn")
	await scene_changed
	await frames()
	check(current_scene.get_node("PracticePine").hits_left == 0 and current_scene.get_node("Rock1").hits_left == 0 and current_scene.get_node("IronVein1").hits_left == 0, "Reload restored harvested props")
	var restored := get_nodes_in_group("chests")
	check(restored.size() == 1 and restored[0].storage.count("copper_ore") == 3 and restored[0].lid != null, "Reload lost chest contents or its imported lid")
	Save.clear()
	print("IMPORTED PROPS: " + ("PASS" if failures == 0 else "FAIL"))
	quit(1 if failures else 0)
