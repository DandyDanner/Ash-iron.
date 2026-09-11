extends SceneTree
const Inventory = preload("res://scripts/inventory.gd")
const Profile = preload("res://scripts/character_profile.gd")
const GameSave = preload("res://scripts/game_save.gd")
const Paths = preload("res://tests/test_paths.gd")
var failures := 0
var screenshot_dir := ""

func _initialize() -> void:
	Profile.storage_path = Paths.path("hotbar_profile_%d.json" % Time.get_ticks_usec())
	GameSave.storage_path = Paths.path("hotbar_save_%d.json" % Time.get_ticks_usec())
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

func key(target: Node, code: Key, menu: bool = false, echo: bool = false) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = true
	event.echo = echo
	if menu:
		target._input(event)
	else:
		target._unhandled_input(event)

func attack(player: Node) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	player._unhandled_input(event)

func enter() -> Node3D:
	change_scene_to_file("res://scenes/main.tscn")
	await scene_changed
	await ticks(6)
	var player: Node3D = current_scene.get_node("Player")
	player.set_third_person(false)
	player._capture_controls(true)
	return player

func capture(filename: String) -> void:
	if screenshot_dir.is_empty() or DisplayServer.get_name() == "headless":
		return
	await process_frame
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(screenshot_dir.path_join(filename)) == OK, "Screenshot failed")

func run() -> void:
	var player := await enter()
	player.inventory.restore([{"item": "stick", "amount": 10}, {"item": "stone", "amount": 10}, {"item": "wood", "amount": 10}])
	var before: Array = player.inventory.to_data()
	check(not player.recipe_requirement("torch").is_empty(), "Torch allowed before bench")
	player.craft_recipe("torch")
	check(player.inventory.to_data() == before, "Failed recipe spent materials")
	preload("res://tests/test_paths.gd").place_bench(player.get_parent())
	check(not player.recipe_requirement("torch").is_empty(), "Remote crafting allowed")
	player.global_position = player.workbench.global_position + Vector3(0, 0.9, 2)
	await ticks()
	check(player.craft_recipe("stone_pickaxe").begins_with("Crafted"), "Pickaxe recipe failed")
	check(player.inventory.count("stick") == 7 and player.inventory.count("stone") == 6 and player.equipped_item == "stone_pickaxe", "Wrong pickaxe ingredients or equip")
	check(player.hotbar[0] == "stone_pickaxe" and player.axe.get_node("Pickaxe").visible, "Pickaxe shortcut/model missing")
	key(player, KEY_1)
	check(player.equipped_item == "", "1 did not put pickaxe away")
	key(player, KEY_1)
	key(player, KEY_1, false, true)
	check(player.equipped_item == "stone_pickaxe", "Repeat key toggled tool")
	player.craft_axe()
	player.open_inventory()
	var panel: Control = player.inventory_panel
	panel.selected = panel._find("stone_axe", -1)
	key(panel, KEY_0, true)
	check(player.hotbar[9] == "stone_axe" and player.hotbar.count("stone_axe") == 1, "0 assignment duplicated/missed shortcut")
	player.close_inventory()
	key(player, KEY_0)
	check(not player.axe_equipped, "0 did not holster held axe")
	key(player, KEY_0)
	check(player.axe_equipped, "0 did not equip axe")
	# A stored or dropped tool cannot be conjured through the shortcut.
	var chest := preload("res://scripts/storage_chest.gd").new()
	current_scene.add_child(chest)
	chest.global_position = player.workbench.global_position + Vector3(2, 0, 0)
	player.inventory.move_slot(panel._find("stone_axe", -1), chest.storage)
	key(player, KEY_0)
	check(not player.axe_equipped and player.hotbar[9] == "stone_axe", "Stored axe stayed equipped or shortcut was lost")
	chest.storage.move_slot(0, player.inventory)
	key(player, KEY_0)
	check(player.axe_equipped, "Recovered tool shortcut failed")
	# Torches use connected stock, show light, cannot chop, and persist as equipment.
	player.inventory.take_slot(panel._find("wood", -1))
	chest.storage.add("wood", 3)
	check(player.craft_recipe("torch").begins_with("Crafted") and chest.storage.count("wood") == 2, "Torch ignored connected storage")
	check(player.equipped_item == "torch" and player.axe.get_node("Torch/WarmLight").is_visible_in_tree(), "Equipped torch has no light")
	check(not player.axe.start_swing(), "Torch accepted a damaging swing")
	check(player.craft_recipe("split_wood").begins_with("Crafted") and chest.storage.count("wood") == 1, "Wood splitting failed")
	player.global_position = Vector3(0, 1.1, 2)
	player.rotation.y = 0
	player.camera.rotation = Vector3.ZERO
	player.equip_item("stone_pickaxe")
	await ticks()
	attack(player)
	await ticks(42)
	check(current_scene.get_node("PracticePine").hits_left == 4, "Pickaxe chopped a tree")
	player.global_position = Vector3(5, 1.1, -3.8)
	player.camera.rotation = Vector3.ZERO
	player.equip_axe(true)
	await ticks()
	attack(player)
	await ticks(42)
	check(current_scene.get_node("Rock1").hits_left == 4, "Axe mined a boulder")
	player.equip_item("stone_pickaxe")
	for i in range(4):
		attack(player)
		await ticks(42)
	check(current_scene.get_node("Rock1").hits_left == 0, "Four pickaxe swings did not deplete boulder")
	var stones := 0
	for pickup in get_nodes_in_group("pickups"):
		if pickup.item_id == "stone": stones += pickup.amount
	check(stones == 36, "Mining did not produce exactly eight additional stones")
	check(not current_scene.get_node("Rock1").mine(Vector3.ZERO), "Depleted rock granted more stones")
	# Save on the final chop, before its fall animation finishes.
	var tree: Node3D = current_scene.get_node("PracticePine")
	for i in range(4): tree.chop(Vector3.ZERO)
	check(get_nodes_in_group("wood_bundles").size() == 1, "Final chop did not secure wood before fall")
	player.equip_item("torch")
	player.assign_hotbar(4, "torch")
	var expected_slots: Array = player.inventory.to_data()
	var expected_bar: Array = player.hotbar.duplicate()
	check(current_scene.save_game() == OK, "Equipment save failed")
	player = await enter()
	check(player.equipped_item == "torch" and player.hotbar == expected_bar and player.inventory.to_data() == expected_slots, "Equipment/shortcuts/backpack did not survive reload")
	check(current_scene.get_node("Rock1").hits_left == 0 and get_nodes_in_group("wood_bundles").size() == 1, "World rewards duplicated or vanished on reload")
	await ticks(90)
	check(get_nodes_in_group("wood_bundles").size() == 1, "Fall animation duplicated saved wood")
	player.global_position = Vector3(0, 1.1, 6)
	player.camera.rotation = Vector3.ZERO
	await ticks()
	await capture("hotbar-torch.png")
	key(player, KEY_ESCAPE)
	panel = player.inventory_panel
	check(panel.visible and not player.controls_active, "Esc did not safely open save controls")
	await ticks()
	var shell: Control = panel.get_child(1)
	var bounds := root.get_visible_rect()
	check(bounds.encloses(shell.get_global_rect()), "Backpack panel extends beyond the viewport: %s within %s" % [shell.get_global_rect(), bounds])
	await capture("backpack-hotbar.png")
	panel.find_child("Recipes", true, false).scroll_vertical = 9999
	await ticks()
	await capture("new-recipes.png")
	# Failed saves must leave the running game open; no quit signal is emitted.
	var real_path := GameSave.storage_path
	GameSave.storage_path = real_path.path_join("missing/save.json")
	var quit_seen := [false]
	current_scene.quit_requested.connect(func(): quit_seen[0] = true)
	panel.quit_button.pressed.emit()
	check(not quit_seen[0] and panel.visible and panel.message_label.text.begins_with("Couldn't save"), "Save failure attempted quit or hid error")
	GameSave.storage_path = real_path
	# Version 1 preserves its backpack and old equipped axe while gaining a shortcut.
	var legacy: Dictionary = current_scene.to_data()
	legacy.player.erase("hotbar")
	legacy.player.erase("equipped_item")
	legacy.player.axe_equipped = true
	legacy.erase("boulders")
	legacy.version = 1
	var file := FileAccess.open(GameSave.storage_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(legacy))
	file.close()
	player = await enter()
	check(current_scene.loaded_from_save and player.axe_equipped and player.hotbar[0] == "stone_axe", "Version 1 progress was not migrated")
	# Full backpack: ingredients in connected storage must remain untouched on failure.
	player.global_position = player.workbench.global_position + Vector3(0, 0.9, 2)
	await ticks()
	player.inventory.restore([])
	player.inventory.add("wood", 80)
	var stored: Node3D = get_nodes_in_group("chests")[0]
	stored.storage.add("stick", 5)
	before = stored.storage.to_data()
	player.craft_recipe("torch")
	check(stored.storage.to_data() == before and player.inventory.count("wood") == 80, "Failed new recipe consumed stored materials")
	# Quit through the actual button in this isolated process, after validating the written snapshot.
	if failures:
		print("HOTBAR + RECIPES: FAIL (%d)" % failures)
		quit(1)
		return
	player.open_inventory()
	current_scene.quit_requested.connect(func():
		print("HOTBAR + RECIPES: PASS — shortcuts, toggles, storage, recipes, mining, torch, migration, rewards, save failure, and Save & Quit")
	)
	player.inventory_panel.quit_button.pressed.emit()
