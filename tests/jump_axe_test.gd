extends SceneTree
const Profile = preload("res://scripts/character_profile.gd")
const GameSave = preload("res://scripts/game_save.gd")
var failures := 0
var screenshot_dir := ""

func _initialize() -> void:
	# Never load or change the player's actual saved character during verification.
	Profile.storage_path = preload("res://tests/test_paths.gd").path("unused_jump_axe_test.json")
	# World progress is isolated too: entering the clearing must never read or write the player's real save.
	GameSave.storage_path = preload("res://tests/test_paths.gd").path("unused_jump_axe_test_save.json")
	GameSave.clear()
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

func check_swing_path(player: Node3D) -> void:
	for tool_name in ["Tool", "Pickaxe"]:
		var tool: Node3D = player.axe.get_node(tool_name)
		var head := Vector3(0, 0.46 if tool_name == "Tool" else 0.42, 0)
		var raised := Vector3.ZERO
		var impact := Vector3.ZERO
		var start_x := 0.0
		for frame in range(61):
			var time := float(frame) / 100
			player.axe.pose_swing(time)
			var point: Vector3 = player.camera.to_local(tool.to_global(head))
			if frame == 0: start_x = point.x
			check(absf(point.x - start_x) < 0.001, "%s sweeps sideways in first person" % tool_name)
			if frame == 8: raised = point
			if frame == 22:
				impact = point
				# Native stone axe edge is +X; the pick's striking point is -X.
				var edge_axis := Vector3.RIGHT if tool_name == "Tool" else Vector3.LEFT
				var edge: Vector3 = player.camera.global_basis.inverse() * (tool.global_basis * edge_axis).normalized()
				check(edge.dot(Vector3.FORWARD) > 0.8, "%s cutting edge does not face forward at impact" % tool_name)
		check(impact.z < raised.z - 0.5 and impact.y < raised.y, "%s does not strike forward and down from its backswing" % tool_name)
	player.axe.cancel_swing()

func run() -> void:
	change_scene_to_file("res://scenes/main.tscn")
	await scene_changed
	await ticks(6)
	var player := current_scene.get_node("Player")
	player.set_third_person(false)
	player._capture_controls(true)
	await ticks(8)
	var tree := current_scene.get_node("PracticePine")
	# This regression verifies axe mechanics after crafting; the starting-loop test covers earning it.
	player.inventory.add("stone_axe", 1)
	player.equip_axe(true)
	check_swing_path(player)
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
	check(tree.hits_left == tree.MAX_HITS, "Axe hit a tree beyond its reach")
	player._notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT)
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
	check(tree.hits_left == tree.MAX_HITS, "Axe hit through an obstacle")
	blocker.queue_free()
	await ticks(3)
	await capture("axe-ready-to-chop.png")
	for i in range(tree.MAX_HITS):
		click(player)
		click(player)
		await ticks(45)
		check(tree.hits_left == tree.MAX_HITS - 1 - i, "Swing contact or cooldown allowed an incorrect hit count")
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
	GameSave.clear()
	print("JUMP + AXE: %s" % ("PASS — jump/landing, no double jump, range, obstruction, cooldown, felling, pickup, resume click, and fall recovery" if failures == 0 else "FAIL"))
	quit(1 if failures else 0)
