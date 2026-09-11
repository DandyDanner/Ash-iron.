extends SceneTree
const Paths = preload("res://tests/test_paths.gd")
const Profile = preload("res://scripts/character_profile.gd")
const Save = preload("res://scripts/game_save.gd")
const Chest = preload("res://scripts/storage_chest.gd")
const Furnace = preload("res://scripts/furnace.gd")
var failures := 0
var screenshot_dir := ""

func _initialize() -> void:
	Profile.storage_path = Paths.path("shortcuts_profile_%d.json" % Time.get_ticks_usec())
	Save.storage_path = Paths.path("shortcuts_save_%d.json" % Time.get_ticks_usec())
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--screenshots="): screenshot_dir = arg.trim_prefix("--screenshots=")
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func ticks(count: int = 3) -> void:
	for i in range(count):
		await physics_frame
		await process_frame

func key(code: Key, echo: bool = false) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = true
	event.echo = echo
	Input.parse_input_event(event)
	await ticks()
	event = event.duplicate()
	event.pressed = false
	event.echo = false
	Input.parse_input_event(event)
	await ticks(1)

func hover(at: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.position = root.get_final_transform() * at
	event.global_position = event.position
	Input.parse_input_event(event)
	await ticks()

func capture(name: String) -> void:
	if screenshot_dir.is_empty() or DisplayServer.get_name() == "headless": return
	DirAccess.make_dir_recursive_absolute(screenshot_dir)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(screenshot_dir.path_join(name + ".png"))

func run() -> void:
	change_scene_to_file("res://scenes/main.tscn")
	await scene_changed
	await ticks()
	var player: Node3D = current_scene.get_node("Player")
	player._capture_controls(true)
	await key(KEY_TAB)
	check(player.inventory_panel.visible and not player.controls_active, "Tab did not open inventory through the real input pipeline")
	await key(KEY_TAB, true)
	check(player.inventory_panel.visible, "Held Tab repeated and closed inventory")
	player.inventory_panel.pack.buttons[0].grab_focus()
	await key(KEY_RIGHT)
	check(root.gui_get_focus_owner() != player.inventory_panel.pack.buttons[0] and player.inventory_panel.visible, "Arrow navigation no longer works in inventory")
	await key(KEY_TAB)
	check(not player.inventory_panel.visible and player.controls_active, "Tab did not close inventory or resume play")
	await key(KEY_I)
	check(player.inventory_panel.visible, "I alias failed to open inventory")
	await key(KEY_I)
	check(not player.inventory_panel.visible, "I alias failed to close inventory")
	player.inventory.add("stone",4)
	player.inventory.add("wood",6)
	player.inventory.add("stone_axe",1)
	player.equip_item("stone_axe")
	var chest := Chest.new()
	current_scene.add_child(chest)
	chest.position = player.position + Vector3(2,0,0)
	player.open_storage(chest)
	await ticks()
	var panel: Control = player.storage_panel
	panel.selected_pack = 0
	panel.refresh()
	# Hover the icon, with another stack selected/focused. Only the hovered stack may move.
	await hover(panel.pack.icons[1].get_global_rect().get_center())
	await key(KEY_T)
	check(chest.storage.count("wood") == 6 and player.inventory.count("wood") == 0 and player.inventory.count("stone") == 4, "T did not transfer hovered stack or used the selected stack instead")
	await capture("quick-transfer")
	await key(KEY_T)
	check(player.inventory.count("stone") == 4 and chest.storage.count("wood") == 6, "T on an empty slot moved a different stack")
	await hover(panel.store.icons[0].get_global_rect().get_center())
	await key(KEY_T)
	check(chest.storage.is_empty() and player.inventory.count("wood") == 6, "Reverse hover transfer failed")
	var filled: Array = []
	for i in range(11): filled.append({"item":"torch","amount":1})
	filled.append({"item":"wood","amount":8})
	chest.storage.restore(filled)
	panel.refresh()
	await hover(panel.pack.buttons[1].get_global_rect().get_center())
	await key(KEY_T)
	check(chest.storage.count("wood") == 10 and player.inventory.count("wood") == 4, "Partial transfer lost excess or ignored stack limits")
	await key(KEY_T)
	check(chest.storage.count("wood") == 10 and player.inventory.count("wood") == 4 and panel.message_label.text.begins_with("No room"), "Full chest lost items or gave no feedback")
	chest.storage.take_slot(11)
	panel.refresh()
	await key(KEY_T, true)
	check(player.inventory.count("wood") == 4 and chest.storage.count("wood") == 0, "Holding T repeated a transfer")
	await hover(panel.pack.icons[2].get_global_rect().get_center())
	await key(KEY_T)
	check(player.equipped_item.is_empty() and chest.storage.count("stone_axe") == 1 and player.hotbar.has("stone_axe"), "Storing held tool did not holster it safely and retain shortcut")
	player.inventory.expand_backpack()
	player.inventory.slots[11] = {"item":"iron_ore","amount":3}
	player.inventory.changed.emit()
	chest.storage.take_slot(9)
	panel.refresh()
	await ticks()
	await hover(panel.pack.buttons[11].get_global_rect().get_center())
	await key(KEY_T)
	check(chest.storage.count("iron_ore") == 3 and player.inventory.slots[11].is_empty(), "T omitted the expanded backpack row")
	await hover(Vector2(2,2))
	var before: Array = player.inventory.to_data()
	await key(KEY_T)
	check(player.inventory.to_data() == before and panel.message_label.text.begins_with("Hover"), "T outside a slot used stale hover or selection")
	await key(KEY_TAB)
	check(not panel.visible and player.controls_active, "Tab did not close chest")
	await key(KEY_TAB)
	await hover(player.inventory_panel.pack.buttons[1].get_global_rect().get_center())
	await key(KEY_T)
	check(player.inventory.to_data() == before, "Closed chest still accepted transfers")
	await key(KEY_TAB)
	var furnace := Furnace.new()
	current_scene.add_child(furnace)
	furnace.position = player.position + Vector3(-2,0,0)
	player.open_furnace(furnace)
	await key(KEY_TAB)
	check(not player.furnace_panel.visible and player.controls_active, "Tab did not close furnace")
	current_scene.save_game()
	var saved := Save.load_state()
	check(saved.chests[0].slots[11].get("item", "") == "stone_axe" and saved.player.equipped_item == "", "Transfer did not persist with correct equipment state")
	Save.clear()
	print("INVENTORY SHORTCUTS: %s" % ("PASS — real Tab/I input, arrow focus, hovered T both ways, partial/full/empty, repeats, held tool, closed panels and save" if failures == 0 else "FAIL"))
	quit(1 if failures else 0)
