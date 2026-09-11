extends SceneTree
const Profile = preload("res://scripts/character_profile.gd")
const GameSave = preload("res://scripts/game_save.gd")
var failures := 0
var screenshot_dir := ""

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _initialize() -> void:
	Profile.storage_path = preload("res://tests/test_paths.gd").path("character_test_%s.json" % Time.get_ticks_usec())
	# World progress is isolated too: entering the clearing must never read or write the player's real save.
	GameSave.storage_path = preload("res://tests/test_paths.gd").path("unused_character_creation_test_save.json")
	GameSave.clear()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--screenshots="):
			screenshot_dir = arg.trim_prefix("--screenshots=")
	call_deferred("run")

func capture(filename: String) -> void:
	if not screenshot_dir.is_empty() and DisplayServer.get_name() != "headless":
		await process_frame
		await RenderingServer.frame_post_draw
		var result := root.get_texture().get_image().save_png(screenshot_dir.path_join(filename))
		check(result == OK, "Screenshot write failed")

func run() -> void:
	var clean := Profile.clean({"name": "  Rowan\nVale  ", "skin": 999, "hair": -2, "face": "invalid"})
	check(clean.name == "Rowan Vale" and clean.skin == 5 and clean.hair == 0 and clean.face == 0, "Invalid save data was not normalized")
	var corrupt := FileAccess.open(Profile.storage_path, FileAccess.WRITE)
	corrupt.store_string("broken json")
	corrupt.close()
	check(Profile.load_profile() == Profile.defaults(), "Malformed save did not fall back safely")
	DirAccess.remove_absolute(Profile.storage_path)
	change_scene_to_file("res://scenes/character_creator.tscn")
	await scene_changed
	await process_frame
	var creator := current_scene
	check(creator.profile.background == 2, "Wrong default background")
	await capture("character-creator.png")
	creator.name_input.text = "Rowan"
	creator.name_input.text_changed.emit("Rowan")
	creator._choose("skin", 4)
	creator._choose("hair", 4)
	creator._choose("face", 2)
	creator._choose("build", 2)
	creator._choose("clothes", 1)
	creator._choose("keepsake", 1)
	for background in range(4):
		creator.background_buttons[background].pressed.emit()
		check(creator.profile.name == "Rowan" and creator.profile.skin == 4 and creator.profile.hair == 4, "Background reset personalized appearance")
		check(creator.story.text == Profile.STORIES[background], "Story did not update")
		check(creator.traveler.body.get_child_count() > 20, "Character preview missing geometry")
		check(creator.background_buttons[background].button_pressed, "Background not selected")
		await capture("background-%d.png" % background)
	for key in ["hair", "build", "face", "keepsake", "skin", "hair_color", "clothes"]:
		var count: int = {"hair": 6, "build": 3, "face": 3, "keepsake": 4, "skin": 6, "hair_color": 6, "clothes": 6}[key]
		for value in range(count):
			creator._choose(key, value)
			await process_frame
	# Exercise the actual Begin button, save, scene transition, and reopened creator.
	var expected: Dictionary = creator.profile.duplicate(true)
	creator.find_child("BeginJourney", true, false).pressed.emit()
	await scene_changed
	await process_frame
	check(current_scene.name == "Main", "Begin did not open the test area")
	check(Profile.load_profile() == Profile.clean(expected), "Saved appearance differs from selection")
	var player := current_scene.get_node("Player")
	check(player.identity_label.text.contains("Rowan"), "World HUD lost the chosen identity")
	check(player.camera.has_node("LeftHand") and player.camera.has_node("StarterAxe/RightHand"), "First-person hands and sleeves missing")
	await capture("traveler-in-clearing.png")
	var event := InputEventKey.new()
	event.pressed = true
	event.physical_keycode = KEY_C
	player._unhandled_input(event)
	await scene_changed
	await process_frame
	check(current_scene.profile == Profile.clean(expected), "Reopening the creator lost saved choices")
	check(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "Creator did not release mouse")
	DirAccess.remove_absolute(Profile.storage_path)
	GameSave.clear()
	print("CHARACTER CREATION: %s" % ("PASS — all appearances, background preservation, save round trip, world entry, and reopening" if failures == 0 else "FAIL"))
	quit(1 if failures else 0)
