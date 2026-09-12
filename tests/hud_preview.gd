extends SceneTree
## Captures the HUD, backpack and crafting panels, the first-person axe swing and the punch:
## Godot --path . --script res://tests/hud_preview.gd -- --out=/absolute/folder
const Profile = preload("res://scripts/character_profile.gd")
const GameSave = preload("res://scripts/game_save.gd")
const Paths = preload("res://tests/test_paths.gd")
var out := ""

func _initialize() -> void:
	Profile.storage_path = Paths.path("hud_preview_profile.json")
	GameSave.storage_path = Paths.path("hud_preview_save.json")
	GameSave.clear()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out = arg.trim_prefix("--out=")
	call_deferred("run")

func ticks(count: int) -> void:
	for i in range(count):
		await physics_frame
		await process_frame

func capture(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	print("CAPTURE ", name, " ", root.get_texture().get_image().save_png(out.path_join(name + ".png")) == OK)

func run() -> void:
	change_scene_to_file("res://scenes/main.tscn")
	await scene_changed
	await ticks(10)
	var player: Node3D = current_scene.get_node("Player")
	player._capture_controls(true)
	player.set_third_person(false)
	player.global_position = Vector3(0, 1.1, 2)
	player.rotation = Vector3.ZERO
	player.camera.rotation = Vector3.ZERO
	player.inventory.add("stone_axe", 1)
	player.inventory.add("stick", 7)
	player.inventory.add("stone", 5)
	player.inventory.add("wood", 3)
	player.equip_item("stone_axe")
	player.health = 66
	player.stamina.value = 43
	await ticks(20)
	await capture("hud-axe-ready")
	for frame in [["swing-windup", 3], ["swing-contact", 10], ["swing-follow", 6], ["swing-recover", 8]]:
		if frame[0] == "swing-windup":
			player.axe.start_swing()
		await ticks(frame[1])
		await capture(frame[0])
	await ticks(30)
	player.equip_item("")
	await ticks(5)
	await capture("hands-empty")
	player.axe.start_swing()
	await ticks(12)
	await capture("punch-contact")
	await ticks(40)
	player.open_inventory()
	await ticks(8)
	await capture("backpack")
	player.inventory_panel._select_recipe("bow")
	await ticks(4)
	await capture("backpack-bow-recipe")
	player.close_inventory()
	player.inventory.add("chest", 1)
	await ticks(4)
	player.place_selected(player.inventory.slots.size() - 1)
	await ticks(6)
	for chest in get_nodes_in_group("chests"):
		player.open_storage(chest)
		await ticks(8)
		await capture("storage")
		player.close_storage()
		break
	await ticks(4)
	player.set_third_person(true)
	await ticks(30)
	await capture("hud-third-person")
	GameSave.clear()
	quit()
