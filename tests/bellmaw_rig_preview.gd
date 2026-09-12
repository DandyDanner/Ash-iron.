extends SceneTree
## Native captures of actual runtime deformation; never touches the player's save.
const Paths = preload("res://tests/test_paths.gd")
const Profile = preload("res://scripts/character_profile.gd")
const Save = preload("res://scripts/game_save.gd")
func _initialize() -> void:
	Profile.storage_path = Paths.path("bellmaw_rig_review_profile.json")
	Save.storage_path = Paths.path("bellmaw_rig_review_save.json")
	Save.clear()
	call_deferred("run")
func capture(filename: String) -> void:
	for i in range(5): await process_frame
	RenderingServer.force_draw(false)
	root.get_texture().get_image().save_png(Paths.path(filename))
	print("CAPTURE: " + Paths.path(filename))
func run() -> void:
	DisplayServer.window_set_title("Ash & Iron — Bellmaw rig review")
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
	camera.fov = 46
	camera.cull_mask = 1 | 4
	current_scene.add_child(camera)
	camera.position = bell.position + Vector3(7, 5.5, 9)
	camera.look_at(bell.position + Vector3(-.6, 1.1, 0))
	camera.make_current()
	bell.art.pose(0, 0, "idle", 0, 0)
	await capture("rigged-bellmaw-game-idle.png")
	bell.art.pose(.2, 3.3, "approach", .2, 0)
	await capture("rigged-bellmaw-game-walk.png")
	bell.art.pose(0, 0, "warn", 1.2, 0)
	await capture("rigged-bellmaw-game-warning.png")
	camera.position = bell.position + Vector3(8, 10, 12)
	camera.look_at(bell.position + Vector3.UP * .7)
	await capture("rigged-bellmaw-game-ring.png")
	# A short stationary rig demonstration, rendered by Godot at fixed time steps.
	camera.position = bell.position + Vector3(7, 5.5, 9)
	camera.look_at(bell.position + Vector3(-.6, 1.1, 0))
	for i in range(84):
		if i < 40: bell.art.pose(.05, 3.3, "approach", i * .05, 0)
		elif i < 64: bell.art.pose(.05, 0, "warn", (i - 40) * .05, 0)
		else: bell.art.pose(.05, 0, "recover", (i - 64) * .05, 0)
		await process_frame
		RenderingServer.force_draw(false)
		root.get_texture().get_image().save_png(Paths.path("bellmaw-motion-%03d.png" % i))
	print("MOTION: 84 actual Godot frames")
	Save.clear()
	quit()
