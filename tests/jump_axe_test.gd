extends SceneTree
const Profile = preload("res://scripts/character_profile.gd")
var failures := 0
var screenshot_dir := ""

func _initialize() -> void:
	# Never load or change the player's actual saved character during verification.
	Profile.storage_path = "user://unused_jump_axe_test.json"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--screenshots="):
			screenshot_dir = arg.trim_prefix("--screenshots=")
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func ticks(count: int) -> void:
	for i in range(count):
		await physics_frame
		await process_frame

func key(player: Node, code: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = true
	player._unhandled_input(event)

func click(player: Node) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	player._unhandled_input(event)

func capture(filename: String) -> void:
	if not screenshot_dir.is_empty() and DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		check(root.get_texture().get_image().save_png(screenshot_dir.path_join(filename)) == OK, "Screenshot failed")

func run() -> void:
	change_scene_to_file("res://scenes/main.tscn")
	await scene_changed
	await ticks(6)
	var player := current_scene.get_node("Player")
	player._capture_controls(true)
	await ticks(8)
	var tree := current_scene.get_node("PracticePine")
	# This regression verifies axe mechanics after crafting; the starting-loop test covers earning it.
	player.inventory.add("stone_axe", 1)
	player.equip_axe(true)
	check(player.is_on_floor(), "Player did not settle on the ground")
	await capture("jump-and-axe.png")
	var start_height: float = player.position.y
	key(player, KEY_SPACE)
	await ticks(4)
	check(player.position.y > start_height + 0.15 and player.velocity.y > 0, "Space did not jump")
	var ascent_speed: float = player.velocity.y
	key(player, KEY_SPACE)
	await ticks(3)
	check(player.velocity.y < ascent_speed, "A second Space press caused a midair jump")
	await ticks(90)
	check(player.is_on_floor() and absf(player.position.y - start_height) < 0.05, "Jump did not land safely")
	click(player)
	await ticks(45)
	check(tree.hits_left == 4, "Axe hit a tree beyond its reach")
	key(player, KEY_ESCAPE)
	click(player)
	check(player.axe.elapsed < 0, "Resume click also swung the axe")
	player.position = Vector3(0, 1.1, 2)
	await ticks(3)
	var blocker := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(2, 3, 0.3)
	collision.shape = shape
	blocker.add_child(collision)
	blocker.position = Vector3(0, 1.5, 1)
	current_scene.add_child(blocker)
	await ticks(3)
	click(player)
	await ticks(45)
	check(tree.hits_left == 4, "Axe hit through an obstacle")
	blocker.queue_free()
	await ticks(3)
	await capture("axe-ready-to-chop.png")
	for i in range(4):
		click(player)
		click(player)
		await ticks(45)
		check(tree.hits_left == 3 - i, "Swing contact or cooldown allowed an incorrect hit count")
	await ticks(60)
	check(get_nodes_in_group("wood_bundles").size() == 1, "Felled tree did not drop exactly one wood bundle")
	check(not tree.chop(tree.global_position), "Felled tree can be harvested twice")
	if get_nodes_in_group("wood_bundles").is_empty():
		quit(1)
		return
	var bundle: Node3D = get_nodes_in_group("wood_bundles")[0]
	player.camera.look_at(bundle.global_position + Vector3(0, 0.15, 0))
	await ticks(3)
	await capture("wood-ready-to-collect.png")
	key(player, KEY_E)
	await ticks(3)
	check(player.wood == 5 and get_nodes_in_group("wood_bundles").is_empty(), "E did not collect the wood")
	key(player, KEY_E)
	await ticks(3)
	check(player.wood == 5, "Wood collection was duplicated")
	player.position.y = -20
	await ticks(6)
	check(player.position.distance_to(player.spawn_position) < 0.1 and player.wood == 5, "Falling off the clearing did not recover safely")
	print("JUMP + AXE: %s" % ("PASS — jump/landing, no double jump, range, obstruction, cooldown, felling, pickup, resume click, and fall recovery" if failures == 0 else "FAIL"))
	quit(1 if failures else 0)
