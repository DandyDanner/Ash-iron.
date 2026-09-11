extends SceneTree
const Inventory = preload("res://scripts/inventory.gd")
const Profile = preload("res://scripts/character_profile.gd")
const GameSave = preload("res://scripts/game_save.gd")
var failures := 0

func _initialize() -> void:
	# Both files are isolated: the player's real traveler and real clearing are never touched.
	Profile.storage_path = preload("res://tests/test_paths.gd").path("save_load_test_profile_%d.json" % Time.get_ticks_usec())
	GameSave.storage_path = preload("res://tests/test_paths.gd").path("save_load_test_%d.json" % Time.get_ticks_usec())
	GameSave.clear()
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

func gather(player: Node3D, pickup: Node3D) -> void:
	player.global_position = Vector3(pickup.global_position.x, 1.1, pickup.global_position.z + 1.4)
	player.camera.look_at(pickup.global_position + Vector3(0, 0.1, 0))
	await ticks()
	key(player, KEY_E)
	await ticks()

func slot_of(inventory: RefCounted, item: String) -> int:
	for i in range(inventory.slots.size()):
		if inventory.slots[i].get("item", "") == item:
			return i
	return -1

func enter_clearing() -> Node3D:
	change_scene_to_file("res://scenes/main.tscn")
	await scene_changed
	await ticks(6)
	var player: Node3D = current_scene.get_node("Player")
	player.set_third_person(false)
	player._capture_controls(true)
	await ticks(6)
	return player

func run() -> void:
	var corrupt := FileAccess.open(GameSave.storage_path, FileAccess.WRITE)
	corrupt.store_string("{not json")
	corrupt.close()
	check(GameSave.exists() and GameSave.load_state().is_empty(), "Malformed save was not rejected")
	var player: Node3D = await enter_clearing()
	check(not current_scene.loaded_from_save and get_nodes_in_group("pickups").size() == 32, "A malformed save changed the fresh clearing")
	check(GameSave.save_state({"version": 0, "bogus": true}) == OK and int(GameSave.load_state().get("version", -1)) == GameSave.VERSION, "Save did not stamp its version")
	GameSave.clear()
	await gather(player, current_scene.get_node("ClearingResources/stick_0"))
	await gather(player, current_scene.get_node("ClearingResources/stone_0"))
	check(player.inventory.count("stick") == 2 and player.inventory.count("stone") == 2, "Gathering failed before saving")
	player.inventory.add("stick", 8)
	player.inventory.add("stone", 4)
	player.global_position = Vector3(-3.5, 1.1, 2.5)
	await ticks()
	check(preload("res://tests/test_paths.gd").craft_and_place_bench(player) and player.craft_axe().begins_with("Stone axe crafted"), "Bench and axe setup failed")
	player.global_position = Vector3(0, 1.1, 2)
	player.rotation.y = 0.0
	player.camera.rotation = Vector3.ZERO
	await ticks()
	var pine: Node3D = current_scene.get_node("PracticePine")
	for i in range(4):
		click(player)
		await ticks(45)
	check(pine.hits_left == 0, "The practice pine was not felled")
	await ticks(60)
	check(get_nodes_in_group("wood_bundles").size() == 1, "Felled pine did not drop wood")
	if get_nodes_in_group("wood_bundles").is_empty():
		quit(1)
		return
	var bundle: Node3D = get_nodes_in_group("wood_bundles")[0]
	player.camera.look_at(bundle.global_position + Vector3(0, 0.15, 0))
	await ticks()
	key(player, KEY_E)
	await ticks()
	check(player.wood == 5, "Wood was not collected before saving")
	player.inventory.add("wood", 5) # A second tree's worth, so five wood remain after the chest is crafted.
	player.global_position = Vector3(8, 1.1, 4)
	player.rotation.y = 0.0
	player.camera.rotation = Vector3.ZERO
	await ticks()
	click(player)
	await ticks(45)
	check(current_scene.get_node("Tree1").hits_left == 3, "Partial chop on Tree1 failed")
	player.inventory.add("stick", 1)
	player.global_position = player.workbench.global_position + Vector3(0, 0.9, 2.0)
	await ticks()
	check(player.craft_chest().begins_with("Storage chest crafted"), "Chest craft failed before saving")
	player.global_position = Vector3(12, 1.1, 12)
	player.rotation.y = 0.0
	player.camera.rotation = Vector3.ZERO
	await ticks()
	check(player.place_chest(slot_of(player.inventory, "chest")).begins_with("Chest placed"), "Chest placement failed before saving")
	if get_nodes_in_group("chests").is_empty():
		quit(1)
		return
	var chest: Node3D = get_nodes_in_group("chests")[0]
	player.open_storage(chest)
	player.storage_panel.selected_pack = slot_of(player.inventory, "wood")
	player.storage_panel.refresh()
	player.storage_panel.store_button.pressed.emit()
	check(chest.storage.count("wood") == 5 and player.wood == 0, "Storing wood in the chest failed")
	player.close_storage()
	player.inventory.add("stone", 3)
	check(player.drop_slot(slot_of(player.inventory, "stone")).begins_with("Dropped"), "Dropping a stack failed")
	player.global_position = Vector3(3, 1.1, 5)
	player.rotation.y = 0.7
	player.camera.rotation.x = -0.3
	await ticks(2)
	var expected_slots: Array = player.inventory.to_data()
	var chest_spot: Vector3 = chest.global_position
	check(current_scene.save_game() == OK and GameSave.exists(), "Saving the clearing failed")
	# Leave and come back.
	player = await enter_clearing()
	check(current_scene.loaded_from_save, "Re-entering the clearing ignored the save")
	check(player.global_position.distance_to(Vector3(3, 1.1, 5)) < 0.3 and absf(player.rotation.y - 0.7) < 0.01 and absf(player.camera.rotation.x + 0.3) < 0.01, "Player position and view were not restored")
	check(player.inventory.to_data() == expected_slots and player.axe_equipped and player.axe.get_node("Tool").visible, "Backpack or equipped axe were not restored")
	check(player.workbench.built, "Workbench was not restored")
	check(current_scene.get_node("PracticePine").hits_left == 0 and current_scene.get_node("Tree1").hits_left == 3 and current_scene.get_node("Tree2").hits_left == 4, "Tree damage was not restored")
	check(get_nodes_in_group("wood_bundles").is_empty(), "The felled pine dropped wood again after loading")
	check(not current_scene.get_node("PracticePine").chop(Vector3.ZERO), "A restored stump could be chopped")
	var pickups := get_nodes_in_group("pickups")
	check(pickups.size() == 31, "Pickup count after loading should be 30 remaining plus 1 dropped, got %d" % pickups.size())
	var dropped: Node3D = null
	for pickup in pickups:
		if pickup.item_id == "stone" and pickup.amount == 3:
			dropped = pickup
	check(dropped != null and dropped.global_position.distance_to(Vector3(12, 0.235, 10.85)) < 0.3, "Dropped stack was not restored where it fell")
	if dropped:
		await gather(player, dropped)
		check(player.inventory.count("stone") == 3, "Restored dropped stack could not be picked up")
	var chests := get_nodes_in_group("chests")
	check(chests.size() == 1 and chests[0].global_position.distance_to(chest_spot) < 0.05 and chests[0].storage.count("wood") == 5, "Chest was not restored with its contents")
	if chests.is_empty():
		quit(1)
		return
	player.open_storage(chests[0])
	player.storage_panel.selected_chest = slot_of(chests[0].storage, "wood")
	player.storage_panel.refresh()
	player.storage_panel.take_button.pressed.emit()
	check(player.wood == 5 and chests[0].storage.is_empty(), "Taking wood from the restored chest failed")
	player.close_storage()
	# Closing the chest checkpointed the game; come back a third time.
	player = await enter_clearing()
	check(player.wood == 5 and get_nodes_in_group("chests").size() == 1 and get_nodes_in_group("chests")[0].storage.is_empty() and player.inventory.count("stone") == 3, "Checkpoint on closing the chest was not saved")
	# C returns to the creator and keeps progress; the creator offers Continue and a two-step Start over.
	key(player, KEY_C)
	await scene_changed
	await process_frame
	var creator: Control = current_scene
	check(creator.begin_button.text.begins_with("Continue") and creator.start_over_button.visible, "Creator did not offer to continue the saved journey")
	creator.start_over_button.pressed.emit()
	check(GameSave.exists() and creator.start_over_button.text.begins_with("Really"), "First Start over click erased the save without asking")
	creator.start_over_button.pressed.emit()
	check(not GameSave.exists() and not creator.start_over_button.visible and creator.begin_button.text.begins_with("Begin"), "Second Start over click did not erase the save")
	creator.find_child("BeginJourney", true, false).pressed.emit()
	await scene_changed
	await ticks(6)
	check(current_scene.name == "Main" and not current_scene.loaded_from_save and get_nodes_in_group("pickups").size() == 32 and get_nodes_in_group("chests").is_empty() and current_scene.get_node("PracticePine").hits_left == 4 and not is_instance_valid(current_scene.get_node("Player").workbench), "Start over did not give a fresh clearing")
	GameSave.clear()
	if FileAccess.file_exists(Profile.storage_path):
		DirAccess.remove_absolute(Profile.storage_path)
	print("SAVE + LOAD: %s" % ("PASS — malformed save, snapshot of pose/backpack/axe/bench/trees/pickups/dropped stack/chest, restore without duplicate wood, checkpoint on close, C keeps progress, Continue, and Start over" if failures == 0 else "FAIL"))
	quit(1 if failures else 0)
