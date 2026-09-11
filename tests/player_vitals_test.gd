extends SceneTree
const Paths = preload("res://tests/test_paths.gd")
const Profile = preload("res://scripts/character_profile.gd")
const Save = preload("res://scripts/game_save.gd")
const Stamina = preload("res://scripts/stamina.gd")
var failures := 0
var screenshot_dir := ""

func _initialize() -> void:
	Profile.storage_path = Paths.path("vitals_profile_%d.json" % Time.get_ticks_usec())
	Save.storage_path = Paths.path("vitals_save_%d.json" % Time.get_ticks_usec())
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--screenshots="): screenshot_dir = arg.trim_prefix("--screenshots=")
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func ticks(count: int = 3) -> void:
	for i in range(count):
		await physics_frame
		await process_frame

func key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)

func enter() -> Node3D:
	change_scene_to_file("res://scenes/main.tscn")
	await scene_changed
	var player: Node3D = current_scene.get_node("Player")
	player._capture_controls(false)
	current_scene.boar.set_physics_process(false)
	current_scene.bellmaw.set_physics_process(false)
	await ticks()
	return player

func capture(filename: String) -> void:
	if screenshot_dir.is_empty() or DisplayServer.get_name() == "headless": return
	DirAccess.make_dir_recursive_absolute(screenshot_dir)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(screenshot_dir.path_join(filename + ".png"))

func run() -> void:
	var reserve := Stamina.new()
	check(reserve.advance(2, true) and reserve.value == 68, "Sprinting did not consume its reserve")
	reserve.advance(0.9, false)
	check(is_equal_approx(reserve.value, 68), "Stamina recovered before its delay")
	reserve.advance(1, false)
	check(is_equal_approx(reserve.value, 90), "Walking/rest recovery rate is wrong")
	reserve.advance(4, false)
	check(reserve.value == 100, "Recovery exceeded full stamina")
	check(not reserve.advance(10, true) and reserve.value == 0 and reserve.exhausted, "Empty reserve still permits sprinting")
	reserve.advance(0.9, true)
	reserve.advance(0.5, true)
	check(reserve.exhausted and is_equal_approx(reserve.value, 11), "Exhausted sprint did not recover while Shift was held")
	reserve.advance(0.5, true)
	check(not reserve.exhausted and reserve.advance(0.1, true), "Sprint did not unlock after recovering 20 stamina")
	reserve.restore({"value": "bad", "recovery_delay": -5, "exhausted": true})
	check(reserve.value == 100 and reserve.recovery_delay == 0 and not reserve.exhausted, "Malformed stamina did not restore safely")
	var player := await enter()
	check(player.vitals.health_bar.value == 100 and player.vitals.stamina_bar.value == 100, "New player HUD is not full")
	for bar in [player.vitals.health_bar, player.vitals.stamina_bar]:
		check(player.vitals.get_global_rect().encloses(bar.get_global_rect()), "A meter extends outside its HUD panel")
	check(player.vitals.health_bar.get_global_rect().end.y < player.vitals.stamina_title.get_global_rect().position.y, "Health bar overlaps stamina label")
	player._capture_controls(true)
	player.global_position = Vector3(0,1.1,10)
	key(KEY_SHIFT, true)
	await ticks(5)
	check(player.stamina.value == 100, "Holding Shift while idle used stamina")
	key(KEY_W, true)
	await ticks(5)
	check(player.stamina.value < 100 and Vector2(player.velocity.x,player.velocity.z).length() > 7.8, "Movement input did not enable stamina-driven sprint")
	player.stamina.restore({"value":0})
	await ticks()
	check(Vector2(player.velocity.x,player.velocity.z).length() < 5.1 and player.stamina.exhausted, "Exhaustion did not reduce sprint to walking")
	key(KEY_SHIFT, false)
	key(KEY_W, false)
	player.open_inventory()
	var frozen: float = player.stamina.value
	await ticks(10)
	check(player.stamina.value == frozen and not player.vitals.visible, "Menu failed to pause stamina or hide HUD")
	player.close_inventory()
	check(player.vitals.visible, "Closing menu did not restore vitals")
	player.health = 100
	player.damage_grace = 0
	player.receive_damage(75)
	check(player.vitals.health_bar.value == 25 and "LOW" in player.vitals.health_title.text, "Damage or low-health HUD is stale")
	player.damage_grace = 0
	player.receive_damage(100)
	check(player.health == 100 and player.stamina.value == 100 and not player.stamina.exhausted and player.vitals.health_bar.value == 100, "Defeat did not refill health/stamina HUD")
	player.health = 40
	player.heal_delay = 0
	player.heal_clock = 0.249
	await ticks()
	check(player.health > 40 and player.vitals.health_bar.value == player.health, "Camp healing did not update the bar")
	player._capture_controls(false)
	player.health = 66
	player.stamina.restore({"value":43, "recovery_delay":0.6})
	player._update_hud()
	for third_person in [true, false]:
		player.set_third_person(third_person)
		check(player.vitals.visible and player.vitals.health_bar.value == 66 and player.vitals.stamina_bar.value == 43, "Camera mode hid or changed vitals")
		await capture("vitals-third-person" if third_person else "vitals-first-person")
	player.health = 20
	player.stamina.restore({"value":0})
	player._update_hud()
	check(player.vitals.stamina_title.text == "CATCH YOUR BREATH", "Exhaustion has no readable cue")
	await capture("vitals-low")
	for dimensions in [Vector2i(1100,680),Vector2i(1920,1080)]:
		root.size = dimensions
		await ticks()
		check(Rect2(Vector2.ZERO,root.get_visible_rect().size).encloses(player.vitals.get_global_rect()), "Vitals leave viewport at supported window size")
		check(player.vitals.get_global_rect().end.y < player.prompt_label.get_global_rect().position.y, "Vitals overlap interaction prompt")
	player.health = 66
	player.stamina.restore({"value":7.5, "recovery_delay":0.6,"exhausted":true})
	current_scene.save_game()
	player = await enter()
	check(player.health == 66 and player.stamina.value == 7.5 and is_equal_approx(player.stamina.recovery_delay,0.6) and player.stamina.exhausted, "Continue lost stamina, recovery state or health")
	check(player.vitals.health_bar.value == 66 and player.vitals.stamina_bar.value == 7.5, "Loaded HUD did not reflect saved values")
	var old := Save.load_state()
	old.version = 9
	old.player.erase("stamina")
	var file := FileAccess.open(Save.storage_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(old))
	file.close()
	player = await enter()
	check(player.health == 66 and player.stamina.value == 100 and not player.stamina.exhausted, "Old-save migration lost health or did not grant full stamina")
	Save.clear()
	print("PLAYER VITALS: %s" % ("PASS — HUD, damage/healing/defeat, real sprint input, exhaustion/recovery, menus, views, bounds, persistence and migration" if failures == 0 else "FAIL"))
	quit(1 if failures else 0)
