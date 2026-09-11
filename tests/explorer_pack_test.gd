extends SceneTree
const Paths = preload("res://tests/test_paths.gd")
const Profile = preload("res://scripts/character_profile.gd")
const Save = preload("res://scripts/game_save.gd")
const Inventory = preload("res://scripts/inventory.gd")
var failures := 0

func _initialize() -> void:
	Profile.storage_path = Paths.path("pack_profile_%d.json" % Time.get_ticks_usec())
	Save.storage_path = Paths.path("pack_save_%d.json" % Time.get_ticks_usec())
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func ticks(count: int = 4) -> void:
	for i in range(count):
		await physics_frame
		await process_frame

func enter() -> Node3D:
	change_scene_to_file("res://scenes/main.tscn")
	await scene_changed
	await ticks()
	return current_scene.get_node("Player")

func run() -> void:
	var player := await enter()
	check(player.inventory.slots.size() == 8, "Starting backpack grew without earning upgrade")
	player.inventory.add("bellmaw_hide", 1)
	player.inventory.add("wood", 2)
	player.inventory.add("stick", 4)
	var before: Array = player.inventory.to_data()
	check(not player.craft_recipe("explorer_pack").begins_with("Explorer Pack fitted") and player.inventory.to_data() == before, "Upgrade bypassed workbench")
	var bench := Paths.place_bench(current_scene)
	player.global_position = bench.position + Vector3(0, 0.9, 2)
	# Fill all eight slots. The upgrade must work even when its materials are in connected storage.
	player.inventory.restore([])
	player.inventory.add("stone_axe", 8)
	var chest := preload("res://scripts/storage_chest.gd").new()
	current_scene.add_child(chest)
	chest.position = bench.position + Vector3(2, 0, 0)
	chest.storage.add("bellmaw_hide", 1)
	chest.storage.add("wood", 2)
	check(not player.recipe_requirement("explorer_pack").is_empty(), "Missing sticks did not block crafting")
	var stored: Array = chest.storage.to_data()
	player.craft_recipe("explorer_pack")
	check(chest.storage.to_data() == stored and player.inventory.slots.size() == 8, "Failed upgrade consumed partial materials")
	chest.storage.add("stick", 4)
	player.open_inventory()
	var panel: Control = player.inventory_panel
	panel._select_recipe("explorer_pack")
	panel.refresh()
	check(panel.craftables.explorer_pack.tile.tooltip_text.contains("Bellmaw hide  1 / 1"), "Upgrade tooltip omitted linked hide")
	panel.craftables.explorer_pack.button.pressed.emit()
	check(player.inventory.slots.size() == 12 and chest.storage.is_empty() and player.inventory.count("explorer_pack") == 0 and player.inventory.count("stone_axe") == 8, "Upgrade must fit permanently, consume exact materials, and preserve gear in full pack")
	check(panel.craftables.explorer_pack.availability.text == "FITTED" and panel.craftables.explorer_pack.button.disabled, "Owned upgrade can be crafted twice")
	check(player.inventory.add("stone", 40) == 40 and player.inventory.add("stone", 1) == 0, "Expanded backpack did not enforce twelve-slot capacity")
	panel.selected = 11
	panel.refresh()
	check(panel.detail.text == Inventory.ITEMS.stone.description and panel.capacity_label.text.contains("12 / 12"), "Last slot or capacity label inaccessible")
	await ticks()
	check(root.get_visible_rect().encloses(panel.drop_button.get_global_rect()), "Expanded pack pushed actions offscreen")
	panel.pack.grid.get_parent().ensure_control_visible(panel.pack.buttons[11])
	await ticks()
	check(panel.pack.buttons[11].is_visible_in_tree() and root.get_visible_rect().encloses(panel.pack.buttons[11].get_global_rect()), "Twelfth slot cannot be reached by scrolling")
	check(player.drop_slot(11).begins_with("Dropped 10"), "Drop rejected twelfth slot")
	player.inventory.add("furnace", 1)
	player.close_inventory()
	player.open_storage(chest)
	player.storage_panel.selected_pack = 11
	player.storage_panel.refresh()
	player.storage_panel.store_button.pressed.emit()
	check(chest.storage.count("furnace") == 1 and player.inventory.slots[11].is_empty(), "Chest transfer ignored twelfth slot")
	player.close_storage()
	player.inventory.add("torch", 1)
	player.assign_hotbar(9, "torch")
	player.equip_item("torch")
	current_scene.save_game()
	player = await enter()
	check(player.inventory.slots.size() == 12 and player.inventory.slots[11].get("item") == "torch" and player.hotbar[9] == "torch" and player.equipped_item == "torch", "Reload lost expanded slots or equipment")
	# A real legacy payload (not save_state, which stamps the current version) migrates safely.
	var old := Save.load_state()
	old.version = 7
	old.erase("bellmaw")
	old.player.erase("explorer_pack")
	old.player.slots.resize(8)
	var file := FileAccess.open(Save.storage_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(old))
	file.close()
	player = await enter()
	check(player.inventory.slots.size() == 8 and player.inventory.count("stone_axe") == 8 and current_scene.bellmaw.health == 80 and current_scene.get_node("EchoTrail/EchoIronVein").hits_left == 4, "Version 7 migration lost equipment or did not add fresh encounter")
	Save.clear()
	print("EXPLORER PACK: %s" % ("PASS — workbench, exact linked costs, full-pack fitting, capacity, scrolling, final-slot drop/transfer, hotbar, save and v7 migration" if failures == 0 else "FAIL"))
	quit(1 if failures else 0)
