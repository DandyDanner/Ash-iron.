extends SceneTree
const Inventory = preload("res://scripts/inventory.gd")
const Profile = preload("res://scripts/character_profile.gd")
const GameSave = preload("res://scripts/game_save.gd")
const Paths = preload("res://tests/test_paths.gd")
var failures := 0

func _initialize() -> void:
	Profile.storage_path = Paths.path("bow_profile_%d.json" % Time.get_ticks_usec())
	GameSave.storage_path = Paths.path("bow_save_%d.json" % Time.get_ticks_usec())
	call_deferred("run")

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func ticks(count: int = 3) -> void:
	for i in range(count):
		await physics_frame
		await process_frame

func mouse(player: Node, pressed: bool, button: MouseButton = MOUSE_BUTTON_LEFT) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = button
	event.pressed = pressed
	player._unhandled_input(event)

func enter() -> Node3D:
	change_scene_to_file("res://scenes/main.tscn")
	await scene_changed
	await ticks(5)
	var player: Node3D = current_scene.get_node("Player")
	player._capture_controls(true)
	return player

func arrows_on_ground() -> int:
	var count := 0
	for pickup in get_nodes_in_group("pickups"):
		if pickup.item_id == "arrow" and not pickup.is_queued_for_deletion():
			count += pickup.amount
	return count

func run() -> void:
	var player := await enter()
	player.inventory.restore([{"item": "wood", "amount": 10}, {"item": "stick", "amount": 10}, {"item": "stone", "amount": 10}])
	check(not player.recipe_requirement("bow").is_empty(), "Bow bypassed the bench requirement")
	player.workbench.build()
	check(not player.recipe_requirement("bow").is_empty(), "Bow allowed remote crafting")
	player.global_position = player.workbench.global_position + Vector3(0, 0.9, 2)
	await ticks()
	check(player.craft_recipe("bow").begins_with("Crafted"), "Bow crafting failed")
	check(player.inventory.count("wood") == 7 and player.inventory.count("stick") == 8 and player.equipped_item == "bow" and player.hotbar[0] == "bow", "Wrong bow cost or missing hotbar equip")
	mouse(player, true)
	check(not player.bow.drawing, "Drawing allowed without arrows")
	var chest := preload("res://scripts/storage_chest.gd").new()
	current_scene.add_child(chest)
	chest.global_position = player.workbench.global_position + Vector3(2, 0, 0)
	player.inventory.take_slot(player.inventory_panel._find("stone", -1))
	chest.storage.add("stone", 2)
	check(player.craft_recipe("arrows").begins_with("Crafted") and player.inventory.count("arrow") == 5 and chest.storage.count("stone") == 1, "Arrow recipe failed to use connected stock")
	mouse(player, true)
	await ticks(20)
	mouse(player, true, MOUSE_BUTTON_RIGHT)
	mouse(player, false)
	check(player.inventory.count("arrow") == 5 and get_nodes_in_group("flying_arrows").is_empty(), "Cancel consumed or fired an arrow")
	mouse(player, true)
	mouse(player, false)
	check(player.inventory.count("arrow") == 5, "A tap spent ammo before minimum draw")
	mouse(player, true)
	await ticks(20)
	player.open_inventory()
	player.close_inventory()
	mouse(player, false)
	check(player.inventory.count("arrow") == 5 and not player.bow.drawing, "Menu did not cancel the draw")
	mouse(player, true)
	await ticks(20)
	player.equip_item("")
	mouse(player, false)
	check(player.inventory.count("arrow") == 5, "Switching equipment fired the bow")
	player.equip_item("bow")
	mouse(player, true)
	player._notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT)
	mouse(player, false)
	mouse(player, true)
	check(not player.bow.drawing, "Focus resume click began an attack")
	# Close, flat shots can reach the bullseye. Shots spend exactly one arrow.
	player.global_position = Vector3(10, 1.1, -4)
	player.rotation.y = 0
	player.camera.rotation = Vector3.ZERO
	await ticks()
	mouse(player, true)
	await ticks(55)
	check(player.bow.charge() == 1.0, "Full draw did not cap at 100 percent")
	mouse(player, false)
	mouse(player, false)
	check(player.inventory.count("arrow") == 4 and get_nodes_in_group("flying_arrows").size() == 1, "Release spent incorrect ammo or fired twice")
	var shot: Node3D = get_nodes_in_group("flying_arrows")[0]
	check(absf(shot.velocity.length() - 32.0) < 0.1, "Full draw speed incorrect")
	# Save while flying, then restore that exact in-flight projectile once.
	check(current_scene.save_game() == OK and GameSave.load_state().arrows.size() == 1, "Airborne arrow not saved")
	player = await enter()
	check(player.equipped_item == "bow" and player.hotbar[0] == "bow" and player.inventory.count("arrow") == 4, "Bow, shortcut, or ammo lost on reload")
	await ticks(50)
	var target: Node3D = current_scene.get_node("ClearingResources/PracticeTarget")
	check(target.hits == 1 and target.last_result == "Bullseye!", "Restored projectile missed the target or scored twice")
	check(get_nodes_in_group("flying_arrows").is_empty() and arrows_on_ground() == 1, "Impact failed to produce exactly one recoverable arrow")
	var arrow: Node3D
	for pickup in get_nodes_in_group("pickups"):
		if pickup.item_id == "arrow": arrow = pickup
	if arrow:
		player.global_position = Vector3(10, 1.1, -7)
		await ticks()
		var event := InputEventKey.new()
		event.physical_keycode = KEY_E
		event.pressed = true
		player._unhandled_input(event)
		await ticks()
		check(player.inventory.count("arrow") == 5 and arrows_on_ground() == 0, "E did not recover the landed arrow")
	# A thin wall in front of the muzzle blocks even a fast shot.
	player.global_position = Vector3(10, 1.1, -4)
	var blocker := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(2, 3, 0.05)
	collision.shape = shape
	blocker.add_child(collision)
	blocker.position = Vector3(10, 1.5, -4.25)
	current_scene.add_child(blocker)
	await ticks()
	mouse(player, true)
	await ticks(55)
	mouse(player, false)
	await ticks(25)
	check(target.hits == 1 and arrows_on_ground() == 1, "Arrow tunneled through the nearby wall")
	blocker.queue_free()
	await ticks()
	# A shorter draw flies slower and curves downward.
	mouse(player, true)
	await ticks(12)
	mouse(player, false)
	check(get_nodes_in_group("flying_arrows").size() == 1, "Short draw did not fire")
	if not get_nodes_in_group("flying_arrows").is_empty():
		shot = get_nodes_in_group("flying_arrows")[0]
		check(shot.velocity.length() < 20, "Short draw did not reduce launch speed")
		await ticks(3)
		if is_instance_valid(shot): check(shot.velocity.y < 0, "Projectile has no gravity")
	await ticks(70)
	check(player.inventory.count("arrow") == 3 and arrows_on_ground() == 2, "Wall/short shots lost or duplicated ammo")
	check(current_scene.save_game() == OK, "Ground-arrow snapshot failed")
	player = await enter()
	check(arrows_on_ground() == 2 and player.inventory.count("arrow") == 3, "Landed arrows did not persist exactly once")
	# Existing format 2 progress still loads after adding flight state.
	var legacy: Dictionary = current_scene.to_data()
	legacy.erase("arrows")
	legacy.version = 2
	var file := FileAccess.open(GameSave.storage_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(legacy))
	file.close()
	player = await enter()
	check(current_scene.loaded_from_save and player.inventory.count("bow") == 1 and player.inventory.count("arrow") == 3, "Format 2 save was reset")
	GameSave.clear()
	print("BOW: %s — recipes, hotbar, draw/cancel, ammo, ballistics, target, obstruction, recovery, flight/ground saves, and migration" % ("PASS" if failures == 0 else "FAIL"))
	quit(1 if failures else 0)
