extends SceneTree
const Profile = preload("res://scripts/character_profile.gd")
const GameSave = preload("res://scripts/game_save.gd")
const Paths = preload("res://tests/test_paths.gd")
var failures := 0
var screenshots := ""

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _initialize() -> void:
	Profile.storage_path = Paths.path("traveler_selection_profile_%d.json" % Time.get_ticks_usec())
	GameSave.storage_path = Paths.path("traveler_selection_world_%d.json" % Time.get_ticks_usec())
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--screenshots="): screenshots = arg.trim_prefix("--screenshots=")
	call_deferred("run")

func frames(count: int = 4) -> void:
	for i in range(count):
		await physics_frame
		await process_frame

func capture(name: String) -> void:
	if screenshots.is_empty() or DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(screenshots.path_join(name + ".png")) == OK, "Failed to save runtime review")

func run() -> void:
	var legacy := Profile.defaults()
	legacy.erase("traveler")
	legacy.version = 1
	legacy.skin = 4
	legacy.hair = 3
	check(Profile.clean(legacy).traveler == 4 and Profile.clean(legacy).skin == 4 and Profile.clean(legacy).hair == 3, "Existing customized travelers were not preserved")
	check(Profile.clean({"traveler": 99}).traveler == 4 and Profile.clean({"traveler": -4}).traveler == 0, "Invalid model choice was not bounded")
	for design in range(4):
		change_scene_to_file("res://scenes/character_creator.tscn")
		await scene_changed
		await frames()
		var creator := current_scene
		creator.name_input.text = "Rowan"
		creator.name_input.text_changed.emit("Rowan")
		creator.choices.traveler.item_selected.emit(design)
		await frames()
		check(creator.profile.traveler == design and creator.choices.traveler.selected == design, "Design menu did not select the requested model")
		check(not creator.appearance_controls.visible, "Preset shows controls that do not change its model")
		var avatar: Node3D = creator.traveler
		check(avatar.body.get_meta("traveler_design", -1) == design, "Preview uses the wrong export")
		check(avatar.authored.skeleton.get_bone_count() == 14, "Export is missing its animation skeleton")
		for mesh in avatar.body.find_children("*", "MeshInstance3D", true, false):
			if mesh.skin == null: continue
			check(mesh.skin.get_bind_count() == 14, "Mesh is not bound to the rig")
			for surface in range(mesh.mesh.get_surface_count()):
				var material: StandardMaterial3D = mesh.get_active_material(surface)
				check(material.vertex_color_use_as_albedo, "Imported colors are disabled")
				check(material.albedo_texture != null, "Rodin surface lost its painted texture")
				if material.albedo_texture != null:
					check(material.albedo_texture.get_width() == 2048, "Rodin atlas detail was lost during import")
		var hand_sides := {"Left": false, "Right": false}
		for mesh in avatar.authored.finger_meshes:
			for side in hand_sides:
				if side in mesh.name: hand_sides[side] = true
		check(hand_sides.Left and hand_sides.Right, "Rodin open fingers were not separated for both weapon grips")
		await capture("creator-%d" % design)
		creator.begin_button.pressed.emit()
		await scene_changed
		await frames(8)
		var player: Node3D = current_scene.get_node("Player")
		player._capture_controls(false)
		avatar = player.view_rig.avatar
		check(avatar.body.get_meta("traveler_design", -1) == design and Profile.load_profile().traveler == design, "Chosen traveler did not persist into the clearing")
		if design == 0: player.inventory.add("stone", 7)
		check(player.inventory.count("stone") == 7, "Changing travelers reset inventory")
		var rig: Node3D = player.view_rig
		var sk: Skeleton3D = avatar.authored.skeleton
		var bone := sk.find_bone("LeftLeg")
		var before: Transform3D = sk.get_bone_global_pose(bone)
		avatar.animate_movement(.15, 5.0, true, 0, "", -1, 0)
		avatar.sync_authored_pose()
		sk.force_update_all_bone_transforms()
		check(not sk.get_bone_global_pose(bone).is_equal_approx(before), "Walking did not animate the imported skin")
		avatar.animate_movement(.1, 0, false, 3, "", -1, 0)
		avatar.sync_authored_pose()
		check(avatar.knees[0].rotation.x > .4, "Jump pose missing")
		for item in ["stone_axe", "stone_pickaxe", "bow", "stone_spear", ""]:
			if not item.is_empty(): player.inventory.add(item, 1)
			player.equip_item(item)
			await frames()
			for i in range(sk.get_bone_count()): check(sk.get_bone_global_pose(i).is_finite(), "Non-finite pose while equipping " + item)
			if item == "stone_axe":
				check(not avatar.open_right_fingers.visible, "Axe grip left the open fingers visible")
				for mesh in avatar.authored.finger_meshes:
					if "Right" in mesh.name: check(not mesh.visible, "Imported open fingers did not follow tool grip")
				await capture("axe-%d" % design)
			if item in ["stone_axe", "stone_pickaxe"]:
				var lateral := 0.0
				for frame in range(61):
					avatar.animate_movement(.01, 5, true, 0, item, frame / 100.0, 0)
					avatar.sync_authored_pose()
					var head_point: Vector3 = avatar.to_local(rig.held[item].to_global(Vector3(0, .46, 0)))
					if frame == 0: lateral = head_point.x
					check(absf(head_point.x - lateral) < .001, "Traveler %d tool swing moved sideways" % design)
				await frames()
			if not screenshots.is_empty():
				var portrait := Camera3D.new()
				current_scene.add_child(portrait)
				portrait.cull_mask = 5
				portrait.fov = 40
				portrait.global_position = avatar.global_position + avatar.global_basis.orthonormalized() * Vector3(1.5, 1.3, 3.2)
				portrait.look_at(avatar.global_position + Vector3.UP * .95)
				portrait.make_current()
				await frames()
				await capture("held-%d-%s" % [design, item])
				portrait.queue_free()
				await frames()
		player.world.save_game()
		await capture("clearing-%d" % design)
	# Reopening and selecting the old custom look restores the original controls.
	change_scene_to_file("res://scenes/character_creator.tscn")
	await scene_changed
	await frames()
	current_scene.choices.traveler.item_selected.emit(4)
	check(current_scene.appearance_controls.visible and current_scene.traveler.authored == null, "Original customization is unavailable")
	GameSave.clear()
	DirAccess.remove_absolute(Profile.storage_path)
	print("TRAVELER SELECTION: %s" % ("PASS — four skinned previews, persisted world models, movement/equipment and old-profile preservation" if failures == 0 else "FAIL"))
	quit(1 if failures else 0)
