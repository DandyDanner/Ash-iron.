extends SceneTree
const Inventory = preload("res://scripts/inventory.gd")
const Profile = preload("res://scripts/character_profile.gd")
const GameSave = preload("res://scripts/game_save.gd")
const Paths = preload("res://tests/test_paths.gd")
const Furnace = preload("res://scripts/furnace.gd")
var failures := 0
var screenshot_dir := ""

func _initialize() -> void:
	Profile.storage_path = Paths.path("iron_profile_%d.json" % Time.get_ticks_usec())
	GameSave.storage_path = Paths.path("iron_save_%d.json" % Time.get_ticks_usec())
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

func key(target: Node, code: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = true
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
	await ticks(3)
	return player

func capture(filename: String) -> void:
	if screenshot_dir.is_empty() or DisplayServer.get_name() == "headless":
		return
	await process_frame
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(screenshot_dir.path_join(filename)) == OK, "Screenshot failed")

func slot_of(inventory: RefCounted, item: String) -> int:
	for i in range(inventory.slots.size()):
		if inventory.slots[i].get("item", "") == item:
			return i
	return -1

func loose(item: String) -> int:
	var total := 0
	for pickup in get_nodes_in_group("pickups"):
		if not pickup.is_queued_for_deletion() and pickup.item_id == item:
			total += pickup.amount
	return total

func gather(player: Node3D, pickup: Node3D) -> void:
	player.global_position = Vector3(pickup.global_position.x, 1.1, pickup.global_position.z + 1.4)
	player.camera.look_at(pickup.global_position + Vector3(0, 0.1, 0))
	await ticks()
	key(player, KEY_E)
	await ticks()

func face(player: Node3D, spot: Vector3, pitch: float) -> void:
	player.global_position = spot
	player.rotation.y = 0.0
	player.camera.rotation = Vector3(pitch, 0, 0)
	await ticks()

func run() -> void:
	check(Inventory.ITEMS.has("iron_ore") and Inventory.ITEMS.has("iron_ingot") and Inventory.ITEMS.has("furnace") and Inventory.RECIPES.has("furnace"), "Iron items or the furnace recipe are missing")
	var player := await enter()
	var vein: Node3D = current_scene.get_node("IronVein1")
	check(get_nodes_in_group("iron_veins").size() == 4 and vein.hits_left == 4, "Three camp veins plus one at the old lookout expected")
	check(vein.prompt().begins_with("Stone pickaxe"), "Vein prompt should ask for a pickaxe: %s" % vein.prompt())
	player.inventory.add("stone_axe", 1)
	player.inventory.add("stone_pickaxe", 1)
	# An axe cannot mine a vein; a pickaxe frees one ore per strike and works the vein out in four.
	await face(player, Vector3(14, 1.1, -10.7), -0.5)
	check(player._aim_target().get("collider") == vein, "Test fixture is not aiming at the vein")
	await capture("iron-vein.png")
	player.equip_axe(true)
	await ticks()
	attack(player)
	await ticks(42)
	check(vein.hits_left == 4 and loose("iron_ore") == 0, "An axe mined an iron vein")
	player.equip_item("stone_pickaxe")
	await ticks()
	for i in range(4):
		attack(player)
		await ticks(42)
	check(vein.hits_left == 0 and not vein.mine(Vector3.ZERO), "Four pickaxe strikes did not work out the vein")
	check(loose("iron_ore") == 4, "The vein should free exactly four ore, found %d" % loose("iron_ore"))
	check(player.feedback.begins_with("Vein worked out"), "Final strike feedback missing: %s" % player.feedback)
	# Pickup assist may grab a neighbouring chunk first, so gather until none are left.
	for attempt in range(8):
		var target: Node3D = null
		for pickup in get_nodes_in_group("pickups"):
			if is_instance_valid(pickup) and not pickup.is_queued_for_deletion() and not pickup.collected and pickup.item_id == "iron_ore":
				target = pickup
				break
		if target == null:
			break
		await gather(player, target)
	check(player.inventory.count("iron_ore") == 4 and loose("iron_ore") == 0, "Ore could not be gathered")
	# Ordinary boulders shed ore only sometimes; the chance is explicit so both outcomes are covered.
	var rock: Node3D = current_scene.get_node("Rock2")
	rock.ore_chance = 0.0
	await face(player, Vector3(-6, 1.1, -1.3), 0.0)
	check(player._aim_target().get("collider") == rock, "Test fixture is not aiming at the boulder")
	for i in range(2):
		attack(player)
		await ticks(42)
	check(rock.hits_left == 2 and loose("iron_ore") == 0 and not rock.last_ore, "A boulder with no ore chance still shed ore")
	rock.ore_chance = 1.0
	for i in range(2):
		attack(player)
		await ticks(42)
	check(rock.hits_left == 0 and loose("iron_ore") == 2 and loose("stone") >= 8 and rock.last_ore, "A boulder with certain ore did not shed one chunk per strike")
	check(player.feedback.contains("iron ore"), "Boulder feedback did not mention the ore: %s" % player.feedback)
	# The furnace is a bench recipe: 10 stones + 2 wood.
	check(player.recipe_requirement("furnace") == "Craft and place a simple workbench first.", "Furnace craftable without a bench")
	var bench: Node3D = Paths.place_bench(current_scene)
	await face(player, bench.global_position + Vector3(0, 0.9, 2.0), 0.0)
	player.inventory.restore([{"item": "iron_ore", "amount": 6}, {"item": "stone", "amount": 10}, {"item": "wood", "amount": 5}])
	check(player.recipe_requirement("furnace").is_empty(), "Furnace recipe not ready with 10 stones + 2 wood at the bench: %s" % player.recipe_requirement("furnace"))
	check(player.craft_recipe("furnace").begins_with("Crafted") and player.inventory.count("furnace") == 1 and player.inventory.count("stone") == 0 and player.inventory.count("wood") == 3, "Furnace craft used the wrong materials")
	check(not player.place_selected(slot_of(player.inventory, "furnace")).begins_with("Furnace placed") and player.inventory.count("furnace") == 1, "Furnace was placed onto the workbench")
	await face(player, Vector3(12, 1.1, 12), 0.0)
	check(player.place_selected(slot_of(player.inventory, "furnace")).begins_with("Furnace placed") and player.inventory.count("furnace") == 0 and get_nodes_in_group("furnaces").size() == 1, "Furnace placement on open ground failed")
	var furnace: Node3D = get_nodes_in_group("furnaces")[0]
	check(furnace.global_position.distance_to(Vector3(12, 0.2, 10.1)) < 0.05, "Furnace landed in the wrong place: %s" % furnace.global_position)
	player.inventory.add("chest", 1)
	check(not player.place_chest(slot_of(player.inventory, "chest")).begins_with("Chest placed"), "A chest was placed over the furnace")
	player.inventory.take_slot(slot_of(player.inventory, "chest"))
	await ticks()
	player.camera.look_at(furnace.global_position + Vector3(0, 0.6, 0))
	player.feedback_time = 0.0 # The last mining message would otherwise still cover the prompt.
	await ticks()
	check(player._interaction_target() == furnace and player.prompt_label.text.begins_with("E  •  Use furnace   (cold"), "Furnace is not targetable or its prompt is wrong: %s" % player.prompt_label.text)
	await capture("furnace-placed.png")
	key(player, KEY_E)
	await ticks()
	var panel: Control = player.furnace_panel
	check(panel.visible and not player.controls_active, "E did not open the furnace")
	var shell: Control = panel.get_child(1)
	check(root.get_visible_rect().encloses(shell.get_global_rect()), "Furnace panel extends beyond the viewport")
	check(not furnace.is_burning() and panel.state_label.text.begins_with("COLD"), "A fresh furnace should be cold")
	panel.ore_button.pressed.emit()
	check(furnace.ore == 6 and player.inventory.count("iron_ore") == 0 and not furnace.is_burning() and not furnace.glow.visible, "Ore loading is wrong, or the furnace lit without fuel")
	panel.fuel_button.pressed.emit()
	check(furnace.fuel == 3 and player.inventory.count("wood") == 0 and furnace.is_burning() and furnace.glow.visible, "Fuel loading or ignition is wrong")
	await capture("furnace-panel.png")
	furnace.progress = 0.0 # With rendering on, real frame time already advanced the furnace during the capture.
	furnace.advance(6.0)
	check(furnace.ingots == 1 and furnace.ore == 4 and furnace.fuel == 2 and furnace.progress < 0.05, "The first ingot was not produced correctly")
	furnace.advance(9.0)
	check(furnace.ingots == 2 and furnace.ore == 2 and furnace.fuel == 1 and absf(furnace.progress - 0.5) < 0.05, "Smelting did not carry partial progress into the next ingot")
	furnace.advance(3.0)
	check(furnace.ingots == 3 and furnace.ore == 0 and furnace.fuel == 0 and not furnace.is_burning(), "The furnace did not stop when it ran out")
	furnace.advance(10.0)
	check(furnace.ingots == 3, "A cold furnace kept producing")
	panel.pickup_button.pressed.emit()
	check(is_instance_valid(furnace) and not furnace.is_queued_for_deletion() and player.inventory.count("furnace") == 0, "A furnace holding ingots was picked up")
	panel.take_button.pressed.emit()
	check(player.inventory.count("iron_ingot") == 3 and furnace.ingots == 0 and furnace.is_empty(), "Taking ingots failed")
	# Save while smelting; the furnace, its progress, and worked veins must all come back.
	player.inventory.add("iron_ore", 3)
	player.inventory.add("wood", 2)
	panel.ore_button.pressed.emit()
	panel.fuel_button.pressed.emit()
	furnace.advance(2.0)
	check(furnace.is_burning() and absf(furnace.progress - 1.0 / 3.0) < 0.01, "Mid-smelt state not set up")
	var furnace_spot: Vector3 = furnace.global_position
	player.close_furnace()
	check(not panel.visible and player.controls_active, "Closing the furnace did not restore play")
	player = await enter()
	var loaded := get_nodes_in_group("furnaces")
	check(loaded.size() == 1, "Furnace did not persist")
	if loaded.is_empty():
		quit(1)
		return
	var restored: Node3D = loaded[0]
	check(restored.ore == 3 and restored.fuel == 2 and restored.progress > 0.3 and restored.progress < 0.5 and restored.is_burning() and restored.global_position.distance_to(furnace_spot) < 0.05, "Furnace contents or progress did not persist")
	check(current_scene.get_node("IronVein1").hits_left == 0 and current_scene.get_node("IronVein2").hits_left == 4 and current_scene.get_node("Rock2").hits_left == 0, "Vein and boulder damage did not persist")
	check(player.inventory.count("iron_ingot") == 3, "Ingots did not persist in the backpack")
	# A format 6 save has no veins or furnaces: veins start fresh and nothing else is lost.
	var legacy := GameSave.load_state()
	legacy.erase("veins")
	legacy.erase("furnaces")
	legacy.version = 6
	var file := FileAccess.open(GameSave.storage_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(legacy))
	file.close()
	player = await enter()
	check(current_scene.loaded_from_save and get_nodes_in_group("furnaces").is_empty() and current_scene.get_node("IronVein1").hits_left == 4 and player.inventory.count("iron_ingot") == 3, "A format 6 save did not load with fresh veins and its belongings")
	# An empty furnace packs up again from its own panel.
	player.inventory.restore([{"item": "furnace", "amount": 1}])
	await face(player, Vector3(12, 1.1, 12), 0.0)
	check(player.place_selected(0).begins_with("Furnace placed"), "Restored furnace item could not be placed")
	var again: Node3D = get_nodes_in_group("furnaces")[0]
	player.open_furnace(again)
	player.furnace_panel.pickup_button.pressed.emit()
	await ticks()
	check(player.inventory.count("furnace") == 1 and get_nodes_in_group("furnaces").is_empty() and not player.furnace_panel.visible and player.controls_active, "An empty furnace could not be packed up")
	GameSave.clear()
	print("IRON + FURNACE: %s" % ("PASS — veins need a pickaxe and free four ore, boulder ore chance, furnace recipe and placement, E to open, loading, timed smelting with carried progress, stopping, taking ingots, persistence, format 6 saves, and packing up" if failures == 0 else "FAIL"))
	quit(1 if failures else 0)
