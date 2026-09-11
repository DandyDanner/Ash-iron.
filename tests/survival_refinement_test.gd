extends SceneTree
const Paths = preload("res://tests/test_paths.gd")
const Profile = preload("res://scripts/character_profile.gd")
const Save = preload("res://scripts/game_save.gd")
const Furnace = preload("res://scripts/furnace.gd")
const Chest = preload("res://scripts/storage_chest.gd")
var failures := 0

func _initialize() -> void:
	Profile.storage_path = Paths.path("refinement_profile_%d.json" % Time.get_ticks_usec())
	Save.storage_path = Paths.path("refinement_save_%d.json" % Time.get_ticks_usec())
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
	var player: Node3D = current_scene.get_node("Player")
	player._capture_controls(false)
	await ticks()
	player._capture_controls(true)
	return player

func wall_at(spot: Vector3) -> StaticBody3D:
	var wall := StaticBody3D.new()
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(3,3,3)
	collider.shape = shape
	wall.add_child(collider)
	current_scene.add_child(wall)
	wall.global_position = spot
	return wall

func run() -> void:
	var player := await enter()
	var bell: Node3D = current_scene.bellmaw
	bell.set_physics_process(false)
	bell.state = "approach"
	for i in range(4): bell.receive_melee_hit(20, bell.position)
	check(bell.health == 120, "Four guarded spear hits should not defeat the tougher Bellmaw")
	bell.state = "recover"
	bell.receive_melee_hit(20, bell.position)
	check(bell.health == 100, "Recovery did not expose Bellmaw to full spear damage")
	check(bell.BOOM_DAMAGE == 34 and bell.RECOVERY_TIME < 1.5 and bell.WARNING_TIME >= 1, "Threat tuning lost its readable warning or short opening")
	for enemy in [current_scene.boar, bell]:
		enemy.set_physics_process(false)
		enemy.receive_melee_hit(10000, enemy.position)
		check(enemy.health == 0 and enemy.respawn.remaining == 120, "Death did not start a two-minute respawn timer")
		player.open_inventory()
		enemy.respawn.advance(enemy, player, 30)
		check(enemy.respawn.remaining == 120, "Respawn advanced while paused")
		player.close_inventory()
		player.global_position = enemy.HOME + Vector3(0,0.9,4)
		enemy.respawn.advance(enemy, player, 121)
		check(enemy.health == 0, "Enemy respawned beside the player")
		player.global_position = player.spawn_position
		var obstruction := wall_at(enemy.HOME + Vector3.UP)
		await ticks()
		enemy.respawn.advance(enemy, player, 1)
		check(enemy.health == 0, "Enemy respawned inside an obstruction")
		obstruction.queue_free()
		await ticks()
		enemy.respawn.advance(enemy, player, 1)
		check(enemy.health == enemy.MAX_HEALTH and enemy.visible and enemy.state == "idle", "Enemy did not return healthy at its clear home")
		enemy.receive_melee_hit(10000, enemy.position)
		enemy.respawn.remaining = 47
	current_scene.save_game()
	player = await enter()
	for enemy in [current_scene.boar, current_scene.bellmaw]:
		check(enemy.health == 0 and enemy.respawn.remaining > 46 and enemy.respawn.remaining <= 47, "Reload reset or lost remaining respawn time")
	# Mining with the player underneath the spawn point must fall to terrain, not sit on their head.
	var rock: Node3D = current_scene.get_node("Rock1")
	player.global_position = Vector3(5,1.1,-4.85)
	rock.ore_chance = 1.0
	rock.mine(rock.global_position + Vector3(0,0,1.5))
	var fragments: Array = []
	for pickup in get_nodes_in_group("pickups"):
		if pickup.global_position.distance_to(Vector3(5,1.5,-4.85)) < 0.8: fragments.append(pickup)
	check(fragments.size() == 2, "Mining did not release stone and ore for fall test")
	await ticks(80)
	for pickup in fragments:
		check(pickup.settled and absf(pickup.global_position.y - 0.225) < 0.025, "Mined fragment remained floating on the player")
	# Chest supply is furnace-centered, bounded, atomic and just one batch at a time.
	player.global_position = player.spawn_position
	var furnace := Furnace.new()
	current_scene.add_child(furnace)
	furnace.position = Vector3(12,0.2,12)
	furnace.set_process(false)
	var near := Chest.new()
	current_scene.add_child(near)
	near.position = furnace.position + Vector3(3,0,0)
	near.storage.add("iron_ore", 6)
	var far := Chest.new()
	current_scene.add_child(far)
	far.position = furnace.position + Vector3(8.1,0,0)
	far.storage.add("wood", 3)
	furnace.advance(1)
	check(furnace.ore == 0 and near.storage.count("iron_ore") == 6, "Auto-feed consumed partial ingredients or used a distant chest")
	far.position = furnace.position + Vector3(8,0,0)
	furnace.advance(0)
	check(furnace.ore == 2 and furnace.fuel == 1 and near.storage.count("iron_ore") == 4 and far.storage.count("wood") == 2, "Auto-feed did not reserve exactly one batch across chests at the range boundary")
	furnace.advance(6)
	check(furnace.ingots == 0 and absf(furnace.progress - 0.5) < 0.001, "Smelting was not doubled to twelve seconds")
	furnace.advance(6)
	check(furnace.ingots == 1 and furnace.ore == 2 and furnace.fuel == 1, "Unattended furnace did not refill for the next batch")
	furnace.advance(24)
	check(furnace.ingots == 3 and near.storage.is_empty() and far.storage.is_empty() and not furnace.is_burning(), "Linked stock was duplicated or furnace did not stop when exhausted")
	near.storage.add("iron_ore", 4)
	near.storage.add("wood", 2)
	furnace.ingots = 10
	furnace.advance(12)
	check(near.storage.count("iron_ore") == 4 and near.storage.count("wood") == 2, "Full output drained connected stock")
	furnace.ingots = 0
	furnace.set_auto_feed(false)
	furnace.advance(12)
	check(furnace.is_empty(), "Disabled auto-feed still loaded materials")
	player.inventory.add("iron_ore", 1)
	check(furnace.load_from_sources(player.inventory, "iron_ore") == 5 and player.inventory.count("iron_ore") == 0 and near.storage.count("iron_ore") == 0, "Manual loading omitted pack or linked chests")
	current_scene.save_game()
	player = await enter()
	check(not get_nodes_in_group("furnaces")[0].auto_feed and get_nodes_in_group("furnaces")[0].ore == 5, "Save lost furnace supply setting or contents")
	# First-person equipment uses complete hands, and the bow hand follows its string.
	player.set_third_person(false)
	player.inventory.add("stone_axe", 1)
	player.inventory.add("bow", 1)
	player.inventory.add("arrow", 1)
	player.equip_item("stone_axe")
	player.update_first_person_hands()
	check(player.axe.hand.has_node("PalmAndWrist") and player.axe.hand.gripping.visible and not player.axe.hand.relaxed.visible, "First-person axe still uses an oval or an open grip")
	player.equip_item("bow")
	player.bow.begin_draw()
	player.bow.advance(0.85)
	player.update_first_person_hands()
	var nock: Vector3 = player.bow.to_global(player.bow.nocked.position + Vector3(0,0,0.39))
	check(player.axe.hand.global_position.distance_to(nock) < 0.001 and player.first_left_hand.global_position.distance_to(player.bow.global_position) < 0.001, "First-person bow hands do not meet string and grip")
	player.equip_item("")
	player.update_first_person_hands()
	check(player.axe.hand.relaxed.visible and not player.first_left_hand.gripping.visible, "Holstered hands did not relax")
	# Version 8 keeps health percentage, old dead enemies get a fresh respawn timer.
	var old := Save.load_state()
	old.version = 8
	old.bellmaw = {"health":40}
	old.boar = {"health":0}
	var file := FileAccess.open(Save.storage_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(old))
	file.close()
	player = await enter()
	check(current_scene.bellmaw.health == 80 and current_scene.boar.respawn.remaining > 119, "Version 8 migration lost health percentage or stranded a dead enemy")
	Save.clear()
	print("SURVIVAL REFINEMENTS: %s" % ("PASS — tougher hide, respawn/pause/clearance/save, falling drops, chest feed/range/atomicity/12s timing, hands and migration" if failures == 0 else "FAIL"))
	quit(1 if failures else 0)
