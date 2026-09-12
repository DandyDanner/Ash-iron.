extends SceneTree
const Paths = preload("res://tests/test_paths.gd")
const Profile = preload("res://scripts/character_profile.gd")
const Save = preload("res://scripts/game_save.gd")
var failures := 0
func _initialize() -> void:
	Profile.storage_path = Paths.path("bellmaw_balance_profile.json")
	Save.storage_path = Paths.path("bellmaw_balance_save.json")
	Save.clear()
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func enter() -> void:
	change_scene_to_file("res://scenes/main.tscn")
	await scene_changed
	current_scene.get_node("Player")._capture_controls(false)
	for i in range(3): await process_frame
func run() -> void:
	await enter()
	var bell: Node3D = current_scene.bellmaw
	check(bell.health == 300 and bell.art.body.scale == Vector3.ONE * 4, "Bellmaw did not get 300 HP and twice the previous size")
	check(is_equal_approx(bell.collider.shape.radius, 2.64) and is_equal_approx(bell.collider.shape.height, 10.8), "Collision did not scale with Bellmaw")
	check(is_equal_approx(bell.label.position.y, 8.4), "Health label stayed inside the enlarged body")
	bell.state = "recover"
	for i in range(14): bell.receive_melee_hit(20, bell.position)
	check(bell.health == 20, "Bellmaw must survive fourteen full-damage spear hits")
	bell.receive_melee_hit(20, bell.position)
	check(bell.health == 0, "Fifteenth recovery spear hit should defeat Bellmaw")
	bell.restore({})
	bell.state = "approach"
	for i in range(29): bell.receive_melee_hit(20, bell.position)
	check(bell.health == 10, "Guarded hide should take thirty spear hits")
	bell.receive_melee_hit(20, bell.position)
	check(bell.health == 0, "Thirtieth guarded spear hit should defeat Bellmaw")
	# Load actual old save files, then save/reload the migrated result to catch double scaling.
	for sample in [[8, 40, 150], [9, 80, 150], [10, 80, 150], [11, 160, 300], [11, 80, 150], [11, 0, 0], [12, 140, 140]]:
		var fixture := {"version":sample[0], "bellmaw":{"health":sample[1], "respawn_remaining":47}}
		var file := FileAccess.open(Save.storage_path, FileAccess.WRITE)
		file.store_string(JSON.stringify(fixture))
		file.close()
		await enter()
		check(current_scene.bellmaw.health == sample[2], "Saved health percentage/death changed for version %s" % sample[0])
		if sample[1] == 0: check(current_scene.bellmaw.respawn.remaining == 47, "Migration reset the defeated enemy's countdown")
		check(current_scene.save_game() == OK, "Migrated save failed")
		check(Save.load_state().version == Save.VERSION, "New health cap was not versioned")
		await enter()
		check(current_scene.bellmaw.health == sample[2], "Reload scaled Bellmaw health a second time")
	Save.clear()
	print("BELLMAW BALANCE: " + ("PASS" if failures == 0 else "FAIL"))
	quit(1 if failures else 0)
