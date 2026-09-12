extends SceneTree
const Paths = preload("res://tests/test_paths.gd")
const Profile = preload("res://scripts/character_profile.gd")
const Save = preload("res://scripts/game_save.gd")
const Props = preload("res://scripts/imported_props.gd")
func _initialize() -> void:
	Profile.storage_path = Paths.path("props_review_profile.json")
	Save.storage_path = Paths.path("props_review_save.json")
	Save.clear()
	call_deferred("run")
func frames(n: int = 5) -> void:
	for i in range(n):
		await physics_frame
		await process_frame
func capture(name: String) -> void:
	await frames()
	RenderingServer.force_draw(false)
	root.get_texture().get_image().save_png(Paths.path("props-" + name + ".png"))
	print("CAPTURE " + Paths.path("props-" + name + ".png"))
func run() -> void:
	DisplayServer.window_set_title("Ash & Iron — supplied trees, chest and ore")
	change_scene_to_file("res://scenes/main.tscn")
	await scene_changed
	await frames()
	var player: Node3D = current_scene.get_node("Player")
	player._capture_controls(false)
	player.set_physics_process(false)
	current_scene.set_process(false)
	current_scene.get_node("HUD").hide()
	for child in player.get_children():
		if child is CanvasLayer: child.hide()
	var camera := Camera3D.new()
	current_scene.add_child(camera)
	camera.cull_mask = 1 | 4
	camera.fov = 55
	camera.make_current()
	player.position = Vector3(-2, 1.1, 0)
	camera.position = Vector3(4, 3.4, 7)
	camera.look_at(Vector3(0, 2.6, 0))
	await capture("pine-close")
	camera.position = Vector3(17, 12, 24)
	camera.look_at(Vector3(0, 1.5, 0))
	await capture("forest")
	var lineup := Node3D.new()
	current_scene.add_child(lineup)
	lineup.position = Vector3(10, .2, 12)
	for i in range(3):
		var kind: String = ["stone", "copper_ore", "iron_ore"][i]
		var rock := Props.rock(lineup, Vector3(2, 1.5, 1.7), kind)
		rock.position.x = (i - 1) * 2.6
		var label := Label3D.new()
		label.text = ["STONE", "COPPER", "IRON"][i]
		label.position = rock.position + Vector3(0, 1.9, 0)
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.font_size = 38
		label.pixel_size = .008
		lineup.add_child(label)
	camera.position = Vector3(11, 4.8, 20)
	camera.look_at(Vector3(10, .9, 12))
	await capture("ore-variants")
	lineup.queue_free()
	await frames()
	var chest := preload("res://scripts/storage_chest.gd").new()
	current_scene.add_child(chest)
	chest.position = Vector3(10, .2, 12)
	camera.position = Vector3(11.3, 1.4, 13.6)
	camera.look_at(chest.position + Vector3(0, .35, 0))
	await capture("chest-closed")
	chest.set_open(true)
	await frames(22)
	await capture("chest-open")
	chest.set_open(false)
	await frames(22)
	await capture("chest-closed-again")
	Save.clear()
	quit()
