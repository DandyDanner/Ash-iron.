extends SceneTree
const Paths = preload("res://tests/test_paths.gd")
const Profile = preload("res://scripts/character_profile.gd")
const GameSave = preload("res://scripts/game_save.gd")
const Workbench = preload("res://scripts/workbench.gd")
const Furnace = preload("res://scripts/furnace.gd")

func _initialize() -> void:
	Profile.storage_path = Paths.path("native_stations_preview_profile.json")
	GameSave.storage_path = Paths.path("native_stations_preview_save.json")
	GameSave.clear()
	call_deferred("run")

func frames(count: int = 5) -> void:
	for i in range(count):
		await physics_frame
		await process_frame

func capture(name: String) -> void:
	await frames()
	RenderingServer.force_draw(false)
	await RenderingServer.frame_post_draw
	var path := Paths.path("native-station-" + name + ".png")
	root.get_texture().get_image().save_png(path)
	print("CAPTURE " + path)

func run() -> void:
	DisplayServer.window_set_title("Ash & Iron — native crafting stations")
	change_scene_to_file("res://scenes/main.tscn")
	await scene_changed
	await frames(8)
	var player: Node3D = current_scene.get_node("Player")
	player._capture_controls(false)
	player.set_process(false)
	player.set_physics_process(false)
	player.hide()
	current_scene.get_node("HUD").hide()
	for child in player.get_children():
		if child is CanvasLayer:
			child.hide()
	var camera := Camera3D.new()
	current_scene.add_child(camera)
	camera.fov = 46
	camera.make_current()
	var bench := Workbench.new()
	current_scene.add_child(bench)
	bench.position = Vector3(10, 0.2, 12)
	camera.position = Vector3(11.8, 1.45, 14.4)
	camera.look_at(bench.position + Vector3(0, 0.55, 0))
	await capture("workbench-default")
	bench.show_copperworking()
	await capture("workbench-copper-kit")
	bench.queue_free()
	await frames()
	var furnace := Furnace.new()
	current_scene.add_child(furnace)
	furnace.set_process(false)
	furnace.position = Vector3(10, 0.2, 12)
	camera.position = Vector3(11.55, 1.38, 14.15)
	camera.look_at(furnace.position + Vector3(0, 0.48, 0))
	await capture("furnace-idle")
	furnace.ore = Furnace.ORE_PER_INGOT
	furnace.fuel = Furnace.FUEL_PER_INGOT
	furnace._refresh_fire()
	await capture("furnace-burning")
	GameSave.clear()
	quit()
