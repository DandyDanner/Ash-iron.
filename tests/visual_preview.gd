extends Node
## Open scenes/visual_preview.tscn and Run Current Scene for an isolated visual playground.
## Its temporary profile and save never replace the real player's data.
const Paths = preload("res://tests/test_paths.gd")
const Profile = preload("res://scripts/character_profile.gd")
const GameSave = preload("res://scripts/game_save.gd")
var world: Node3D
var preview_player: Node3D
var portrait: Camera3D

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
	player.workbench.build()
	var chest := preload("res://scripts/storage_chest.gd").new()
	world.add_child(chest)
	chest.position = player.workbench.position + Vector3(1.6, 0, 0.8)
	for item in ["stone_axe", "bow", "stone_pickaxe", "torch"]:
		player.inventory.add(item, 1)
		player.equip_item(item)
	player.inventory.add("arrow", 10)
	player.equip_item("")
	player.global_position = Vector3(0, 1.1, 6)
	player.camera.rotation.x = -0.12
	player._capture_controls(true)
	var label := Label.new()
	label.text = "VISUAL PREVIEW • Temporary inventory / save • O: portrait • P: capture"
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
				preview_player.view_rig.set_mode(true)
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
		if event.physical_keycode == KEY_P:
			await RenderingServer.frame_post_draw
			var path := Paths.path("graphics_preview.png")
			get_viewport().get_texture().get_image().save_png(path)
			print("Graphics capture: %s | %.0f FPS" % [path, Engine.get_frames_per_second()])
