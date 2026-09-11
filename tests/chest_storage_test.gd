extends SceneTree
const Inventory = preload("res://scripts/inventory.gd")
const Profile = preload("res://scripts/character_profile.gd")
const GameSave = preload("res://scripts/game_save.gd")
var failures := 0
var screenshot_dir := ""

func _initialize() -> void:
	Profile.storage_path = "user://unused_chest_test.json"
	GameSave.storage_path = "user://chest_test_%d.json" % Time.get_ticks_usec()
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

func capture(filename: String) -> void:
	if not screenshot_dir.is_empty() and DisplayServer.get_name() != "headless":
		await process_frame
		await RenderingServer.frame_post_draw
		check(root.get_texture().get_image().save_png(screenshot_dir.path_join(filename)) == OK, "Screenshot failed")

func slot_of(inventory: RefCounted, item: String) -> int:
	for i in range(inventory.slots.size()):
		if inventory.slots[i].get("item", "") == item:
			return i
	return -1

func run() -> void:
	var pack := Inventory.new()
	var chest := Inventory.new(Inventory.CHEST_CAPACITY)
	check(pack.slots.size() == 8 and chest.slots.size() == 12, "Backpack and chest sizes are wrong")
	pack.add("wood", 7)
	check(pack.move_slot(0, chest) == 7 and pack.is_empty() and chest.count("wood") == 7, "Whole stack did not move into the chest")
	chest.add("stone", 200)
	pack.add("stone", 5)
	check(chest.used_slots() == 12 and chest.count("stone") == 110 and pack.move_slot(0, chest) == 0 and pack.count("stone") == 5, "A full chest accepted items or lost the source stack")
	chest = Inventory.new(Inventory.CHEST_CAPACITY)
	chest.add("stone", 110)
	chest.add("wood", 8)
	pack = Inventory.new()
	pack.add("wood", 5)
	check(pack.move_slot(0, chest) == 2 and pack.count("wood") == 3 and chest.count("wood") == 10, "Partial transfer left the wrong remainders")
	check(pack.move_slot(0, pack) == 0 and pack.count("wood") == 3, "Moving a stack into its own inventory was allowed")
	var restored := Inventory.new()
	restored.restore([{"item": "wood", "amount": 99}, {"item": "bogus", "amount": 3}, "junk", {}, {"item": "chest", "amount": 1.0}, {"item": "stone", "amount": -4}])
	check(restored.count("wood") == 10 and restored.count("chest") == 1 and restored.used_slots() == 2, "Restore did not clamp or reject bad slot data")
	change_scene_to_file("res://scenes/main.tscn")
	await scene_changed
	await ticks(6)
	var player := current_scene.get_node("Player")
	player._capture_controls(true)
	await ticks(8)
	check(current_scene.has_method("save_game"), "The clearing lost its world script")
	player.inventory.add("wood", 15)
	player.inventory.add("stick", 12)
	player.inventory.add("stone", 4)
	check(player.chest_requirement() == "Build the simple bench first.", "Chest was craftable without a bench")
	player.global_position = player.workbench.global_position + Vector3(0, 0.9, 2.0)
	await ticks()
	player.inventory.add("stick", 6)
	check(player.build_bench().begins_with("Bench built"), "Bench setup failed")
	check(player.inventory.count("wood") == 15 and player.inventory.count("stick") == 12 and player.inventory.count("stone") == 0, "Unexpected materials before the chest craft")
	player.inventory.add("stone", 40)
	check(player.inventory.used_slots() == 8 and player.chest_requirement() == "Make room for the chest: drop one stack.", "A full backpack did not block the chest craft")
	var before: Array = player.inventory.slots.duplicate(true)
	player.craft_chest()
	check(player.inventory.slots == before, "A failed chest craft changed the backpack")
	player.inventory.take_slot(7)
	check(player.chest_requirement().is_empty(), "Chest recipe unavailable with materials, a bench, and a free slot")
	key(player, KEY_I)
	await capture("backpack-chest-recipe.png")
	player.close_inventory()
	check(player.craft_chest().begins_with("Storage chest crafted") and player.inventory.count("chest") == 1 and player.inventory.count("wood") == 10 and player.inventory.count("stick") == 10, "Chest craft consumed the wrong materials")
	player.global_position = Vector3(12, 1.1, 12)
	check(player.chest_requirement() == "Stand close to your workbench.", "Chest craftable away from the bench")
	check(player.place_chest(slot_of(player.inventory, "wood")).begins_with("Select the chest"), "Placing a non-chest slot was accepted")
	player.global_position = Vector3(0, 1.1, 2.0)
	player.rotation.y = 0.0
	player.camera.rotation = Vector3.ZERO
	await ticks()
	check(player.place_chest(slot_of(player.inventory, "chest")).begins_with("No room there") and player.inventory.count("chest") == 1, "Chest was placed inside a tree")
	player.global_position = Vector3(12, 1.1, 12)
	await ticks()
	check(player.place_chest(slot_of(player.inventory, "chest")).begins_with("Chest placed") and player.inventory.count("chest") == 0, "Chest could not be placed on open ground")
	check(get_nodes_in_group("chests").size() == 1, "Placed chest is missing from the world")
	var placed: Node3D = get_nodes_in_group("chests")[0]
	check(placed.global_position.distance_to(Vector3(12, 0.2, 10.3)) < 0.1 and placed.get_parent() == current_scene, "Chest landed in the wrong place")
	await ticks()
	player.camera.look_at(placed.global_position + Vector3(0, 0.3, 0))
	await ticks()
	check(player._aim_target().get("collider") == placed and player._interaction_target() == placed, "Chest is not solid or not targetable")
	check(player.prompt_label.text.begins_with("E  •  Open storage chest"), "Chest prompt missing")
	await capture("chest-placed.png")
	key(player, KEY_E)
	await ticks()
	check(player.storage_panel.visible and not player.controls_active and placed.is_open, "E did not open the chest")
	var panel: Control = player.storage_panel
	panel.store_button.pressed.emit()
	check(panel.message_label.text == "Select a stack first." and placed.storage.is_empty(), "Storing with nothing selected changed the chest")
	# Crafting took its five wood from the first stack, so the pack holds two stacks of five.
	panel.selected_pack = slot_of(player.inventory, "wood")
	panel.refresh()
	panel.store_button.pressed.emit()
	check(placed.storage.count("wood") == 5 and player.inventory.count("wood") == 5, "Storing the first wood stack failed")
	panel.selected_pack = slot_of(player.inventory, "wood")
	panel.refresh()
	panel.store_button.pressed.emit()
	check(placed.storage.count("wood") == 10 and placed.storage.used_slots() == 1 and player.inventory.count("wood") == 0, "Second stack did not merge into the chest's existing stack")
	await capture("storage-chest-open.png")
	check(panel.message_label.text == "Stored 5 wood.", "Store feedback was wrong: %s" % panel.message_label.text)
	panel.pickup_button.pressed.emit()
	check(is_instance_valid(placed) and not placed.is_queued_for_deletion() and player.inventory.count("chest") == 0, "A chest with contents could be picked up")
	panel.selected_chest = slot_of(placed.storage, "wood")
	panel.refresh()
	panel.take_button.pressed.emit()
	check(placed.storage.is_empty() and player.inventory.count("wood") == 10, "Taking wood back failed")
	panel.pickup_button.pressed.emit()
	await ticks()
	check(player.inventory.count("chest") == 1 and get_nodes_in_group("chests").is_empty() and not player.storage_panel.visible and player.controls_active, "Empty chest could not be packed up")
	GameSave.clear()
	print("CHEST STORAGE: %s" % ("PASS — chest inventory rules, transfers, bad data, bench recipe, footprint check, placement, E to open, store/take, and pick up" if failures == 0 else "FAIL"))
	quit(1 if failures else 0)
