extends SceneTree
## Deterministic runtime capture in the clearing, using temporary review saves.
const Paths = preload("res://tests/test_paths.gd")
const Profile = preload("res://scripts/character_profile.gd")
const Save = preload("res://scripts/game_save.gd")
var output := "/tmp/bellmaw-motion-frames"
var frame_number := 0
func _initialize() -> void:
	Profile.storage_path = Paths.path("bellmaw_motion_preview_profile.json")
	Save.storage_path = Paths.path("bellmaw_motion_preview_save.json")
	Save.clear()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="): output = arg.trim_prefix("--output=")
	DirAccess.make_dir_recursive_absolute(output)
	call_deferred("run")
func capture(label: String = "") -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var picture := root.get_texture().get_image()
	picture.save_png(output.path_join("frame-%04d.png" % frame_number))
	if not label.is_empty(): picture.save_png(output.path_join(label + ".png"))
	frame_number += 1
func run() -> void:
	DisplayServer.window_set_title("Ash & Iron — Bellmaw motion review")
	DisplayServer.window_set_size(Vector2i(960, 640))
	change_scene_to_file("res://scenes/main.tscn")
	await scene_changed
	var bell: Node3D = current_scene.bellmaw
	var player: Node3D = current_scene.get_node("Player")
	player._capture_controls(false)
	player.set_physics_process(false)
	bell.set_physics_process(false)
	current_scene.boar.set_physics_process(false)
	current_scene.set_process(false)
	player.hide()
	for child in player.get_children():
		if child is CanvasLayer: child.hide()
	current_scene.get_node("HUD").hide()
	bell.label.hide()
	# Hide scenery only in this capture session so trees cannot conceal the paws.
	for child in current_scene.get_children():
		if child is Node3D and child.name not in ["Ground", "Sun", "WorldEnvironment", "Bellmaw"]:
			child.hide()
	var stage := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(200, 200)
	stage.mesh = plane
	var finish := StandardMaterial3D.new()
	finish.albedo_color = Color("647254")
	finish.roughness = 1
	stage.material_override = finish
	current_scene.add_child(stage)
	bell.rotation.y = 0
	# Rig-only playback over the clearing's level arena; normal AI stays paused.
	bell.position.y = .08
	var camera := Camera3D.new()
	camera.fov = 48
	current_scene.add_child(camera)
	camera.make_current()
	bell.art.swipe_side = 1
	for phase in [["idle", .8, 0.0], ["roam", 3.8, 1.15], ["idle", .4, 0.0], ["approach", 1.0, 3.3], ["swipe_warn", .85, 0.0], ["swipe", .24, 0.0], ["swipe_recover", 1.05, 0.0]]:
		var count := ceili(float(phase[1]) * 24)
		for n in range(count + 1):
			var time := minf(float(n) / 24, phase[1])
			bell.position.z += float(phase[2]) / 24
			camera.position = bell.position + Vector3(8, 5.5, 10)
			camera.look_at(bell.position + Vector3(0, 2.25, .5))
			bell.art.pose(1.0 / 24, phase[2], phase[0], time, 0)
			var label := ""
			if n == count / 2: label = str(phase[0])
			await capture(label)
	# Matched close-up: original open face and a full local eyelid closure.
	camera.fov = 35
	camera.position = bell.position + Vector3(1.6, 4.8, 7.7)
	camera.look_at(bell.position + Vector3(0, 4.65, 3.9))
	bell.art.blink_clock = 0
	bell.art.pose(0, 0, "idle", 0, 0)
	await capture("eyes-open")
	bell.art.blink_clock = bell.art.next_blink
	for n in range(18):
		bell.art.pose(1.0 / 48, 0, "idle", 0, 0)
		await capture("eyes-closed" if n == 3 else "")
	Save.clear()
	print("BELLMAW MOTION PREVIEW: %d frames in %s" % [frame_number, output])
	quit()
