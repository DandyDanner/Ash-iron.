extends SceneTree
## Captures the clearing in third person and the creator face view with the current renderer:
## Godot --path . --script res://tests/rendering_preview.gd -- --out=/absolute/prefix
## Add --rendering-method gl_compatibility before --script to compare renderers.
const Profile = preload("res://scripts/character_profile.gd")
const GameSave = preload("res://scripts/game_save.gd")
const Paths = preload("res://tests/test_paths.gd")
var out := ""

func _initialize() -> void:
	Profile.storage_path = Paths.path("ab_profile.json")
	GameSave.storage_path = Paths.path("ab_save.json")
	GameSave.clear()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out = arg.trim_prefix("--out=")
	call_deferred("run")

func ticks(count: int) -> void:
	for i in range(count):
		await physics_frame
		await process_frame

func capture(path: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	print("CAPTURE ", path, " ", root.get_texture().get_image().save_png(path) == OK)

func run() -> void:
	print("RENDERER ", RenderingServer.get_rendering_device().get_device_name() if RenderingServer.get_rendering_device() else "compatibility/OpenGL", " method=", ProjectSettings.get_setting("rendering/renderer/rendering_method"))
	change_scene_to_file("res://scenes/main.tscn")
	await scene_changed
	await ticks(10)
	var player: Node3D = current_scene.get_node("Player")
	player.set_third_person(true)
	player._capture_controls(true)
	player.global_position = Vector3(1.0, 1.1, 4.5)
	player.rotation.y = 0.35
	player.camera.rotation = Vector3(-0.12, 0, 0)
	await ticks(75)
	print("FPS world ", Engine.get_frames_per_second())
	await capture(out + "_world.png")
	change_scene_to_file("res://scenes/character_creator.tscn")
	await scene_changed
	await ticks(10)
	for button in current_scene.find_children("*", "Button", true, false):
		if button.text.begins_with("Face"):
			button.button_pressed = true
	await ticks(40)
	print("FPS creator ", Engine.get_frames_per_second())
	await capture(out + "_face.png")
	quit()
