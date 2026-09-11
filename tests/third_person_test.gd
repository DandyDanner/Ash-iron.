extends SceneTree
const Paths = preload("res://tests/test_paths.gd")
const Profile = preload("res://scripts/character_profile.gd")
const GameSave = preload("res://scripts/game_save.gd")
const Pickup = preload("res://scripts/resource_pickup.gd")
var failures := 0

func _initialize() -> void:
	Profile.storage_path = Paths.path("third_person_profile_%d.json" % Time.get_ticks_usec())
	GameSave.storage_path = Paths.path("third_person_save_%d.json" % Time.get_ticks_usec())
	call_deferred("run")

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func ticks(count: int = 4) -> void:
	for i in range(count):
		await physics_frame
		await process_frame

func key(player: Node, code: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	player._unhandled_input(event)

func enter() -> Node3D:
	change_scene_to_file("res://scenes/main.tscn")
	await scene_changed
	await ticks(6)
	var player: Node3D = current_scene.get_node("Player")
	player._capture_controls(true)
	return player

func wall_at(spot: Vector3) -> StaticBody3D:
	var wall := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(3, 3, 0.25)
	collision.shape = shape
	wall.add_child(collision)
	current_scene.add_child(wall)
	wall.position = spot
	return wall

func run() -> void:
	var player := await enter()
	var rig: Node3D = player.view_rig
	check(rig.third_person and root.get_camera_3d() == rig.third_camera, "New game did not start in third person")
	check(player.inventory.is_empty() and player.inventory.slots.size() == 8 and not rig.back_bow.visible and not rig.quiver.visible, "Visual gear granted free starting equipment")
	key(player, KEY_V)
	check(not rig.third_person and root.get_camera_3d() == player.camera and player.camera.cull_mask == 3, "V did not enter first person with the correct render layers")
	key(player, KEY_V)
	player.global_position = Vector3(12, 1.1, 12)
	player.rotation = Vector3.ZERO
	player.camera.rotation = Vector3.ZERO
	await ticks(8)
	check(rig.arm.get_hit_length() > 3.5 and (rig.third_camera.cull_mask & 2) == 0, "Clear chase camera is obstructed or shows first-person hands")
	var wall := wall_at(Vector3(12, 1.6, 14))
	await ticks(8)
	check(rig.arm.get_hit_length() < 2.0 and rig.third_camera.global_position.z < 13.9, "Chase camera passed through the wall behind the player")
	wall.queue_free()
	await ticks(8)
	check(rig.arm.get_hit_length() > 3.5, "Camera did not recover after removing the wall")
	# Gathering stays measured from the player, including broad aim and occlusion.
	for pickup in get_nodes_in_group("pickups"): pickup.queue_free()
	var item := Pickup.new()
	current_scene.add_child(item)
	item.position = Vector3(14, 0.22, 10.5)
	await ticks()
	check(player._interaction_target() == item, "Third-person off-center gathering failed")
	item.position = Vector3(12, 0.22, 8.8)
	await ticks()
	check(player._interaction_target() == null, "Chase camera extended the three-meter pickup limit")
	item.position = Vector3(12, 0.22, 10)
	wall = wall_at(Vector3(12, 1.5, 11))
	await ticks()
	check(player._interaction_target() == null, "Third-person pickup reached through a wall")
	wall.queue_free()
	await ticks()
	key(player, KEY_E)
	await ticks()
	check(player.inventory.count("stick") == 2, "Third-person E did not gather the selected item")
	# Actual third-person axe contact works; distant targets remain out of reach.
	player.inventory.add("stone_axe", 1)
	player.equip_item("stone_axe")
	player.global_position = Vector3(0, 1.1, 2)
	await ticks(8)
	var pine: Node3D = current_scene.get_node("PracticePine")
	player.axe.start_swing()
	await ticks(45)
	check(pine.hits_left == 3 and rig.held.stone_axe.visible, "Third-person axe did not strike the practice pine")
	player.global_position.z = 4.5
	await ticks(8)
	player.axe.start_swing()
	await ticks(45)
	check(pine.hits_left == 3, "Third-person axe gained camera-length reach")
	# Aim from the chase crosshair, but launch at the head so close walls still block arrows.
	player.global_position = Vector3(10, 1.1, -4)
	player.camera.rotation.x = -0.055
	player.inventory.add("bow", 1)
	player.inventory.add("arrow", 5)
	player.equip_item("bow")
	await ticks(8)
	player.bow.begin_draw()
	await ticks(55)
	check(rig.held_bow.visible and not rig.back_bow.visible and rig.drawn_arrow.visible and rig.arm.spring_length < 2.4, "Bow presentation did not follow drawing/equipment")
	player.fire_bow()
	await ticks(30)
	var target: Node3D = current_scene.get_node("ClearingResources/PracticeTarget")
	check(target.hits == 1 and player.inventory.count("arrow") == 4, "Third-person shot missed the target or spent incorrect ammo")
	wall = wall_at(Vector3(10, 1.5, -5))
	await ticks()
	player.bow.begin_draw()
	await ticks(55)
	player.fire_bow()
	await ticks(25)
	check(target.hits == 1 and get_nodes_in_group("flying_arrows").is_empty(), "Third-person arrow bypassed the close obstruction")
	wall.queue_free()
	player.bow.begin_draw()
	key(player, KEY_V)
	check(not player.bow.drawing and not rig.third_person, "Changing view did not cancel the bow draw")
	# The articulated model responds to locomotion, jump, and tool gestures.
	var avatar: Node3D = rig.avatar
	var stride_peak := 0.0
	for step in range(8):
		avatar.animate_movement(0.1, 5, true, 0, "", -1, 0)
		stride_peak = maxf(stride_peak, absf(avatar.legs[0].rotation.x))
	check(stride_peak > 0.4, "Walking has no leg motion through a complete stride")
	avatar.animate_movement(0.1, 0, false, 4, "", -1, 0)
	check(avatar.knees[0].rotation.x > 0.4, "Jump pose did not bend the knees")
	avatar.animate_movement(0.1, 0, true, 0, "stone_axe", 0.22, 0)
	check(avatar.arms[1].rotation.x < -1.5, "Axe swing has no third-person gesture")
	# Terrain triangle winding must face up: both lighting and collision depend on it.
	var terrain: MeshInstance3D = current_scene.get_node("VisualClearing").get_child(0)
	var normals: PackedVector3Array = terrain.mesh.surface_get_arrays(0)[Mesh.ARRAY_NORMAL]
	check(normals[0].y > 0.9, "Terrain normals face inward")
	var query := PhysicsRayQueryParameters3D.create(Vector3(35, 10, 0), Vector3(35, -10, 0), 1)
	var hit := player.get_world_3d().direct_space_state.intersect_ray(query)
	check(not hit.is_empty() and hit.normal.y > 0.9, "Outer meadow has no walkable collision")
	# Current saves preserve the camera preference; old snapshots retain progress and default to third person.
	check(current_scene.save_game() == OK, "Saving the view failed")
	player = await enter()
	check(not player.view_rig.third_person and player.inventory.count("bow") == 1 and current_scene.get_node("PracticePine").hits_left == 3, "Save lost camera choice or progress")
	var old := GameSave.load_state()
	old.version = 3
	old.player.erase("third_person")
	var file := FileAccess.open(GameSave.storage_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(old))
	file.close()
	player = await enter()
	check(player.view_rig.third_person and player.inventory.count("bow") == 1 and current_scene.get_node("PracticePine").hits_left == 3, "Version 3 migration lost progress or camera default")
	GameSave.clear()
	print("THIRD PERSON: %s" % ("PASS — camera modes/collision, gear, pickup reach/occlusion, axe, bow/obstruction, animation, terrain, save and v3 migration" if failures == 0 else "FAIL"))
	quit(1 if failures else 0)
