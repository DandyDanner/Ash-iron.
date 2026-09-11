extends SceneTree
const Pickup = preload("res://scripts/resource_pickup.gd")
const Profile = preload("res://scripts/character_profile.gd")
const GameSave = preload("res://scripts/game_save.gd")
var failures := 0

func _initialize() -> void:
	Profile.storage_path = preload("res://tests/test_paths.gd").path("unused_pickup_test.json")
	# World progress is isolated too: entering the clearing must never read or write the player's real save.
	GameSave.storage_path = preload("res://tests/test_paths.gd").path("unused_pickup_assist_test_save.json")
	GameSave.clear()
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func ticks() -> void:
	for i in range(3):
		await physics_frame
		await process_frame

func run() -> void:
	change_scene_to_file("res://scenes/main.tscn")
	await scene_changed
	for pickup in get_nodes_in_group("pickups"):
		pickup.queue_free()
	await ticks()
	var player := current_scene.get_node("Player")
	player.global_position = Vector3(12, 1.1, 12)
	player.set_third_person(false)
	player._capture_controls(true)
	player.camera.rotation = Vector3.ZERO
	var item := Pickup.new()
	item.position = Vector3(14, 0.22, 10.5)
	current_scene.add_child(item)
	await ticks()
	check(player._aim_target().is_empty(), "Fixture unexpectedly needs direct aim")
	check(player._interaction_target() == item, "Off-center ground item was not selected while looking level")
	check(player.prompt_label.text == item.prompt(), "Prompt and selected item disagree")
	item.position = Vector3(12, 0.22, 8.8)
	await ticks()
	check(player._interaction_target() == null, "Pickup beyond three meters was selected")
	item.position = Vector3(12, 0.22, 14)
	await ticks()
	check(player._interaction_target() == null, "Distant item behind the player was selected")
	item.position = Vector3(12.2, 0.22, 12.3)
	await ticks()
	check(player._interaction_target() == item, "Item at the player's feet was not selected")
	item.position = Vector3(12, 0.22, 10)
	var wall := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1, 2.4, 0.3)
	collision.shape = shape
	wall.add_child(collision)
	wall.position = Vector3(12, 1.2, 11)
	current_scene.add_child(wall)
	await ticks()
	check(player._interaction_target() == null, "Pickup assist reached through an obstacle")
	wall.queue_free()
	await ticks()
	check(player._interaction_target() == item, "Unobstructed pickup was not restored")
	var event := InputEventKey.new()
	event.physical_keycode = KEY_E
	event.pressed = true
	player._unhandled_input(event)
	await ticks()
	check(player.inventory.count("stick") == 2, "E did not collect the assisted target")
	GameSave.clear()
	print("PICKUP ASSIST: %s" % ("PASS — broad aim, level view, feet, distance limit, rear exclusion, obstacles, prompt, and E collection" if failures == 0 else "FAIL"))
	quit(1 if failures else 0)
