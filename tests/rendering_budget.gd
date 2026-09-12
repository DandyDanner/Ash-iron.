extends SceneTree
## Frame-time ladder for renderer features at 2x, 1.5x and 1x internal resolution (retina
## is 2x). macOS caps both drivers at the display rate, so rows above 16.7 ms are the ones
## that break the budget: Godot --path . --script res://tests/rendering_budget.gd
const Profile = preload("res://scripts/character_profile.gd")
const GameSave = preload("res://scripts/game_save.gd")
const Paths = preload("res://tests/test_paths.gd")
var out := ""

func _initialize() -> void:
	Profile.storage_path = Paths.path("budget_profile.json")
	GameSave.storage_path = Paths.path("budget_save.json")
	GameSave.clear()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out = arg.trim_prefix("--out=")
	call_deferred("run")

func ticks(count: int) -> void:
	for i in range(count):
		await physics_frame
		await process_frame

func measure(label: String) -> void:
	await ticks(20)
	var n := 90
	var t0 := Time.get_ticks_usec()
	for i in range(n):
		await process_frame
	var ms := (Time.get_ticks_usec() - t0) / 1000.0 / n
	print("%-40s %6.2f ms  %6.1f fps  draws %d  prims %d" % [label, ms, 1000.0 / ms, RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME), RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)])

func capture(path: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)

func run() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	var forward := RenderingServer.get_current_rendering_method() == "forward_plus"
	print("METHOD ", RenderingServer.get_current_rendering_method(), " driver ", RenderingServer.get_current_rendering_driver_name())
	change_scene_to_file("res://scenes/main.tscn")
	await scene_changed
	await ticks(10)
	var player: Node3D = current_scene.get_node("Player")
	player.set_third_person(true)
	player._capture_controls(true)
	player.global_position = Vector3(1.0, 1.1, 4.5)
	player.rotation.y = 0.35
	player.camera.rotation = Vector3(-0.12, 0, 0)
	await ticks(30)
	var env: Environment = current_scene.find_children("*", "WorldEnvironment", true, false)[0].environment
	var light: DirectionalLight3D = current_scene.find_children("*", "DirectionalLight3D", true, false)[0]
	# Warm every pipeline once so first-use shader compilation stays out of the rows.
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.glow_enabled = true
	if forward:
		env.ssao_enabled = true
		env.sdfgi_enabled = true
		env.ssil_enabled = true
		light.light_angular_distance = 0.7
	await ticks(120)
	env.ssil_enabled = false
	env.sdfgi_enabled = false
	env.ssao_enabled = false
	env.glow_enabled = false
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	light.light_angular_distance = 0.0
	for scale in [2.0, 1.5, 1.0]:
		root.scaling_3d_scale = scale
		var tag := "scale %.1f " % scale
		await measure(tag + "baseline")
		light.directional_shadow_max_distance = 45.0
		await measure(tag + "shadow 45 m")
		env.tonemap_mode = Environment.TONE_MAPPER_ACES
		env.glow_enabled = true
		await measure(tag + "+ aces + glow")
		if forward:
			light.light_angular_distance = 0.7
			await measure(tag + "+ soft shadows")
			env.ssao_enabled = true
			await measure(tag + "+ ssao")
			env.sdfgi_enabled = true
			await measure(tag + "+ sdfgi")
			env.sdfgi_enabled = false
			env.ssil_enabled = true
			await measure(tag + "+ ssil instead of sdfgi")
			env.ssil_enabled = false
			env.ssao_enabled = false
			light.light_angular_distance = 0.0
		env.glow_enabled = false
		env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
		light.directional_shadow_max_distance = 65.0
	quit()
