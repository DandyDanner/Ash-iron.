extends SceneTree
const Paths = preload("res://tests/test_paths.gd")
const Profile = preload("res://scripts/character_profile.gd")
const GameSave = preload("res://scripts/game_save.gd")
const Chest = preload("res://scripts/storage_chest.gd")
var failures := 0

func _initialize() -> void:
	Profile.storage_path = Paths.path("placebench_profile_%d.json" % Time.get_ticks_usec())
	GameSave.storage_path = Paths.path("placebench_save_%d.json" % Time.get_ticks_usec())
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
	await ticks(6)
	var player: Node3D = current_scene.get_node("Player")
	player.set_third_person(false)
	player._capture_controls(false)
	return player

func slot(player: Node3D, item: String = "bench") -> int:
	for i in range(player.inventory.slots.size()):
		if player.inventory.slots[i].get("item", "") == item: return i
	return -1

func key(player: Node, code: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	player._unhandled_input(event)

func obstacle(spot: Vector3, dimensions: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	var collider := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = dimensions
	collider.shape = box
	body.add_child(collider)
	current_scene.add_child(body)
	body.position = spot
	return body

func run() -> void:
	var player := await enter()
	check(get_nodes_in_group("workbenches").is_empty() and not is_instance_valid(player.workbench), "Fresh game still has a fixed worksite")
	player.global_position = Vector3(12, 1.1, 12)
	player.rotation = Vector3.ZERO
	player.camera.rotation.x = -1.3
	player.inventory.add("stick", 10)
	player.inventory.add("stone", 10)
	player.inventory.add("wood", 60)
	var before: Array = player.inventory.to_data()
	check(player.craft_bench().contains("Make room") and player.inventory.to_data() == before, "Full-pack bench crafting consumed ingredients without room for the result")
	player.inventory.restore([])
	player.inventory.add("stick", 9)
	player.inventory.add("stone", 6)
	check(player.craft_bench().begins_with("Workbench crafted") and player.inventory.count("bench") == 1 and player.inventory.count("stick") == 3 and player.inventory.count("stone") == 2, "Hand crafting failed away from camp or used the wrong cost")
	check(not player.axe_requirement().is_empty(), "Carrying a bench allowed tool crafting before placement")
	# Invalid selection, no ground, obstacles, and uneven surfaces all preserve the item.
	check(player.place_workbench(-1).begins_with("Select"), "Invalid inventory selection placed a bench")
	player.global_position = Vector3(100, 1.1, 100)
	check(not player.place_workbench(slot(player)).begins_with("Workbench placed") and player.inventory.count("bench") == 1, "Placement without ground consumed the bench")
	player.global_position = Vector3(12, 1.1, 12)
	var wall := obstacle(Vector3(12, 1.5, 10.9), Vector3(3, 3, 0.15))
	await ticks()
	check(player.place_workbench(slot(player)).contains("blocks") and player.inventory.count("bench") == 1, "Workbench was placed through a wall")
	wall.queue_free()
	await ticks()
	var platform := obstacle(Vector3(22, 2, 22), Vector3(4, 0.2, 4))
	platform.add_to_group("placement_ground")
	platform.rotation.z = 0.35
	player.global_position = Vector3(22, 3.1, 24.2)
	await ticks()
	check(not player.place_workbench(slot(player)).begins_with("Workbench placed") and player.inventory.count("bench") == 1, "Steep or uneven placement consumed the bench")
	platform.queue_free()
	player.global_position = Vector3(12, 1.1, 12)
	await ticks()
	check(player.place_workbench(slot(player)).begins_with("Workbench placed") and player.inventory.count("bench") == 0, "Valid workbench placement failed")
	var first: Node3D = player.workbench
	if not is_instance_valid(first):
		quit(1)
		return
	check(first.global_position.distance_to(Vector3(12, 0.2, 9.8)) < 0.05, "Bench was not placed in front of the player independently of camera pitch")
	check(player.axe_requirement().is_empty(), "Placed bench did not enable nearby crafting")
	player.inventory.add("bench", 1)
	check(not player.place_workbench(slot(player)).begins_with("Workbench placed") and player.inventory.count("bench") == 1, "Overlapping placement consumed the second bench")
	player.camera.rotation = Vector3.ZERO
	player._capture_controls(true)
	key(player, KEY_E)
	await ticks()
	check(player.inventory_panel.visible and player.workbench == first, "Looking level did not allow E to use the placed bench")
	player.close_inventory()
	player._capture_controls(false)
	# E uses the bench being viewed, even when another one is slightly nearer.
	var second := Paths.place_bench(current_scene, Vector3(14, 0.2, 11))
	var chest_a := Chest.new()
	current_scene.add_child(chest_a)
	chest_a.position = Vector3(8, 0.2, 5)
	chest_a.storage.add("wood", 3)
	var chest_b := Chest.new()
	current_scene.add_child(chest_b)
	chest_b.position = Vector3(20, 0.2, 11)
	chest_b.storage.add("wood", 1)
	await ticks()
	player.active_bench = null
	check(player.workbench == first and player.stock("wood") == 3, "Nearest bench linked the wrong chest")
	player.camera.look_at(second.global_position + Vector3(0, 0.8, 0))
	player._capture_controls(true)
	key(player, KEY_E)
	await ticks()
	check(player.inventory_panel.visible and player.workbench == second and player.stock("wood") == 1, "E did not select the viewed bench and its storage")
	player.close_inventory()
	player._capture_controls(false)
	# Moving away never makes a remote workshop's chest materials available to hand crafting.
	player.global_position = Vector3(35, 3, 35)
	check(player.stock("wood") == 0 and not player.recipe_requirement("bow").is_empty(), "Remote bench/chest supplied materials")
	player.global_position = Vector3(12, 1.1, 12)
	player.inventory.restore([])
	player.inventory.add("stone", 80)
	check(player.pickup_workbench(first).contains("full") and not first.is_queued_for_deletion(), "Full backpack destroyed a bench")
	player.inventory.restore([])
	player.open_inventory(first)
	player.inventory_panel.pickup_bench_button.pressed.emit()
	check(player.inventory.count("bench") == 1 and first.is_queued_for_deletion(), "Pick up workbench button failed")
	check(player.pickup_workbench(first).contains("gone") and player.inventory.count("bench") == 1, "Repeated pickup duplicated the bench")
	check(current_scene.save_game() == OK and GameSave.load_state().workbenches.size() == 1, "Saving during pickup duplicated the packed bench")
	player = await enter()
	check(get_nodes_in_group("workbenches").size() == 1 and player.inventory.count("bench") == 1, "Packed/placed bench states did not survive loading")
	player.global_position = Vector3(18, 1.1, 18)
	player.rotation.y = PI / 2
	await ticks()
	check(player.place_workbench(slot(player)).begins_with("Workbench placed"), "Packed bench could not be relocated")
	var relocated: Node3D = player.workbench
	check(relocated.global_position.distance_to(Vector3(15.8, 0.2, 18)) < 0.05 and absf(relocated.rotation.y - PI / 2) < 0.01, "Relocation lost position or rotation")
	check(current_scene.save_game() == OK, "Multiple bench save failed")
	player = await enter()
	check(get_nodes_in_group("workbenches").size() == 2 and player.inventory.count("bench") == 0 and absf(player.workbench.rotation.y - PI / 2) < 0.01, "Multiple benches did not restore their transforms")
	# Previous built flags migrate to one real, movable bench at the old camp position.
	var legacy := GameSave.load_state()
	legacy.erase("workbenches")
	legacy.workbench = {"built": true}
	legacy.version = 4
	legacy.player.slots = [{"item": "wood", "amount": 3}]
	var file := FileAccess.open(GameSave.storage_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(legacy))
	file.close()
	player = await enter()
	check(get_nodes_in_group("workbenches").size() == 1 and player.workbench.global_position.distance_to(Vector3(-3.5, 0.2, 0.3)) < 0.05 and player.inventory.count("wood") == 3 and get_nodes_in_group("chests").size() == 2, "Version 4 migration lost the old bench, inventory, or chests")
	legacy.workbench.built = false
	file = FileAccess.open(GameSave.storage_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(legacy))
	file.close()
	player = await enter()
	check(get_nodes_in_group("workbenches").is_empty(), "Unbuilt legacy worksite granted a free bench")
	# A crafted bench can also be dropped and recovered using the existing item flow.
	player.inventory.add("bench", 1)
	player.global_position = Vector3(12, 1.1, 12)
	player.rotation = Vector3.ZERO
	await ticks()
	check(player.drop_slot(slot(player)).begins_with("Dropped"), "Portable bench could not be dropped")
	var loose: Node3D
	for pickup in get_nodes_in_group("pickups"):
		if pickup.item_id == "bench": loose = pickup
	check(is_instance_valid(loose) and loose.collect_into(player.inventory) == 1, "Dropped bench could not be recovered")
	GameSave.clear()
	print("PLACEABLE WORKBENCH: %s" % ("PASS — hand craft, placement checks, multiple benches, E and storage selection, packing, relocation, saves, migration, drop/recover" if failures == 0 else "FAIL"))
	quit(1 if failures else 0)
