extends SceneTree
## Capture utility for the standalone three-species wildlife preview.

const Paths = preload("res://tests/test_paths.gd")
var output := ""
var preview: Node3D


func _initialize() -> void:
	output = Paths.path("native-wildlife-review")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="):
			output = arg.trim_prefix("--output=")
	DirAccess.make_dir_recursive_absolute(output)
	call_deferred("run")


func capture(filename: String) -> void:
	for i in range(4):
		await process_frame
	RenderingServer.force_draw(false)
	var path := output.path_join(filename + ".png")
	var error := root.get_texture().get_image().save_png(path)
	print("WILDLIFE CAPTURE: %s %s" % [path, error_string(error)])


func run() -> void:
	root.size = Vector2i(1200, 900)
	root.msaa_3d = Viewport.MSAA_4X
	preview = preload("res://scenes/wildlife_preview.tscn").instantiate()
	root.add_child(preview)
	await process_frame
	preview.playing = false
	var samples := [
		[0, "idle", "bristleback-idle"], [0, "charge", "bristleback-charge"], [0, "warn", "bristleback-warning"],
		[1, "idle", "meadow-buck-idle"], [1, "flee", "meadow-buck-flee"], [1, "alert", "meadow-buck-alert"],
		[2, "idle", "hollow-wolf-idle"], [2, "flee", "hollow-wolf-flee"], [2, "alert", "hollow-wolf-alert"],
	]
	for sample in samples:
		preview.select_species(sample[0])
		preview.set_pose_state(sample[1])
		for frame in range(7):
			preview.animals[sample[0]].pose(.05, float(preview.SPEEDS.get(sample[1], 0.0)), sample[1], 0.0)
		await capture(sample[2])
	quit()
