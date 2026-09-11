extends Node
## Open scenes/visual_preview.tscn and Run Current Scene for an isolated visual playground.
## Its temporary profile and save never replace the real player's data.
const Paths = preload("res://tests/test_paths.gd")
const Profile = preload("res://scripts/character_profile.gd")
const GameSave = preload("res://scripts/game_save.gd")
var world: Node3D
var preview_player: Node3D
var portrait: Camera3D
var gear_pose := -1
var portrait_angle := 0.0

func _ready() -> void:
	Profile.storage_path = Paths.path("visual_preview_profile.json")
	GameSave.storage_path = Paths.path("visual_preview_save.json")
	GameSave.clear()
	var profile := Profile.defaults()
	profile.name = "Willow Scout"
	profile.build = 0
	Profile.save_profile(profile)
	world = preload("res://scenes/main.tscn").instantiate()
	add_child(world)
	await get_tree().physics_frame
	var player: Node3D = world.get_node("Player")
	preview_player = player
	preload("res://tests/test_paths.gd").place_bench(player.get_parent())
	var chest := preload("res://scripts/storage_chest.gd").new()
	world.add_child(chest)
	chest.position = player.workbench.position + Vector3(1.6, 0, 0.8)
	for item in ["stone_axe", "bow", "stone_pickaxe", "torch"]:
		player.inventory.add(item, 1)
		player.equip_item(item)
	player.inventory.add("arrow", 10)
	player.inventory.add("stick", 6)
	player.inventory.add("stone", 4)
	player.equip_item("")
	player.global_position = Vector3(12, 1.1, 12)
	player.camera.rotation.x = -0.12
	player._capture_controls(true)
	var label := Label.new()
	label.text = "VISUAL PREVIEW • Temporary inventory / save • O: portrait • J: axe poses • K: drawn bow • L: orbit • P: capture"
	label.position = Vector2(24, 120)
	label.add_theme_font_size_override("font_size", 13)
	var hud := CanvasLayer.new()
	add_child(hud)
	hud.add_child(label)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and is_instance_valid(preview_player):
		if event.physical_keycode == KEY_O:
			if is_instance_valid(portrait):
				portrait.queue_free()
				portrait = null
				preview_player.axe.cancel_swing()
				preview_player.bow.cancel_draw()
				preview_player.view_rig.set_physics_process(true)
				preview_player.view_rig.set_mode(true)
				preview_player._capture_controls(true)
			else:
				preview_player._capture_controls(false)
				portrait = Camera3D.new()
				portrait.fov = 42
				portrait.cull_mask = 5
				add_child(portrait)
				var avatar: Node3D = preview_player.view_rig.avatar
				portrait.global_position = avatar.global_position + avatar.global_basis.z.normalized() * 3.1 + Vector3.UP * 1.25
				portrait.look_at(avatar.global_position + Vector3.UP * 0.95)
				portrait.make_current()
		if event.physical_keycode in [KEY_J, KEY_K] and is_instance_valid(portrait):
			preview_player.view_rig.set_physics_process(false)
			if event.physical_keycode == KEY_J:
				gear_pose = (gear_pose + 1) % 4
				preview_player.equip_item("stone_axe")
				preview_player.axe.elapsed = [-1.0, 0.08, 0.22, 0.32][gear_pose]
			else:
				preview_player.equip_item("bow")
				preview_player.bow.begin_draw()
				preview_player.bow.advance(0.85)
			preview_player.view_rig.avatar.animate_movement(0, 0, true, 0, preview_player.equipped_item, preview_player.axe.elapsed, preview_player.bow.charge())
			preview_player.view_rig._sync_equipment()
		if event.physical_keycode == KEY_L and is_instance_valid(portrait):
			portrait_angle += PI / 4
			var avatar: Node3D = preview_player.view_rig.avatar
			portrait.global_position = avatar.global_position + avatar.global_basis.orthonormalized() * Vector3(sin(portrait_angle) * 3.1, 1.25, cos(portrait_angle) * 3.1)
			portrait.look_at(avatar.global_position + Vector3.UP * 0.95)
		if event.physical_keycode == KEY_P:
			await RenderingServer.frame_post_draw
			var path := Paths.path("graphics_preview.png")
			get_viewport().get_texture().get_image().save_png(path)
			print("Graphics capture: %s | %.0f FPS" % [path, Engine.get_frames_per_second()])
