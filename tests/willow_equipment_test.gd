extends SceneTree
## Earned archery visuals: no sculpted bow, clean carry fit, and inventory ownership.
const Profile = preload("res://scripts/character_profile.gd")
const Save = preload("res://scripts/game_save.gd")
const Paths = preload("res://tests/test_paths.gd")
var failures := 0
var player: Node3D
var camera: Camera3D

func _initialize() -> void:
	Profile.storage_path = Paths.path("willow_equipment_profile.json")
	Save.storage_path = Paths.path("willow_equipment_save.json")
	Save.clear()
	Profile.save_profile(Profile.defaults())
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func frames(n: int = 4) -> void:
	for i in range(n):
		await physics_frame
		await process_frame

func capture(label: String, offset := Vector3(0, 1.35, -3.9)) -> void:
	if not "--screenshots" in OS.get_cmdline_user_args(): return
	var avatar: Node3D = player.view_rig.avatar
	camera.position = avatar.to_global(offset)
	camera.look_at(avatar.to_global(Vector3(0, 1.2, 0)))
	camera.make_current()
	await frames()
	RenderingServer.force_draw(false)
	var path := Paths.path("willow-equipment-" + label + ".png")
	root.get_texture().get_image().save_png(path)
	print("CAPTURE " + path)

func check_model_and_carry() -> void:
	var body: Node3D = player.view_rig.avatar.body
	var back_surface := {}
	var baked_bow_tip := false
	for mesh in body.find_children("*", "MeshInstance3D", true, false):
		if mesh.skin == null: continue
		for surface in range(mesh.mesh.get_surface_count()):
			var vertices: PackedVector3Array = mesh.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]
			for point in vertices:
				if point.x > .28 and point.y > 1.85: baked_bow_tip = true
				var cell := Vector2i(floori(point.x / .04), floori(point.y / .04))
				back_surface[cell] = minf(back_surface.get(cell, INF), point.z)
	check(not baked_bow_tip, "Willow still has the sculpted bow above her shoulder")
	# Compare the carry mesh against the rear envelope of the authored clothing/bag.
	var sampled := 0
	var overlaps := 0
	for prop in [player.view_rig.back_bow, player.view_rig.quiver]:
		var closest := INF
		for mesh in prop.find_children("*", "MeshInstance3D", true, false):
			for surface in range(mesh.mesh.get_surface_count()):
				var vertices: PackedVector3Array = mesh.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]
				for local_point in vertices:
					var point: Vector3 = body.to_local(mesh.to_global(local_point))
					var cell := Vector2i(floori(point.x / .04), floori(point.y / .04))
					if not back_surface.has(cell): continue
					sampled += 1
					closest = minf(closest, float(back_surface[cell]) - point.z)
					if point.z > float(back_surface[cell]) - .015: overlaps += 1
		print("CARRY CLEARANCE %s: %.3f m" % [prop.name, closest])
	check(sampled > 100 and overlaps == 0, "Stowed bow/quiver intersects Willow's bag: %d / %d samples" % [overlaps, sampled])

func run() -> void:
	change_scene_to_file("res://scenes/main.tscn")
	await scene_changed
	await frames()
	player = current_scene.get_node("Player")
	player.set_physics_process(false)
	player.view_rig.set_physics_process(false)
	player.inventory.restore([])
	player.equip_item("")
	var rig: Node3D = player.view_rig
	player.global_position = Vector3(8, 1.1, 12)
	camera = Camera3D.new()
	current_scene.add_child(camera)
	camera.cull_mask = 5
	camera.fov = 36
	current_scene.get_node("HUD").hide()
	for child in player.get_children():
		if child is CanvasLayer: child.hide()
	rig._sync_equipment()
	check(not rig.held_bow.visible and not rig.back_bow.visible and not rig.quiver.visible, "Fresh Willow starts with archery equipment")
	check_model_and_carry()
	await capture("fresh-back")
	await capture("fresh-front", Vector3(.6, 1.35, 3.9))
	var bench := Paths.place_bench(current_scene, Vector3(8, .2, 10))
	player.global_position = bench.global_position + Vector3(0, .9, 2)
	player.inventory.restore([{"item": "wood", "amount": 10}, {"item": "stick", "amount": 10}, {"item": "stone", "amount": 10}])
	await frames()
	check(player.craft_recipe("bow").begins_with("Crafted"), "Fixture could not craft the earned bow")
	rig._sync_equipment()
	check(rig.held_bow.visible and not rig.back_bow.visible, "Crafted bow is missing or duplicated while held")
	rig.avatar.animate_movement(.01, 0, true, 0, "bow", -1, 0)
	rig._sync_equipment()
	await capture("held-front", Vector3(1.4, 1.35, 3.6))
	check(player.craft_recipe("arrows").begins_with("Crafted"), "Fixture could not craft arrows")
	player.equip_item("")
	rig.avatar.animate_movement(.01, 0, true, 0, "", -1, 0)
	rig._sync_equipment()
	check(rig.back_bow.visible and not rig.held_bow.visible and rig.arrow_feathers.visible, "Owned bow/arrows do not appear when stowed")
	await capture("crafted-back")
	await capture("crafted-side", Vector3(3.4, 1.4, -.8))
	var chest := preload("res://scripts/storage_chest.gd").new()
	current_scene.add_child(chest)
	for i in range(player.inventory.slots.size()):
		if player.inventory.slots[i].get("item", "") in ["bow", "arrow"]:
			player.inventory.move_slot(i, chest.storage)
	await frames()
	rig._sync_equipment()
	check(chest.storage.count("bow") == 1 and not rig.back_bow.visible and not rig.held_bow.visible and not rig.quiver.visible, "Stored bow/arrows remain attached to Willow")
	await capture("stored-back")
	Save.clear()
	DirAccess.remove_absolute(Profile.storage_path)
	print("WILLOW EQUIPMENT: %s" % ("PASS" if failures == 0 else "FAIL"))
	quit(1 if failures else 0)
