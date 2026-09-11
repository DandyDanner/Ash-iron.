extends SceneTree
const Inventory = preload("res://scripts/inventory.gd")
const Profile = preload("res://scripts/character_profile.gd")
const GameSave = preload("res://scripts/game_save.gd")
const Chest = preload("res://scripts/storage_chest.gd")
var failures := 0

func _initialize() -> void:
	Profile.storage_path = preload("res://tests/test_paths.gd").path("unused_connected_storage_test.json")
	GameSave.storage_path = preload("res://tests/test_paths.gd").path("connected_storage_test_%d.json" % Time.get_ticks_usec())
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

func place_chest_at(spot: Vector3) -> Node3D:
	var chest := Chest.new()
	current_scene.add_child(chest)
	chest.global_position = spot
	return chest

func run() -> void:
	# Planning across two inventories: nothing moves unless the whole recipe works.
	var pack := Inventory.new()
	var chest := Inventory.new(Inventory.CHEST_CAPACITY)
	pack.add("stick", 1)
	chest.add("stick", 1)
	var pack_before: Array = pack.slots.duplicate(true)
	var chest_before: Array = chest.slots.duplicate(true)
	check(not Inventory.can_afford_across([pack, chest], Inventory.AXE_COST) and not Inventory.craft_across([pack, chest], Inventory.AXE_COST, "stone_axe") and pack.slots == pack_before and chest.slots == chest_before, "Short materials across containers still changed something")
	chest.add("stick", 9)
	chest.add("stone", 2)
	check(Inventory.count_across([pack, chest], "stick") == 11, "count_across is wrong")
	check(Inventory.craft_across([pack, chest], Inventory.AXE_COST, "stone_axe"), "Cross-container craft failed")
	check(pack.count("stick") == 0 and chest.count("stick") == 8 and chest.count("stone") == 0 and pack.count("stone_axe") == 1 and chest.count("stone_axe") == 0, "Backpack-first consumption or output placement is wrong")
	pack = Inventory.new()
	pack.add("stone", 80)
	chest = Inventory.new(Inventory.CHEST_CAPACITY)
	chest.add("stick", 3)
	chest.add("stone", 2)
	check(not Inventory.can_craft_across([pack, chest], Inventory.AXE_COST, "stone_axe") and not Inventory.craft_across([pack, chest], Inventory.AXE_COST, "stone_axe") and chest.count("stick") == 3, "Output went somewhere other than the backpack, or a failed craft spent chest materials")
	change_scene_to_file("res://scenes/main.tscn")
	await scene_changed
	await ticks(6)
	var player: Node3D = current_scene.get_node("Player")
	player.set_third_person(false)
	player._capture_controls(true)
	await ticks(6)
	var bench: Node3D = preload("res://tests/test_paths.gd").place_bench(current_scene)
	var near := place_chest_at(bench.global_position + Vector3(2.5, 0, 1.5))
	var far := place_chest_at(bench.global_position + Vector3(12, 0, 0))
	await ticks()
	check(bench.linked_chests().size() == 1 and bench.linked_chests()[0] == near, "Chest linking by distance is wrong")
	far.storage.add("stick", 10)
	far.storage.add("stone", 10)
	player.global_position = bench.global_position + Vector3(0, 0.9, 2.0)
	await ticks()
	check(player.bench_requirement() == "Gather more sticks and stones by hand.", "A distant chest supplied the bench")
	near.storage.add("stick", 6)
	near.storage.add("stone", 4)
	check(player.bench_requirement().is_empty() and player.stock("stick") == 6, "A connected chest did not supply the bench")
	var built: String = player.craft_bench()
	check(built.begins_with("Workbench crafted") and built.ends_with("chest by the bench.") and bench.built and near.storage.is_empty() and far.storage.count("stick") == 10, "Bench build did not draw from the connected chest only")
	player.inventory.take_slot(0) # Remove the extra portable bench from this storage-capacity fixture.
	check(bench.prompt().ends_with("(1 chest connected)"), "Workbench prompt does not show connected storage: %s" % bench.prompt())
	player.inventory.add("stick", 2)
	near.storage.add("stick", 10)
	near.storage.add("stone", 2)
	check(player.axe_requirement().is_empty(), "Axe recipe unavailable with materials split between pack and chest")
	var crafted: String = player.craft_axe()
	check(crafted.begins_with("Stone axe crafted") and crafted.ends_with("chest by the bench."), "Craft message did not mention the chest: %s" % crafted)
	check(player.inventory.count("stick") == 0 and near.storage.count("stick") == 9 and near.storage.count("stone") == 0 and player.axe_equipped, "Axe craft did not take from the backpack first and then the chest")
	check(current_scene.dirty, "Spending chest materials did not mark the world for saving")
	player.inventory.add("stone", 200)
	near.storage.add("wood", 5)
	near.storage.add("stick", 2)
	check(player.inventory.used_slots() == 8 and player.chest_requirement() == "Make room for the chest: drop one stack.", "A full backpack did not block a craft fed from storage")
	chest_before = near.storage.slots.duplicate(true)
	player.craft_chest()
	check(near.storage.slots == chest_before, "A failed craft spent chest materials")
	player.inventory.take_slot(7)
	check(player.craft_chest().begins_with("Storage chest crafted") and player.inventory.count("chest") == 1 and near.storage.count("wood") == 0 and near.storage.count("stick") == 9, "Chest craft from storage went wrong")
	player.open_inventory()
	check(player.inventory_panel.storage_note.text.begins_with("Connected storage: 1 chest"), "Backpack panel does not report connected storage")
	check(player.inventory_panel.axe_cost.text.contains("Sticks  9 / 3"), "Panel costs do not include chest stock: %s" % player.inventory_panel.axe_cost.text)
	player.close_inventory()
	check(current_scene.save_game() == OK, "Save failed")
	change_scene_to_file("res://scenes/main.tscn")
	await scene_changed
	await ticks(6)
	var chests := get_nodes_in_group("chests")
	var sticks := 0
	for stored in chests:
		sticks += stored.storage.count("stick")
	check(chests.size() == 2 and sticks == 19, "Chest stock after crafting did not persist (chests %d, sticks %d)" % [chests.size(), sticks])
	check(current_scene.get_node("Player").workbench.linked_chests().size() == 1, "Connected storage not restored from the save")
	GameSave.clear()
	print("CONNECTED STORAGE: %s" % ("PASS — atomic planning across containers, backpack first, output in the backpack, distance limit, bench and axe and chest recipes fed from a chest, prompt and panel totals, persistence" if failures == 0 else "FAIL"))
	quit(1 if failures else 0)
