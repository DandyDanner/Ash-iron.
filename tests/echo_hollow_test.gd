extends SceneTree
const Paths = preload("res://tests/test_paths.gd")
const Profile = preload("res://scripts/character_profile.gd")
const Save = preload("res://scripts/game_save.gd")
const Bell = preload("res://scripts/bellmaw.gd")
const Terrain = preload("res://scripts/visual_clearing.gd")
var failures := 0

func _initialize() -> void:
	Profile.storage_path = Paths.path("echo_profile_%d.json" % Time.get_ticks_usec())
	Save.storage_path = Paths.path("echo_save_%d.json" % Time.get_ticks_usec())
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func ticks(count: int = 4) -> void:
	for i in range(count):
		await physics_frame
		await process_frame

func enter() -> Node3D:
	change_scene_to_file("res://scenes/main.tscn")
	await scene_changed
	await ticks()
	var player: Node3D = current_scene.get_node("Player")
	player._capture_controls(true)
	return player

func reset(player: Node3D, bell: Node3D) -> void:
	bell.restore({})
	player.global_position = Bell.HOME + Vector3(0, 0.9, 3.7)
	player.velocity = Vector3.ZERO
	player.health = 100
	player.damage_grace = 0
	player._capture_controls(true)

func rewards() -> int:
	var total := 0
	for item in get_nodes_in_group("pickups"):
		if item.item_id == "bellmaw_hide" and not item.collected: total += item.amount
	return total

func run() -> void:
	var player := await enter()
	var bell: Node3D = current_scene.bellmaw
	check(bell.health == Bell.MAX_HEALTH and player.inventory.is_empty(), "Fresh encounter granted equipment or wrong health")
	await ticks(50)
	check(player.health == 100 and bell.state == "idle", "Bellmaw disturbed safe starting camp")
	# Sample both segments of the new route using real ground collision.
	for p in [Vector2(25,-12), Vector2(34,-18), Vector2(42,-20), Vector2(53,-32)]:
		var query := PhysicsRayQueryParameters3D.create(Vector3(p.x, 8, p.y), Vector3(p.x,-2,p.y), 1, [bell.get_rid(), player.get_rid()])
		var ground: Dictionary = current_scene.get_world_3d().direct_space_state.intersect_ray(query)
		check(not ground.is_empty() and absf(ground.position.y - Terrain.terrain_height(p.x,p.y)) < 0.2, "Trail has a missing or obstructed floor at %s" % p)
	reset(player, bell)
	await ticks(15)
	check(bell.state == "warn" and player.health == 100 and bell.art.throat.scale.y > 1, "Throat warning missing or caused early damage")
	player.global_position.z += 3
	await ticks(65)
	check(player.health == 100 and bell.state == "recover", "Backing beyond the boom radius did not avoid it")
	reset(player, bell)
	await ticks(90)
	check(player.health == 100 - Bell.BOOM_DAMAGE and bell.state == "recover", "Boom did not deal the configured damage after its warning")
	await ticks(25)
	check(player.health == 100 - Bell.BOOM_DAMAGE, "Recovery inflicted repeated contact damage")
	player.open_inventory()
	var paused_time: float = bell.state_time
	await ticks(100)
	check(bell.state_time == paused_time and player.health == 100 - Bell.BOOM_DAMAGE, "Inventory did not pause encounter")
	player.close_inventory()
	reset(player, bell)
	await ticks(15)
	var wall := StaticBody3D.new()
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(5, 3, 0.3)
	collider.shape = shape
	wall.add_child(collider)
	current_scene.add_child(wall)
	wall.global_position = Bell.HOME + Vector3(0, 1.0, 2)
	await ticks(75)
	check(player.health == 100, "Boom passed through solid cover")
	wall.queue_free()
	player.global_position = player.spawn_position
	await ticks(120)
	check(bell.state == "idle" and bell.health == Bell.MAX_HEALTH, "Leaving territory failed to reset the encounter")
	# Real weapon collision uses the shared melee/arrow interface, with Bellmaw's own resistance.
	bell.set_physics_process(false)
	bell.state = "recover"
	bell.global_position = Vector3(12, 0.2, 12)
	player.global_position = Vector3(12, 1.1, 14.3)
	player.rotation = Vector3.ZERO
	player.set_third_person(false)
	player.camera.look_at(bell.global_position + Vector3.UP * 0.9)
	player.inventory.add("stone_spear", 1)
	player.equip_item("stone_spear")
	await ticks()
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	player._unhandled_input(event)
	await ticks(45)
	check(bell.health == Bell.MAX_HEALTH - 20, "Spear did not hit Bellmaw for 20")
	player.inventory.add("bow", 1)
	player.inventory.add("arrow", 2)
	player.equip_item("bow")
	player.bow.begin_draw()
	player.bow.advance(0.85)
	player.fire_bow()
	await ticks(25)
	check(bell.health == Bell.MAX_HEALTH - 35, "Arrow did not hit Bellmaw for 15")
	bell.receive_melee_hit(1000, bell.global_position)
	bell.receive_melee_hit(1000, bell.global_position)
	check(bell.health == 0 and rewards() == 1 and not bell.visible, "Defeat reward missing or duplicated")
	check(current_scene.save_game() == OK, "Encounter save failed")
	player = await enter()
	check(current_scene.bellmaw.health == 0 and rewards() == 1, "Reload lost dead Bellmaw or its uncollected hide")
	for pickup in get_nodes_in_group("pickups"):
		if pickup.item_id == "bellmaw_hide": pickup.collect_into(player.inventory)
	current_scene.save_game()
	player = await enter()
	check(player.inventory.count("bellmaw_hide") == 1 and rewards() == 0, "Reload duplicated collected reward")
	Save.clear()
	print("ECHO HOLLOW: %s" % ("PASS — ground, warning, distance, cover, recovery, pause, leash, actual weapons, one reward and persistence" if failures == 0 else "FAIL"))
	quit(1 if failures else 0)
