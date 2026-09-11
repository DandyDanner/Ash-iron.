extends SceneTree
const Paths = preload("res://tests/test_paths.gd")
const Profile = preload("res://scripts/character_profile.gd")
const Save = preload("res://scripts/game_save.gd")
const Inventory = preload("res://scripts/inventory.gd")
const Furnace = preload("res://scripts/furnace.gd")
var failures := 0
var captures := ""

func _initialize() -> void:
	Profile.storage_path = Paths.path("progression_profile_%d.json" % Time.get_ticks_usec())
	Save.storage_path = Paths.path("progression_save_%d.json" % Time.get_ticks_usec())
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--screenshots="): captures = arg.trim_prefix("--screenshots=")
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func ticks(count: int = 4) -> void:
	for i in range(count):
		await physics_frame
		await process_frame

func capture(name: String) -> void:
	if captures.is_empty() or DisplayServer.get_name() == "headless": return
	DirAccess.make_dir_recursive_absolute(captures)
	await ticks(5)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(captures.path_join(name + ".png"))

func enter() -> Node3D:
	change_scene_to_file("res://scenes/main.tscn")
	await scene_changed
	await ticks()
	var player: Node3D = current_scene.get_node("Player")
	player._capture_controls(true)
	return player

func slot(player: Node3D, item: String) -> int:
	for i in range(player.inventory.slots.size()):
		if player.inventory.slots[i].get("item") == item: return i
	return -1

func click(player: Node) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	player._unhandled_input(event)

func run() -> void:
	var player := await enter()
	player.global_position = Vector3(12, 1.1, 12)
	player.rotation = Vector3.ZERO
	player.camera.rotation = Vector3.ZERO
	check(player.crafting.to_data().is_empty(), "Fresh player was granted milestones")
	player.inventory.add("stick", 15)
	player.inventory.add("stone", 14)
	player.inventory.add("wood", 5)
	var before: Array = player.inventory.to_data()
	check(player.craft_bench().begins_with("Locked") and player.inventory.to_data() == before, "Locked bench consumed materials")
	player.open_inventory()
	check(player.inventory_panel.craftables.bench.availability.text == "LOCKED", "Bench lock is not visible")
	check(player.inventory_panel.progression_note.text.contains("stone axe"), "Fresh next-step hint missing")
	await ticks()
	check(root.get_visible_rect().encloses(player.inventory_panel.get_child(1).get_global_rect()), "Fresh crafting panel exceeds viewport")
	check(player.inventory_panel.find_child("Recipes", true, false).get_global_rect().encloses(player.inventory_panel.axe_button.get_global_rect()), "First craft button is clipped")
	await capture("crafting-start")
	player.close_inventory()
	check(player.craft_axe().begins_with("Stone axe crafted") and player.crafting.has("stone_axe"), "Handmade axe did not unlock bench")
	check(player.craft_recipe("stone_pickaxe").begins_with("Crafted") and player.crafting.has("stone_pickaxe"), "Pickaxe cannot be crafted without a bench")
	check(player.craft_recipe("stone_spear").begins_with("Crafted") and player.inventory.count("wood") == 5, "Spear needs timber or bench instead of loose sticks/stone")
	check(player.craft_bench().begins_with("Workbench crafted"), "Bench remained locked")
	check(player.place_workbench(slot(player, "bench")).begins_with("Workbench placed"), "Bench placement failed")
	await ticks()
	check(player.crafting.has("bench_placed") and not player.chest_requirement().begins_with("Locked"), "Workshop did not unlock")
	# Successful crafting earns knowledge; adding or losing an item does not manufacture milestones.
	var clean := preload("res://scripts/craft_progress.gd").new()
	clean.restore({"stone_axe": "true", "copperworking": 1, "unknown": true})
	check(clean.to_data().is_empty(), "Malformed milestone values unlocked recipes")
	player.crafting.learned.erase("stone_pickaxe")
	before = player.inventory.to_data()
	check(player.craft_recipe("furnace").begins_with("Locked") and player.inventory.to_data() == before, "Owned but uncrafted pickaxe bypassed milestone")
	player.crafting.earn("stone_pickaxe")
	player.inventory.add("stone", 8)
	check(player.craft_recipe("furnace").begins_with("Crafted"), "Learned tools did not unlock furnace")
	check(not player.crafting.has("furnace_placed"), "Crafting furnace prematurely counted as placement")
	player.global_position = Vector3(15, 1.1, 12)
	check(player.place_furnace(slot(player, "furnace")).begins_with("Furnace placed"), "Furnace placement failed")
	var furnace: Node3D = get_nodes_in_group("furnaces")[0]
	furnace.set_process(false)
	check(furnace.metal == "copper" and player.crafting.has("furnace_placed"), "New furnace does not start copper milestone")
	# Mine two real copper veins, preserving iron nodes and producing falling collectible ore.
	check(get_nodes_in_group("copper_veins").size() == 3 and get_nodes_in_group("iron_veins").size() == 4, "Copper replaced existing iron deposits")
	for vein in [current_scene.get_node("CopperVein1"), current_scene.get_node("CopperVein2")]:
		for i in range(4): check(vein.mine(vein.global_position + Vector3.FORWARD), "Copper vein mining failed")
	await ticks(50)
	var mined := 0
	for pickup in get_nodes_in_group("pickups"):
		if pickup.item_id == "copper_ore":
			check(pickup.settled, "Copper ore floats after mining")
			mined += pickup.collect_into(player.inventory)
	check(mined == 8, "Two copper veins did not yield eight collectible ore")
	check(furnace.load_item(player.inventory, "iron_ore") == 0, "Wrong ore type entered copper furnace")
	var chest := preload("res://scripts/storage_chest.gd").new()
	current_scene.add_child(chest)
	chest.position = furnace.position + Vector3(2.5, 0, 0)
	player.inventory.move_slot(slot(player, "copper_ore"), chest.storage)
	chest.storage.add("wood", 4)
	furnace.refill_from_chests()
	check(furnace.ore == 2 and furnace.fuel == 1 and chest.storage.count("copper_ore") == 6, "Copper auto-feed did not reserve exactly one batch")
	check(not furnace.select_metal("iron"), "Mode switch transmuted loaded ore")
	furnace.advance(11.9)
	check(not player.crafting.has("copper_smelted") and furnace.ingots == 0, "Smelting unlock granted before completion")
	player.open_furnace(furnace)
	await capture("copper-furnace")
	furnace.advance(0.11)
	check(player.crafting.has("copper_smelted") and furnace.ingots == 1, "Completed copper smelt did not unlock fittings")
	furnace.advance(36)
	check(furnace.ingots == 4 and chest.storage.is_empty(), "Copper batches duplicated or consumed the wrong stock")
	check(furnace.take_ingots(player.inventory) == 4, "Copper ingots cannot be collected")
	player.close_furnace()
	player.global_position = player.workbench.global_position + Vector3(0, 0.9, 2)
	await ticks()
	check(player.craft_recipe("copper_axe").begins_with("Locked"), "Copper axe bypassed workshop kit")
	check(player.craft_recipe("copper_fittings").begins_with("Crafted"), "Smelted copper did not unlock fittings at bench")
	player.inventory.add("stone", 2)
	check(player.craft_recipe("copperworking").begins_with("Copperworking kit fitted"), "Bench kit could not be fitted")
	check(player.workbench.copperworking, "Learned kit not visible on bench")
	player.inventory.add("stick", 2)
	check(player.craft_recipe("copper_axe").begins_with("Crafted") and player.equipped_item == "copper_axe", "Copper axe cannot be crafted/equipped")
	before = player.inventory.to_data()
	check(player.craft_recipe("copperworking").contains("already fitted") and player.inventory.to_data() == before, "Kit was purchased twice")
	player.open_inventory()
	player.inventory_panel._select_recipe("copper_axe")
	player.inventory_panel.refresh()
	check(player.inventory_panel.craftables.copperworking.availability.text == "FITTED", "Kit status missing")
	await ticks()
	check(root.get_visible_rect().encloses(player.inventory_panel.get_child(1).get_global_rect()), "Unlocked crafting panel exceeds viewport")
	check(player.inventory_panel.find_child("Recipes", true, false).get_global_rect().encloses(player.inventory_panel.craftables.copper_axe.button.get_global_rect()), "Copper axe craft button is clipped")
	await capture("copperworking-unlocked")
	player.close_inventory()
	# Exact copper melee contact in both views; the shared forward pose and hotbar are used.
	var boar: Node3D = current_scene.boar
	boar.set_physics_process(false)
	boar.position = Vector3(12, 0.2, 16)
	for third in [false, true]:
		boar.health = boar.MAX_HEALTH
		player.global_position = boar.position + Vector3(0, 0.9, 2.2)
		player.rotation = Vector3.ZERO
		player.set_third_person(third)
		var pivot: Vector3 = player.view_rig.arm.global_position if third else player.camera.global_position
		var offset: Vector3 = boar.global_position + Vector3.UP * 0.65 - pivot
		player.camera.rotation.x = atan2(offset.y, Vector2(offset.x, offset.z).length())
		await ticks()
		check(player._melee_target(player.REACH).get("collider") == boar, "Copper combat fixture did not aim at boar")
		click(player)
		await ticks(45)
		check(boar.health == boar.MAX_HEALTH - 14, "Copper axe should deal one 14-damage hit in either view")
		check(player.axe.get_node("CopperTool").visible and player.view_rig.held.copper_axe.visible, "Copper axe art missing")
		await capture("copper-axe-third" if third else "copper-axe-first")
	boar.position = boar.HOME
	player.set_third_person(false)
	player.global_position = Vector3(0, 1.1, 2)
	player.rotation = Vector3.ZERO
	player.camera.rotation = Vector3.ZERO
	await ticks()
	click(player)
	await ticks(45)
	check(current_scene.get_node("PracticePine").hits_left == 2, "Copper axe did not deliver two chopping hits")
	click(player)
	await ticks(45)
	check(current_scene.get_node("PracticePine").hits_left == 0 and get_nodes_in_group("wood_bundles").size() == 1, "Copper axe duplicated the tree reward")
	# Safe metal selection / partial return / full pack / save with an unfinished copper batch.
	furnace.set_auto_feed(false)
	player.inventory.add("copper_ore", 3)
	player.inventory.add("wood", 2)
	furnace.load_item(player.inventory, "copper_ore")
	furnace.load_item(player.inventory, "wood", 2)
	furnace.advance(4)
	var learned: Dictionary = player.crafting.to_data()
	var tiny := Inventory.new(1)
	tiny.add("stone", 10)
	check(furnace.return_ore(tiny) == 0 and furnace.ore == 3, "Full inventory lost returned ore")
	check(current_scene.save_game() == OK, "Progression save failed")
	player = await enter()
	furnace = get_nodes_in_group("furnaces")[0]
	furnace.set_process(false)
	check(furnace.metal == "copper" and furnace.ore == 3 and furnace.progress > 0.3 and furnace.progress < 0.5, "Save lost copper batch/progress")
	check(player.crafting.to_data() == learned and player.workbench.copperworking and player.inventory.count("copper_axe") == 1, "Save lost unlocks, kit or copper axe")
	check(current_scene.get_node("CopperVein1").hits_left == 0, "Reload regenerated copper ore")
	player.inventory.take_slot(slot(player, "stone_axe"))
	check(player.crafting.has("stone_axe"), "Removing a learned tool relocked progression")
	check(furnace.return_ore(player.inventory) == 3 and furnace.select_metal("iron") and furnace.fuel == 2, "Returning ore/switching metal lost fuel")
	# A format 10 save retains every old recipe and its old iron furnace contents.
	var legacy: Dictionary = current_scene.to_data()
	legacy.version = 10
	legacy.player.erase("crafting")
	legacy.furnaces[0].erase("metal")
	legacy.furnaces[0].ore = 4
	legacy.furnaces[0].ingots = 2
	legacy.furnaces[0].progress = 0.4
	var file := FileAccess.open(Save.storage_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(legacy))
	file.close()
	player = await enter()
	furnace = get_nodes_in_group("furnaces")[0]
	check(furnace.metal == "iron" and furnace.ore == 4 and furnace.ingots == 2, "Legacy furnace contents changed metal")
	check(player.crafting.has("stone_axe") and player.crafting.has("stone_pickaxe") and not player.crafting.has("copperworking"), "Legacy recipe access lost or copper kit granted free")
	Save.clear()
	print("CRAFTING PROGRESSION: %s" % ("PASS — handcraft, earned locks, placement, copper mining/smelting, linked stock, kit, axe, saves and migration" if failures == 0 else "FAIL"))
	quit(1 if failures else 0)
