extends SceneTree
## Native captures of actual runtime deformation; never touches the player's save.
const Paths = preload("res://tests/test_paths.gd")
const Profile = preload("res://scripts/character_profile.gd")
const Save = preload("res://scripts/game_save.gd")
func _initialize() -> void:
	Profile.storage_path = Paths.path("bellmaw_sculpt_review_profile.json")
	Save.storage_path = Paths.path("bellmaw_sculpt_review_save.json")
	Save.clear()
	call_deferred("run")
func capture(filename: String) -> void:
	for i in range(5): await process_frame
	RenderingServer.force_draw(false)
	root.get_texture().get_image().save_png(Paths.path(filename))
	print("CAPTURE: " + Paths.path(filename))
func run() -> void:
	DisplayServer.window_set_title("Ash & Iron — Bellmaw sculpt and size review")
	change_scene_to_file("res://scenes/main.tscn")
	await scene_changed
	for i in range(10): await process_frame
	var player: Node3D = current_scene.get_node("Player")
	var bell: Node3D = current_scene.bellmaw
	player._capture_controls(false)
	player.set_physics_process(false)
	bell.set_physics_process(false)
	current_scene.set_process(false)
	player.global_position = bell.global_position + Vector3(-3, .9, 0)
	for child in player.get_children():
		if child is CanvasLayer: child.hide()
	current_scene.get_node("HUD").hide()
	var camera := Camera3D.new()
	camera.fov = 65
	camera.cull_mask = 1 | 4
	current_scene.add_child(camera)
	camera.position = bell.position + Vector3(6, 7.5, 9)
	camera.look_at(bell.position + Vector3(0, 3.0, 0))
	camera.make_current()
	player.global_position = bell.global_position + Vector3(6, .9, -1.3)
	bell.art.body.scale = Vector3.ONE * 2
	bell.art.pose(0, 0, "idle", 0, 0)
	await capture("bellmaw-sculpt-size-before.png")
	bell.art.body.scale = Vector3.ONE * 4
	bell.art.pose(0, 0, "idle", 0, 0)
	await capture("bellmaw-sculpt-size-after.png")
	for sample in [["idle", 0.0], ["warn", .92], ["recover", .08], ["recover", .65], ["swipe_warn", .75], ["swipe", .12]]:
		bell._set_state(sample[0])
		bell.art.pose(0, 0, sample[0], sample[1], 0)
		await capture("bellmaw-sculpt-%s-%s.png" % [sample[0], str(sample[1])])
	var frame := 0
	for phase in [["warn", 24], ["recover", 25], ["swipe_warn", 17], ["swipe", 5], ["swipe_recover", 21], ["idle", 10]]:
		bell._set_state(phase[0])
		for i in range(phase[1]):
			bell.art.pose(.05, 0, phase[0], i * .05, 0)
			await process_frame
			RenderingServer.force_draw(false)
			root.get_texture().get_image().save_png(Paths.path("bellmaw-sculpt-motion-%03d.png" % frame))
			frame += 1
	print("ATTACK MOTION: %d native frames" % frame)
	Save.clear()
	quit()
