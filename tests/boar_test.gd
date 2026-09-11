extends SceneTree
const Paths = preload("res://tests/test_paths.gd")
const Profile = preload("res://scripts/character_profile.gd")
const Save = preload("res://scripts/game_save.gd")
const Boar = preload("res://scripts/bristleback.gd")
var failures := 0

func _initialize() -> void:
	Profile.storage_path = Paths.path("boar_profile_%d.json" % Time.get_ticks_usec())
	Save.storage_path = Paths.path("boar_save_%d.json" % Time.get_ticks_usec())
	call_deferred("run")
func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)
func ticks(count: int = 4) -> void:
	for i in range(count):
		await physics_frame
		await process_frame
func enter() -> Node3D:
	change_scene_to_file("res://scenes/main.tscn")
	await scene_changed
	await ticks(5)
	var player: Node3D = current_scene.get_node("Player")
	player._capture_controls(true)
	return player
func click(player: Node) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	player._unhandled_input(event)
func hide_count() -> int:
	var count := 0
	for pickup in get_nodes_in_group("pickups"):
		if pickup.item_id == "boar_hide" and not pickup.collected: count += pickup.amount
	return count
func reset_encounter(player: Node3D, boar: Node3D) -> void:
	boar.restore({})
	player.health = 100
	player.damage_grace = 0
	player.global_position = Boar.HOME + Vector3(0, 0.9, 4)
	player.velocity = Vector3.ZERO
	player._capture_controls(true)

func run() -> void:
	var player := await enter()
	var boar: Node3D = current_scene.boar
	check(player.health == 100 and boar.health == 60 and player.inventory.is_empty(), "New encounter granted gear or wrong health")
	await ticks(80)
	check(player.health == 100 and boar.global_position.distance_to(Boar.HOME) < 0.5, "Boar left its territory to attack camp")
	reset_encounter(player, boar)
	await ticks(15)
	check(boar.state == "warn" and player.health == 100, "Boar did not warn before attacking")
	var direction: Vector3 = boar.charge_direction
	player.global_position.x += 3.5
	await ticks(25)
	check(boar.charge_direction.distance_to(direction) < 0.001 and player.health == 100, "Warning tracked the dodge or dealt early damage")
	await ticks(80)
	check(player.health == 100, "Sidestepping the committed charge did not avoid damage")
	reset_encounter(player, boar)
	await ticks(100)
	check(player.health == 75 and boar.state == "recover", "Charge did not hit once and enter recovery")
	await ticks(25)
	check(player.health == 75, "Contact during recovery caused repeated damage")
	# Backpack/focus pause the encounter.
	player.open_inventory()
	var paused_time: float = boar.state_time
	await ticks(90)
	check(boar.state_time == paused_time and player.health == 75, "Combat continued while backpack was open")
	player.close_inventory()
	# A solid wall intercepts a charge.
	reset_encounter(player, boar)
	await ticks(15)
	var wall := StaticBody3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(4, 3, 0.25)
	var collider := CollisionShape3D.new()
	collider.shape = shape
	wall.add_child(collider)
	current_scene.add_child(wall)
	wall.global_position = Boar.HOME + Vector3(0, 1.0, 2)
	await ticks(100)
	check(player.health == 100 and boar.global_position.z < wall.global_position.z, "Charge passed through a solid wall")
	wall.queue_free()
	# Leaving the territory returns the animal home.
	player.global_position = player.spawn_position
	await ticks(160)
	check(boar.global_position.distance_to(Boar.HOME) < 0.6 and boar.health == 60, "Boar did not disengage and reset at home")
	# Exercise actual weapon contact against a stationary enemy away from scenery.
	boar.set_physics_process(false)
	boar.global_position = Vector3(12, 0.2, 12)
	boar.health = 60
	player.global_position = Vector3(12, 1.1, 14.2)
	player.rotation = Vector3.ZERO
	player.set_third_person(false)
	player.camera.look_at(boar.global_position + Vector3.UP * 0.5)
	player.inventory.add("stone_spear", 1)
	player.equip_item("stone_spear")
	await ticks()
	click(player)
	await ticks(45)
	check(boar.health == 40, "Spear did not apply its 20 damage to the boar")
	player.inventory.add("bow", 1)
	player.inventory.add("arrow", 2)
	player.equip_item("bow")
	player.bow.begin_draw()
	player.bow.advance(0.85)
	player.fire_bow()
	await ticks(25)
	check(boar.health == 15 and player.inventory.count("arrow") == 1, "Bow did not damage the boar or spent incorrect ammo")
	player.equip_item("stone_spear")
	click(player)
	await ticks(45)
	check(boar.health == 0 and not boar.visible and hide_count() == 1, "Defeat did not create exactly one hide")
	boar.receive_melee_hit(20, boar.global_position)
	boar.hit_by_arrow(boar.global_position)
	check(hide_count() == 1, "Dead boar duplicated its reward")
	# Defeat keeps equipment and returns the traveler to safety.
	var gear: Array = player.inventory.to_data()
	player.health = 25
	player.damage_grace = 0
	check(player.receive_damage(25), "Player damage was rejected")
	check(player.health == 100 and player.global_position == player.spawn_position and player.inventory.to_data() == gear and player.axe.elapsed < 0, "Player defeat lost gear or failed to return to camp")
	check(not player.receive_damage(25), "Defeat grace did not block immediate repeated damage")
	player.health = 90
	player.heal_delay = 0
	await ticks(40)
	check(player.health > 90, "Camp did not restore health")
	player.global_position = Vector3(12, 1.1, 12)
	player.health = 67
	check(current_scene.save_game() == OK, "Combat save failed")
	player = await enter()
	boar = current_scene.boar
	check(player.health == 67 and boar.health == 0 and hide_count() == 1, "Save lost health/death or duplicated hide")
	var hide: Node3D
	for pickup in get_nodes_in_group("pickups"):
		if pickup.item_id == "boar_hide": hide = pickup
	if is_instance_valid(hide): check(hide.collect_into(player.inventory) == 1, "Hide could not be collected")
	check(current_scene.save_game() == OK, "Collected reward save failed")
	player = await enter()
	check(current_scene.boar.health == 0 and hide_count() == 0 and player.inventory.count("boar_hide") == 1, "Reload duplicated a collected reward")
	# Format 5 gets a fresh boar and full player health, preserving inventory.
	var old := Save.load_state()
	old.version = 5
	old.erase("boar")
	old.player.erase("health")
	var file := FileAccess.open(Save.storage_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(old))
	file.close()
	player = await enter()
	check(player.health == 100 and current_scene.boar.health == 60 and player.inventory.count("stone_spear") == 1, "Format 5 migration lost equipment or health defaults")
	current_scene.boar.restore({"health": "bad", "x": "bad"})
	check(current_scene.boar.health == 60, "Malformed combat data did not use safe defaults")
	Save.clear()
	print("BOAR: %s" % ("PASS — warning/dodge/charge, recovery, pause/walls/leash, spear/bow, reward, defeat/healing, persistence and v5 migration" if failures == 0 else "FAIL"))
	quit(1 if failures else 0)
