extends SceneTree
## Native first-person framing and grip review; all saves are temporary.
const Paths = preload("res://tests/test_paths.gd")
const Profile = preload("res://scripts/character_profile.gd")
const Save = preload("res://scripts/game_save.gd")
var output := "/tmp/first-person-hands-preview"
var player: Node3D
func _initialize() -> void:
	Profile.storage_path = Paths.path("hands_preview_profile.json")
	Save.storage_path = Paths.path("hands_preview_save.json")
	Save.clear()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="): output = arg.trim_prefix("--output=")
	DirAccess.make_dir_recursive_absolute(output)
	call_deferred("run")
func capture(label: String) -> void:
	player.update_first_person_hands()
	for i in range(3): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(label + ".png"))
	print("HAND CAPTURE " + label)
func run() -> void:
	DisplayServer.window_set_size(Vector2i(1280,800))
	change_scene_to_file("res://scenes/main.tscn")
	await scene_changed
	player = current_scene.get_node("Player")
	player._capture_controls(false)
	player.set_physics_process(false)
	current_scene.boar.set_physics_process(false)
	current_scene.bellmaw.set_physics_process(false)
	current_scene.set_process(false)
	player.global_position = Vector3(12,1.1,12)
	player.set_third_person(false)
	player.camera.rotation = Vector3(-.13,0,0)
	for layer in player.find_children("*", "CanvasLayer", true, false): layer.hide()
	current_scene.get_node("HUD").hide()
	await capture("empty")
	for item in ["stone_axe", "copper_axe", "stone_pickaxe", "stone_spear", "torch"]:
		player.inventory.add(item,1)
		player.equip_item(item)
		await capture(item + "-idle")
		if item != "torch":
			player.axe.elapsed = .08
			player.axe.pose_swing(.08)
			await capture(item + "-raised")
			player.axe.elapsed = player.axe.CONTACT_TIME
			player.axe.pose_swing(player.axe.CONTACT_TIME)
			await capture(item + "-contact")
			player.axe.cancel_swing()
	player.inventory.add("bow",1)
	player.inventory.add("arrow",4)
	player.equip_item("bow")
	await capture("bow-idle")
	player.bow.begin_draw()
	player.bow.advance(.4)
	await capture("bow-half")
	player.bow.advance(.45)
	await capture("bow-full")
	player.bow.cancel_draw()
	player.equip_item("")
	player.axe.start_swing()
	player.axe.elapsed = player.axe.CONTACT_TIME
	player.axe.pose_swing(player.axe.CONTACT_TIME)
	await capture("punch-contact")
	Save.clear()
	quit()
