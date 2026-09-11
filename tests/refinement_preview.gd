extends SceneTree
## Captures the actual updated hands, Bellmaw and linked furnace using temporary saves only.
const Paths = preload("res://tests/test_paths.gd")
const Profile = preload("res://scripts/character_profile.gd")
const Save = preload("res://scripts/game_save.gd")
var output := Paths.path("refinement_captures")

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="): output = arg.trim_prefix("--output=")
	Profile.storage_path = Paths.path("refinement_preview_profile.json")
	Save.storage_path = Paths.path("refinement_preview_save.json")
	Save.clear()
	call_deferred("run")

func frames(count: int = 25) -> void:
	for i in range(count): await process_frame

func capture(filename: String) -> void:
	await frames()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(filename + ".png"))
	print("REFINEMENT CAPTURE: " + filename)

func run() -> void:
	DirAccess.make_dir_recursive_absolute(output)
	change_scene_to_file("res://scenes/main.tscn")
	await scene_changed
	await frames()
	var player: Node3D = current_scene.get_node("Player")
	player._capture_controls(false)
	player.global_position = Vector3(12,1.1,12)
	player.set_third_person(false)
	player.camera.rotation = Vector3(-0.13,0,0)
	player.update_first_person_hands()
	await capture("hands-relaxed")
	for item in ["stone_axe", "stone_pickaxe", "stone_spear", "bow"]:
		player.inventory.add(item,1)
		player.equip_item(item)
		if item == "bow":
			player.inventory.add("arrow",1)
			player.bow.begin_draw()
			player.bow.advance(0.85)
		player.update_first_person_hands()
		await capture("hands-" + item)
	for layer in player.find_children("*", "CanvasLayer", true, false): layer.hide()
	current_scene.get_node("HUD").hide()
	var bell: Node3D = current_scene.bellmaw
	var camera := Camera3D.new()
	current_scene.add_child(camera)
	camera.fov = 43
	camera.position = bell.position + Vector3(3.1,2,4.6)
	camera.look_at(bell.position + Vector3.UP * 0.8)
	camera.make_current()
	await capture("bellmaw-idle")
	bell._set_state("warn")
	bell.art.pose(0,0,"warn",1.1,0)
	await capture("bellmaw-warning")
	var chest := preload("res://scripts/storage_chest.gd").new()
	current_scene.add_child(chest)
	chest.position = Vector3(14,0.2,12)
	chest.storage.add("iron_ore",8)
	chest.storage.add("wood",4)
	var furnace := preload("res://scripts/furnace.gd").new()
	current_scene.add_child(furnace)
	furnace.position = Vector3(12,0.2,10)
	furnace.advance(5)
	player.furnace_panel.get_parent().show()
	player.camera.make_current()
	player.open_furnace(furnace)
	await capture("furnace-linked")
	Save.clear()
	quit()
