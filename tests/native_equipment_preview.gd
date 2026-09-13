extends SceneTree
## Playable native review: held grips, axe/spear contact, and actual full bow draw.
const Paths = preload("res://tests/test_paths.gd")
const Profile = preload("res://scripts/character_profile.gd")
const Save = preload("res://scripts/game_save.gd")
const Pickup = preload("res://scripts/resource_pickup.gd")
var output := Paths.path("native-equipment-review")
var player: Node3D


func _initialize() -> void:
	Profile.storage_path = Paths.path("native_equipment_preview_profile.json")
	Save.storage_path = Paths.path("native_equipment_preview_save.json")
	Save.clear()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--screenshots="):
			output = arg.trim_prefix("--screenshots=")
	DirAccess.make_dir_recursive_absolute(output)
	call_deferred("run")


func frames(count: int = 8) -> void:
	for i in range(count):
		await physics_frame
		await process_frame


func capture(label: String) -> void:
	await frames()
	await RenderingServer.frame_post_draw
	var path := output.path_join(label + ".png")
	root.get_texture().get_image().save_png(path)
	print("CAPTURE " + path)


func show_tool(item: String, third: bool, time: float) -> void:
	player.equip_item(item)
	player.set_third_person(third)
	player.axe.elapsed = time
	player.axe.pose_swing(time)
	player.view_rig.avatar.animate_movement(0, 0, true, 0, item, time, 0)
	player.view_rig._sync_equipment()
	await capture(("third-" if third else "first-") + item + ("-contact" if time >= 0 else "-grip"))
	if third:
		var side_camera := Camera3D.new()
		current_scene.add_child(side_camera)
		side_camera.cull_mask = 5
		side_camera.fov = 44 if item == "stone_spear" else 34
		side_camera.global_position = player.view_rig.avatar.to_global(Vector3(3.2, 1.35, .1))
		side_camera.look_at(player.view_rig.avatar.to_global(Vector3(0, 1.25, -.62 if item == "stone_spear" else -.25)))
		side_camera.make_current()
		await capture("third-side-" + item + ("-contact" if time >= 0 else "-grip"))
		side_camera.queue_free()


func show_bow(third: bool) -> void:
	player.equip_item("bow")
	player.set_third_person(third)
	player.bow.drawing = true
	player.bow.draw_time = player.bow.DRAW_TIME
	player.bow._refresh()
	player.view_rig.avatar.animate_movement(0, 0, true, 0, "bow", -1, 1)
	player.view_rig._sync_equipment()
	await capture(("third" if third else "first") + "-bow-full-draw")
	if third:
		var side_camera := Camera3D.new()
		current_scene.add_child(side_camera)
		side_camera.cull_mask = 5
		side_camera.fov = 38
		side_camera.global_position = player.view_rig.avatar.to_global(Vector3(3.2, 1.35, .15))
		side_camera.look_at(player.view_rig.avatar.to_global(Vector3(0, 1.30, .15)))
		side_camera.make_current()
		await capture("side-bow-full-draw")
		side_camera.queue_free()
	player.bow.cancel_draw()


func show_carry() -> void:
	player.equip_item("")
	player.set_third_person(true)
	player.view_rig.avatar.animate_movement(0, 0, true, 0, "", -1, 0)
	player.view_rig._sync_equipment()
	await capture("third-carried-bow-quiver-arrows")


func show_dropped_lineup() -> void:
	player.global_position = Vector3(0, 1.1, 12)
	var items := ["stone_axe", "copper_axe", "stone_pickaxe", "stone_spear", "bow", "arrow"]
	var pickups: Array[Node3D] = []
	for index in range(items.size()):
		var pickup := Pickup.new()
		pickup.item_id = items[index]
		pickup.amount = 1
		current_scene.add_child(pickup)
		var row := index / 3
		var column := index % 3
		pickup.global_position = Vector3(8.5 + column * 1.5, .12, -7.5 + row * 1.35)
		if items[index] in ["stone_spear", "bow", "arrow"]:
			pickup.rotation.y = PI / 2
		pickups.append(pickup)
	var review_camera := Camera3D.new()
	current_scene.add_child(review_camera)
	review_camera.global_position = Vector3(10, 3.7, -2.5)
	review_camera.look_at(Vector3(10, .10, -6.8))
	review_camera.fov = 39
	review_camera.make_current()
	await capture("dropped-equipment-grounded")
	for pickup in pickups:
		pickup.queue_free()
	review_camera.queue_free()


func show_packed_stations() -> void:
	var pickups: Array[Node3D] = []
	for index in range(2):
		var pickup := Pickup.new()
		pickup.item_id = ["bench", "furnace"][index]
		pickup.amount = 1
		current_scene.add_child(pickup)
		pickup.global_position = Vector3(9.1 + index * 1.8, .08, -6.4)
		pickup.rotation.y = -.25 if index == 0 else .25
		pickups.append(pickup)
	var review_camera := Camera3D.new()
	current_scene.add_child(review_camera)
	review_camera.global_position = Vector3(10, 2.2, -3.5)
	review_camera.look_at(Vector3(10, .22, -6.4))
	review_camera.fov = 35
	review_camera.make_current()
	await capture("packed-native-workbench-furnace-grounded-cold")
	for pickup in pickups:
		pickup.queue_free()
	review_camera.queue_free()


func run() -> void:
	change_scene_to_file("res://scenes/main.tscn")
	await scene_changed
	await frames(10)
	player = current_scene.get_node("Player")
	player._capture_controls(false)
	player.global_position = Vector3(10, 1.1, -4)
	player.rotation = Vector3.ZERO
	player.camera.rotation = Vector3.ZERO
	player.inventory.restore([
		{"item": "stone_axe", "amount": 1}, {"item": "copper_axe", "amount": 1},
		{"item": "stone_pickaxe", "amount": 1}, {"item": "stone_spear", "amount": 1},
		{"item": "bow", "amount": 1}, {"item": "arrow", "amount": 5},
	])
	await show_tool("stone_axe", false, .22)
	await show_tool("copper_axe", true, .22)
	await show_tool("stone_pickaxe", false, .22)
	await show_tool("stone_spear", true, .22)
	await show_bow(false)
	await show_bow(true)
	await show_carry()
	await show_dropped_lineup()
	await show_packed_stations()
	Save.clear()
	print("NATIVE EQUIPMENT PREVIEW: PASS — first/third grip, attack contact, and full draw captures")
	quit()
