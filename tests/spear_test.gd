extends SceneTree
const Paths = preload("res://tests/test_paths.gd")
const Profile = preload("res://scripts/character_profile.gd")
const Save = preload("res://scripts/game_save.gd")
var failures := 0

func _initialize() -> void:
	Profile.storage_path = Paths.path("spear_profile_%d.json" % Time.get_ticks_usec())
	Save.storage_path = Paths.path("spear_save_%d.json" % Time.get_ticks_usec())
	call_deferred("run")

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func ticks(count: int = 4) -> void:
	for i in range(count):
		await physics_frame
		await process_frame

func click(player: Node) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	player._unhandled_input(event)

func enter() -> Node3D:
	change_scene_to_file("res://scenes/main.tscn")
	await scene_changed
	await ticks(6)
	var player: Node3D = current_scene.get_node("Player")
	player._capture_controls(true)
	return player

func aim(player: Node3D, target: Node3D, distance: float, third: bool) -> void:
	player.global_position = target.global_position + Vector3(0, 0.9, distance)
	player.rotation = Vector3.ZERO
	player.set_third_person(third)
	var pivot: Vector3 = player.view_rig.arm.global_position if third else player.camera.global_position
	var offset: Vector3 = target.global_position + Vector3.UP * 1.4 - pivot
	player.camera.rotation = Vector3(atan2(offset.y, Vector2(offset.x, offset.z).length()), 0, 0)
	await ticks(8)

func spear_clears_body(rig: Node3D) -> bool:
	for part in rig.held_spear.find_children("*", "MeshInstance3D", true, false):
		var vertices: PackedVector3Array = part.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		for vertex in vertices:
			var world_point: Vector3 = part.to_global(vertex)
			var body_point: Vector3 = rig.avatar.body.to_local(world_point)
			if body_point.y > 1.0 and body_point.y < 1.5 and pow(body_point.x / 0.25, 2) + pow(body_point.z / 0.16, 2) < 1.0:
				return false
			var forearm: Vector3 = rig.avatar.forearms[1].to_local(world_point)
			# Match the model's tapered skin and rolled cuff, rather than a full-width tube at the wrist.
			var radius_x := lerpf(0.043, 0.059, clampf((forearm.y + 0.23) / 0.13, 0, 1))
			var radius_z := lerpf(0.042, 0.052, clampf((forearm.y + 0.23) / 0.13, 0, 1))
			if forearm.y > -0.10:
				radius_x = lerpf(0.059, 0.061, clampf((forearm.y + 0.10) / 0.10, 0, 1))
				radius_z = lerpf(0.052, 0.057, clampf((forearm.y + 0.10) / 0.10, 0, 1))
			if forearm.y > -0.0415:
				radius_x = 0.084
				radius_z = 0.084
			if forearm.y > -0.23 and forearm.y < 0.0215 and pow(forearm.x / radius_x, 2) + pow(forearm.z / radius_z, 2) < 1.0:
				return false
	return true

func run() -> void:
	var player := await enter()
	check(player.inventory.count("stone_spear") == 0 and not player.view_rig.held_spear.visible, "A new traveler received a free spear")
	var full_pack := preload("res://scripts/inventory.gd").new()
	var stock := preload("res://scripts/inventory.gd").new(12)
	full_pack.add("stick", 80)
	stock.add("wood", 2)
	stock.add("stone", 2)
	var stored_before: Array = stock.to_data()
	check(not full_pack.craft_across([full_pack, stock], {"wood": 2, "stone": 2}, "stone_spear") and stock.to_data() == stored_before, "Full-pack spear craft spent connected materials")
	player.inventory.add("wood", 2)
	player.inventory.add("stone", 2)
	var before: Array = player.inventory.to_data()
	check(not player.craft_recipe("stone_spear").begins_with("Crafted") and player.inventory.to_data() == before, "Spear crafted without a bench")
	Paths.place_bench(current_scene)
	player.global_position = Vector3(-3.5, 1.1, 2)
	await ticks()
	# Split material costs across the pack and connected chest.
	player.inventory.craft({"stone": 2})
	var chest := preload("res://scripts/storage_chest.gd").new()
	current_scene.add_child(chest)
	chest.position = player.workbench.position + Vector3(1.6, 0, 0)
	chest.storage.add("stone", 2)
	check(player.craft_recipe("stone_spear").begins_with("Crafted"), "Spear recipe failed")
	check(player.inventory.count("stone_spear") == 1 and player.inventory.count("wood") == 0 and chest.storage.is_empty(), "Wrong spear cost or connected-storage consumption")
	check(player.equipped_item == "stone_spear" and player.hotbar[0] == "stone_spear", "Crafting did not equip and assign the spear")
	var target: Node3D = current_scene.get_node("ClearingResources/PracticeTarget")
	for third in [false, true]:
		await aim(player, target, 2.2, third)
		var previous: int = target.hits
		click(player)
		click(player)
		await ticks(7)
		check(target.hits == previous, "Spear hit before its contact frame")
		await ticks(38)
		check(target.hits == previous + 1, "Spear thrust missed or repeated damage in view %s" % third)
		await aim(player, target, 3.5, third)
		click(player)
		await ticks(45)
		check(target.hits == previous + 1, "Spear gained chase-camera reach")
	# Walls stop melee before the target.
	await aim(player, target, 2.2, true)
	var wall := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(3, 3, 0.2)
	collision.shape = shape
	wall.add_child(collision)
	current_scene.add_child(wall)
	wall.global_position = target.global_position + Vector3(0, 1.4, 1)
	await ticks()
	var hits: int = target.hits
	click(player)
	await ticks(45)
	check(target.hits == hits, "Spear hit through a wall")
	wall.queue_free()
	await ticks()
	# View changes, menus, focus loss, and holstering cancel pending contacts.
	await aim(player, target, 2.2, true)
	click(player)
	player.use_hotbar(0)
	await ticks(45)
	check(target.hits == hits and not player.view_rig.held_spear.visible, "Holstering left an active spear attack")
	player.use_hotbar(0)
	click(player)
	player.open_inventory()
	await ticks(45)
	check(target.hits == hits and player.axe.elapsed < 0, "Opening the backpack did not cancel the thrust")
	player.close_inventory()
	click(player)
	player._notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT)
	click(player)
	check(player.axe.elapsed < 0, "Resume click also thrust the spear")
	click(player)
	player.set_third_person(false)
	await ticks(45)
	check(target.hits == hits, "View toggle left an active attack")
	# The spear cannot harvest the existing trees or rocks.
	var pine: Node3D = current_scene.get_node("PracticePine")
	await aim(player, pine, 2.0, false)
	check(player._spear_target().get("collider") == pine, "Non-harvesting tree test did not aim at the tree")
	var tree_hits: int = pine.hits_left
	click(player)
	await ticks(45)
	check(pine.hits_left == tree_hits, "Spear harvested wood")
	var rock: Node3D = get_nodes_in_group("mineable_rocks")[0]
	await aim(player, rock, 2.0, false)
	player.camera.look_at(rock.global_position)
	await ticks()
	check(player._spear_target().get("collider") == rock, "Non-harvesting rock test did not aim at the rock")
	var rock_hits: int = rock.hits_left
	click(player)
	await ticks(45)
	check(rock.hits_left == rock_hits, "Spear mined a boulder")
	# First-person motion is a thrust; the third-person hand remains at its grip.
	for time in [-1.0, 0.08, 0.22, 0.59]:
		player.axe.elapsed = time
		player.axe.pose_swing(time)
		player.view_rig.avatar.animate_movement(0, 0, true, 0, "stone_spear", time, 0)
		player.view_rig._sync_equipment()
		check(player.axe.rotation.length() < 0.001 and absf(player.axe.position.x - player.axe.rest_position.x) < 0.001, "Spear uses a sideways/chopping gesture")
		var palm_distance: float = player.view_rig.avatar.right_hand.global_position.distance_to(player.view_rig.held_spear.global_position)
		check(palm_distance > 0.04 and palm_distance < 0.075, "Spear no longer rests against the palm")
		check(spear_clears_body(player.view_rig), "Spear intersects the torso or forearm")
	# Existing inventory, chest, dropped-item, and save paths retain the new item.
	player.axe.cancel_swing()
	player.inventory.move_slot(0, chest.storage)
	check(player.equipped_item == "" and chest.storage.count("stone_spear") == 1, "Storing the spear did not holster it")
	chest.storage.move_slot(0, player.inventory)
	player.use_hotbar(0)
	check(player.equipped_item == "stone_spear", "Stored spear did not return to its hotbar")
	check(current_scene.save_game() == OK, "Spear save failed")
	player = await enter()
	check(player.equipped_item == "stone_spear" and player.hotbar[0] == "stone_spear" and player.inventory.count("stone_spear") == 1, "Save lost spear equipment")
	player.drop_slot(0)
	await ticks()
	check(current_scene.save_game() == OK, "Dropped spear save failed")
	player = await enter()
	var dropped: Node3D
	for pickup in get_nodes_in_group("pickups"):
		if pickup.item_id == "stone_spear": dropped = pickup
	check(is_instance_valid(dropped) and player.inventory.count("stone_spear") == 0, "Dropped spear was lost or duplicated")
	if is_instance_valid(dropped): check(dropped.collect_into(player.inventory) == 1, "Dropped spear could not be recovered")
	Save.clear()
	print("SPEAR: %s" % ("PASS — crafting/storage, both views, reach/obstruction, one contact, cancellation, non-harvesting, grip, hotbar, saves and recovery" if failures == 0 else "FAIL"))
	quit(1 if failures else 0)
