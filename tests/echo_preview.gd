extends SceneTree
## Native renderer review: isolated profile/world, three captures, then closes its own window.
const Paths = preload("res://tests/test_paths.gd")
const Profile = preload("res://scripts/character_profile.gd")
const Save = preload("res://scripts/game_save.gd")

func _initialize() -> void:
	Profile.storage_path = Paths.path("echo_review_profile.json")
	Save.storage_path = Paths.path("echo_review_save.json")
	Save.clear()
	call_deferred("run")

func frames(count: int = 15) -> void:
	for i in range(count): await process_frame

func capture(filename: String) -> void:
	await frames()
	await RenderingServer.frame_post_draw
	var path := Paths.path(filename)
	root.get_texture().get_image().save_png(path)
	print("CAPTURE: " + path)

func run() -> void:
	DisplayServer.window_set_title("Ash & Iron — isolated Echo Hollow review")
	change_scene_to_file("res://scenes/main.tscn")
	await scene_changed
	await frames()
	var player: Node3D = current_scene.get_node("Player")
	var bell: Node3D = current_scene.bellmaw
	player._capture_controls(false)
	current_scene.set_process(false)
	var camera := Camera3D.new()
	camera.fov = 43
	current_scene.add_child(camera)
	camera.position = bell.position + Vector3(3.1, 2.0, 4.6)
	camera.look_at(bell.position + Vector3.UP * 0.8)
	camera.make_current()
	for child in player.get_children():
		if child is CanvasLayer: child.hide()
	current_scene.get_node("HUD").hide()
	await capture("bellmaw-engine-idle.png")
	bell._set_state("warn")
	bell.state_time = 1.2
	bell.art.pose(0, 0, "warn", 1.2, 0)
	camera.position = bell.position + Vector3(6.5, 5.5, 8.5)
	camera.look_at(bell.position + Vector3.UP * 0.6)
	await capture("echo-hollow-engine.png")
	# Exercise the real pack button, with the earned material supplied only in this test save.
	Paths.place_bench(current_scene)
	player.global_position = Vector3(-3.5, 1.1, 2.5)
	player.inventory.add("bellmaw_hide", 1)
	player.inventory.add("wood", 2)
	player.inventory.add("stick", 4)
	player.craft_recipe("explorer_pack")
	player.inventory.add("stone_spear", 1)
	player.inventory.add("bow", 1)
	player.inventory.add("arrow", 10)
	for child in player.get_children():
		if child is CanvasLayer: child.show()
	player.open_inventory()
	player.inventory_panel._select_recipe("explorer_pack")
	player.inventory_panel.refresh()
	await capture("explorer-pack-engine.png")
	Save.clear()
	quit()
