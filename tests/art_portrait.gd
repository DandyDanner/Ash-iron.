extends SceneTree
## Manual render utility: real model geometry in a neutral studio; no game or save edits.
## Godot --path . --script res://tests/art_portrait.gd -- --output=/absolute/folder
const Scout = preload("res://scripts/traveler_model.gd")
const Boar = preload("res://scripts/bristleback_model.gd")
const Profile = preload("res://scripts/character_profile.gd")
var output := "/private/tmp/ash-art-review"
var stage: Node3D
var camera: Camera3D
func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="): output = arg.trim_prefix("--output=")
	call_deferred("render")
func capture(name: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var error := root.get_texture().get_image().save_png(output.path_join(name + ".png"))
	print("ART CAPTURE ", name, " ", error)
func render() -> void:
	DirAccess.make_dir_recursive_absolute(output)
	root.size = Vector2i(1200, 1000)
	root.msaa_3d = Viewport.MSAA_4X
	stage = Node3D.new()
	root.add_child(stage)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("7b7a72")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("b5c4d0")
	environment.environment.ambient_light_energy = 0.32
	stage.add_child(environment)
	var ground := Scout.box(stage, Vector3(0, -0.08, 0), Vector3(200, 0.12, 200), Color("858578"))
	ground.material_override.roughness = 1
	for config in [Vector3(-40, -35, 0.72), Vector3(-25, 135, 0.35)]:
		var light := DirectionalLight3D.new()
		stage.add_child(light)
		light.rotation_degrees = Vector3(config.x, config.y, 0)
		light.light_energy = config.z
		light.shadow_enabled = false
		light.directional_shadow_max_distance = 12
	camera = Camera3D.new()
	stage.add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 2.5
	camera.position = Vector3(0.65, 1.35, 5)
	camera.look_at(Vector3(0, 1.04, 0))
	var scout := Scout.new()
	stage.add_child(scout)
	var profile := Profile.defaults()
	profile.build = 0
	scout.rebuild(profile)
	scout.set_process(false)
	await capture("willow-front")
	camera.position = Vector3(-1.5, 1.35, -5)
	camera.look_at(Vector3(0, 1.04, 0))
	await capture("willow-back")
	camera.position = Vector3(0.55, 1.88, 4)
	camera.size = 0.78
	camera.look_at(Vector3(0, 1.79, 0))
	await capture("willow-face")
	scout.free()
	var boar := Boar.new()
	stage.add_child(boar)
	camera.size = 2.40
	camera.position = Vector3(2.7, 1.7, 3.8)
	camera.look_at(Vector3(0, 0.68, 0))
	await capture("bristleback")
	stage.free()
	await render_in_clearing()
	quit()

func render_in_clearing() -> void:
	var paths = preload("res://tests/test_paths.gd")
	var save = preload("res://scripts/game_save.gd")
	Profile.storage_path = paths.path("art_review_profile.json")
	save.storage_path = paths.path("art_review_save.json")
	save.clear()
	var profile := Profile.defaults()
	profile.build = 0
	Profile.save_profile(profile)
	var world := preload("res://scenes/main.tscn").instantiate()
	root.add_child(world)
	await physics_frame
	var player: Node3D = world.get_node("Player")
	player.global_position = Vector3(12, 1.1, 12)
	player._capture_controls(false)
	for layer in world.find_children("*", "CanvasLayer", true, false): layer.hide()
	await physics_frame
	var avatar: Node3D = player.view_rig.avatar
	camera = Camera3D.new()
	world.add_child(camera)
	camera.cull_mask = 5
	camera.fov = 40
	camera.position = avatar.global_position + avatar.global_basis.orthonormalized() * Vector3(0.8, 1.3, 3.2)
	camera.look_at(avatar.global_position + Vector3.UP * 0.90)
	camera.make_current()
	await capture("willow-in-clearing")
	camera.position = world.boar.global_position + Vector3(2.5, 1.7, 3.5)
	camera.look_at(world.boar.global_position + Vector3.UP * 0.7)
	await capture("bristleback-in-clearing")
