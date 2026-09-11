extends SceneTree
const Inventory = preload("res://scripts/inventory.gd")
const Profile = preload("res://scripts/character_profile.gd")
const GameSave = preload("res://scripts/game_save.gd")
const Bundle = preload("res://scripts/wood_bundle.gd")
var failures := 0
var screenshot_dir := ""

func _initialize() -> void:
	Profile.storage_path = preload("res://tests/test_paths.gd").path("unused_inventory_test.json")
	# World progress is isolated too: entering the clearing must never read or write the player's real save.
	GameSave.storage_path = preload("res://tests/test_paths.gd").path("unused_inventory_crafting_test_save.json")
	GameSave.clear()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--screenshots="):
			screenshot_dir = arg.trim_prefix("--screenshots=")
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func ticks(count: int = 3) -> void:
	for i in range(count):
		await physics_frame
		await process_frame

func key(player: Node, code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	player._unhandled_input(event)

func click(player: Node) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	player._unhandled_input(event)

func capture(filename: String) -> void:
	if not screenshot_dir.is_empty() and DisplayServer.get_name() != "headless":
		await process_frame
		await RenderingServer.frame_post_draw
		check(root.get_texture().get_image().save_png(screenshot_dir.path_join(filename)) == OK, "Screenshot failed")

func gather(player: Node3D, pickup: Node3D) -> void:
	player.global_position = Vector3(pickup.global_position.x, 1.1, pickup.global_position.z + 1.4)
	player.camera.look_at(pickup.global_position + Vector3(0, 0.1, 0))
	await ticks()
	key(player, KEY_E)
	await ticks()

func run() -> void:
	var pack := Inventory.new()
	check(pack.used_slots() == 0 and pack.slots.size() == 8, "Backpack is not initially empty with eight slots")
	check(pack.add("stick", 13) == 13 and pack.slots[0].amount == 10 and pack.slots[1].amount == 3, "Resource stacks did not split at ten")
	var before: Array = pack.slots.duplicate(true)
	check(not pack.craft(Inventory.BENCH_COST) and pack.slots == before, "Failed recipe consumed resources")
	pack = Inventory.new()
	pack.add("stick", 10)
	pack.add("stone", 10)
	pack.add("wood", 60)
	before = pack.slots.duplicate(true)
	check(not pack.craft(Inventory.AXE_COST, "stone_axe") and pack.slots == before, "Crafting with no output space consumed materials")
	pack.take_slot(7)
	check(pack.craft(Inventory.AXE_COST, "stone_axe") and pack.count("stick") == 7 and pack.count("stone") == 8 and pack.count("stone_axe") == 1, "Craft did not consume exactly its recipe")
	pack = Inventory.new()
	pack.add("stick", 3)
	pack.add("stone", 2)
	pack.add("wood", 60)
	check(pack.craft(Inventory.AXE_COST, "stone_axe") and pack.used_slots() == 7, "Craft did not reuse slots freed by ingredients")
	change_scene_to_file("res://scenes/main.tscn")
	await scene_changed
	await ticks(6)
	var player := current_scene.get_node("Player")
	player._capture_controls(true)
	await ticks(8)
	check(player.inventory.used_slots() == 0 and not player.axe_equipped and not player.axe.get_node("Tool").visible, "Player did not start with empty hands")
	check(get_nodes_in_group("pickups").size() == 32, "Guaranteed starting supplies missing")
	await capture("empty-hands-and-supplies.png")
	player.global_position = Vector3(0, 1.1, 2)
	player.camera.rotation = Vector3.ZERO
	click(player)
	await ticks(42)
	check(current_scene.get_node("PracticePine").hits_left == 4, "Empty hands damaged a tree")
	check(not player.axe.start_swing(), "Unequipped axe accepted an attack")
	key(player, KEY_I)
	check(player.inventory_panel.visible and not player.controls_active, "I did not open the backpack safely")
	check(player.inventory_panel.bench_button.disabled and player.inventory_panel.axe_button.disabled, "Unavailable recipes were enabled")
	await capture("backpack-empty.png")
	click(player)
	check(not player.controls_active and player.axe.elapsed < 0, "Inventory click leaked into gameplay")
	player.close_inventory()
	for i in range(5):
		await gather(player, current_scene.get_node("ClearingResources/stick_%d" % i))
	for i in range(3):
		await gather(player, current_scene.get_node("ClearingResources/stone_%d" % i))
	check(player.inventory.count("stick") == 10 and player.inventory.count("stone") == 6, "E gathering did not deliver the supplies")
	player.global_position = Vector3(12, 1.1, 12)
	check(not player.bench_requirement().is_empty(), "Bench can be built away from its campsite")
	before = player.inventory.slots.duplicate(true)
	player.build_bench()
	player.craft_axe()
	check(player.inventory.slots == before and not player.workbench.built, "Invalid crafting changed materials or the bench")
	player.global_position = player.workbench.global_position + Vector3(0, 0.9, 2.0)
	player.camera.look_at(player.workbench.global_position + Vector3(0, 0.7, 0))
	await ticks()
	key(player, KEY_E)
	await ticks()
	check(player.inventory_panel.visible, "E did not open crafting at the worksite")
	await capture("backpack-ready-to-build.png")
	player.inventory_panel.bench_button.pressed.emit()
	check(player.workbench.built and player.inventory.count("stick") == 4 and player.inventory.count("stone") == 2, "Bench construction did not consume the exact cost")
	check(not player.inventory_panel.axe_button.disabled, "Axe recipe unavailable at the built bench")
	player.inventory_panel.axe_button.pressed.emit()
	check(player.inventory.count("stone_axe") == 1 and player.axe_equipped and player.axe.get_node("Tool").visible, "Axe was not crafted and equipped")
	check(player.inventory.count("stick") == 1 and player.inventory.count("stone") == 0, "Axe materials not consumed correctly")
	before = player.inventory.slots.duplicate(true)
	player.craft_axe()
	check(player.inventory.slots == before, "Repeated craft duplicated an axe")
	await capture("backpack-first-axe.png")
	var axe_slot := -1
	for i in range(8):
		if player.inventory.slots[i].get("item", "") == "stone_axe":
			axe_slot = i
	player.inventory_panel.selected = axe_slot
	player.inventory_panel.refresh()
	player.inventory_panel.equip_button.pressed.emit()
	check(not player.axe_equipped, "Unequip failed")
	player.inventory_panel.equip_button.pressed.emit()
	check(player.axe_equipped, "Re-equip failed")
	player.inventory_panel.drop_button.pressed.emit()
	check(not player.axe_equipped and player.inventory.count("stone_axe") == 0, "Dropping the axe did not unequip it")
	player.close_inventory()
	var dropped: Node3D
	for pickup in get_nodes_in_group("pickups"):
		if pickup.item_id == "stone_axe":
			dropped = pickup
	check(is_instance_valid(dropped), "Dropped axe was lost")
	if is_instance_valid(dropped):
		await gather(player, dropped)
	check(player.axe_equipped and player.inventory.count("stone_axe") == 1, "Dropped axe could not be recovered")
	pack = Inventory.new()
	pack.add("wood", 79)
	var bundle := Bundle.new()
	current_scene.add_child(bundle)
	check(bundle.collect_into(pack) == 1 and bundle.amount == 4 and not bundle.collected, "Partial pickup lost leftover wood")
	check(bundle.collect_into(pack) == 0 and bundle.amount == 4, "Full backpack consumed a world pickup")
	pack.take_slot(0)
	check(bundle.collect_into(pack) == 4 and bundle.collected, "Leftover wood could not be picked up after making space")
	check(bundle.collect_into(pack) == 0, "Pickup duplication allowed")
	player.global_position = player.workbench.global_position + Vector3(0, 0.9, 2.4)
	player.camera.look_at(player.workbench.global_position + Vector3(0, 0.85, 0))
	await ticks()
	await capture("first-workbench.png")
	GameSave.clear()
	print("INVENTORY + CRAFTING: %s" % ("PASS — eight slots, stacking, full/partial pickups, recipe transactions, empty start, gathering, bench, axe, equip/drop/recover" if failures == 0 else "FAIL"))
	quit(1 if failures else 0)
