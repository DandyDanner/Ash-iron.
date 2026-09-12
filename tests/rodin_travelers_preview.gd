extends SceneTree
const Paths = preload("res://tests/test_paths.gd")
const Profile = preload("res://scripts/character_profile.gd")
const Save = preload("res://scripts/game_save.gd")
func _initialize() -> void:
	Profile.storage_path = Paths.path("rodin_review_profile.json")
	Save.storage_path = Paths.path("rodin_review_save.json")
	call_deferred("run")
func frames(n: int = 5) -> void:
	for i in range(n):
		await physics_frame
		await process_frame
func capture(name: String) -> void:
	await frames()
	RenderingServer.force_draw(false)
	root.get_texture().get_image().save_png(Paths.path("rodin-" + name + ".png"))
	print("CAPTURE " + Paths.path("rodin-" + name + ".png"))
func run() -> void:
	DisplayServer.window_set_title("Ash & Iron — Rodin travelers in game")
	for design in range(4):
		Save.clear()
		var only := -1
		for arg in OS.get_cmdline_user_args():
			if arg.begins_with("--only="): only = arg.trim_prefix("--only=").to_int()
		if only >= 0 and design != only: continue
		var profile := Profile.defaults()
		profile.traveler = design
		Profile.save_profile(profile)
		change_scene_to_file("res://scenes/main.tscn")
		await scene_changed
		await frames(8)
		var player: Node3D = current_scene.get_node("Player")
		player._capture_controls(false)
		player.set_physics_process(false)
		player.view_rig.set_physics_process(false)
		current_scene.set_process(false)
		current_scene.get_node("HUD").hide()
		for child in player.get_children():
			if child is CanvasLayer: child.hide()
		player.position = Vector3(8, 1.1, 12)
		var avatar: Node3D = player.view_rig.avatar
		var camera := Camera3D.new()
		current_scene.add_child(camera)
		camera.cull_mask = 5
		camera.fov = 36
		camera.make_current()
		camera.position = avatar.to_global(Vector3(0, 1.2, 4.2))
		camera.look_at(avatar.to_global(Vector3(0, 1.1, 0)))
		await capture("%d-idle" % design)
		camera.position = avatar.to_global(Vector3(.04, 1.86, 1.3))
		camera.look_at(avatar.to_global(Vector3(.04, 1.85, 0)))
		await capture("%d-face" % design)
		if design == 1:
			for side in [-1, 1]:
				camera.position = avatar.to_global(Vector3(side * .75, 1.86, 1.1))
				camera.look_at(avatar.to_global(Vector3(.04, 1.85, 0)))
				await capture("1-face-side-%d" % side)
			camera.position = avatar.to_global(Vector3(.04, 1.86, 1.3))
			camera.look_at(avatar.to_global(Vector3(.04, 1.85, 0)))
			for side in [-1, 1]:
				avatar.head.rotation.y = side * .4
				avatar.authored.sync()
				await capture("1-head-turn-%d" % side)
			avatar.head.rotation.y = 0
			avatar.authored.sync()
		camera.position = avatar.to_global(Vector3(1.4, 1.4, 3.4))
		camera.look_at(avatar.to_global(Vector3(0, 1, 0)))
		for item in ["stone_axe", "bow", ""]:
			if not item.is_empty():player.inventory.add(item, 1)
			player.equip_item(item)
			avatar.animate_movement(.01, 0, true, 0, item, -1, 0)
			player.view_rig._sync_equipment()
			camera.make_current()
			await frames()
			await capture("%d-held-%s" % [design,item])
		avatar.animate_movement(.15, 5, true, 0, "", -1, 0)
		avatar.sync_authored_pose()
		await capture("%d-stride" % design)
	Save.clear()
	DirAccess.remove_absolute(Profile.storage_path)
	quit()
