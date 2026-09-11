extends SceneTree
const Paths = preload("res://tests/test_paths.gd")
const Profile = preload("res://scripts/character_profile.gd")
const Save = preload("res://scripts/game_save.gd")
var failures := 0

func _initialize() -> void:
	Profile.storage_path = Paths.path("axe_combat_profile_%d.json" % Time.get_ticks_usec())
	Save.storage_path = Paths.path("axe_combat_save_%d.json" % Time.get_ticks_usec())
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func ticks(count: int = 4) -> void:
	for i in range(count):
		await physics_frame
		await process_frame

func click(player: Node) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	player._unhandled_input(event)

func aim(player: Node3D, enemy: Node3D, distance: float, third: bool) -> void:
	player.global_position = enemy.global_position + Vector3(0, 0.9, distance)
	player.velocity = Vector3.ZERO
	player.rotation = Vector3.ZERO
	player.set_third_person(third)
	var pivot: Vector3 = player.view_rig.arm.global_position if third else player.camera.global_position
	var offset: Vector3 = enemy.global_position + Vector3.UP * 0.65 - pivot
	player.camera.rotation = Vector3(atan2(offset.y, Vector2(offset.x, offset.z).length()), 0, 0)
	await ticks(8)

func run() -> void:
	change_scene_to_file("res://scenes/main.tscn")
	await scene_changed
	await ticks()
	var player: Node3D = current_scene.get_node("Player")
	player._capture_controls(true)
	player.inventory.add("stone_axe", 1)
	player.inventory.add("stone_spear", 1)
	player.inventory.add("stone_pickaxe", 1)
	for enemy in [current_scene.boar, current_scene.bellmaw]:
		enemy.set_physics_process(false)
	for enemy in [current_scene.boar, current_scene.bellmaw]:
		var original: Vector3 = enemy.position
		enemy.position = Vector3(12, 0.2, 12)
		for third in [false, true]:
			enemy.health = enemy.MAX_HEALTH
			enemy.state = "recover"
			player.equip_item("stone_axe")
			await aim(player, enemy, 2.2, third)
			check(player._melee_target(player.REACH).get("collider") == enemy, "Axe fixture did not aim at enemy")
			var before: int = enemy.health
			click(player)
			click(player)
			await ticks(7)
			check(enemy.health == before, "Axe dealt damage before contact")
			await ticks(38)
			check(enemy.health == before - 10, "Axe must deal exactly one 10-damage hit per swing in either view")
			player.equip_item("stone_spear")
			click(player)
			await ticks(45)
			check(enemy.health == before - 30, "Spear no longer deals twice the axe's damage")
			player.equip_item("stone_axe")
			await aim(player, enemy, 4.5, third)
			click(player)
			await ticks(45)
			check(enemy.health == before - 30, "Axe hit outside its reach")
		# A wall must remain outside the body and be the first solid contact.
		var wall_offset := 1.0 if enemy == current_scene.bellmaw else 0.0
		await aim(player, enemy, 2.2 + wall_offset, true)
		var wall := StaticBody3D.new()
		var collider := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(3, 3, 0.2)
		collider.shape = shape
		wall.add_child(collider)
		current_scene.add_child(wall)
		wall.position = enemy.position + Vector3(0, 1.4, 1 + wall_offset)
		await ticks()
		var health: int = enemy.health
		click(player)
		await ticks(45)
		check(enemy.health == health, "Axe hit through a wall")
		wall.queue_free()
		await ticks()
		# Switching tools or opening a panel cancels an unfinished axe strike.
		click(player)
		player.equip_item("stone_pickaxe")
		await ticks(45)
		click(player)
		await ticks(45)
		check(enemy.health == health, "Switching tools kept pending axe damage or pickaxe gained unintended combat damage")
		player.equip_item("stone_axe")
		click(player)
		player.open_inventory()
		await ticks(45)
		check(enemy.health == health, "Axe damage continued while the backpack was open")
		player.close_inventory()
		# Finishing an enemy with an axe uses its normal single loot/death path.
		enemy.health = 10
		click(player)
		await ticks(45)
		check(enemy.health == 0 and not enemy.visible, "Axe could not finish an enemy")
		var reward := "boar_hide" if enemy == current_scene.boar else "bellmaw_hide"
		var drops := 0
		for pickup in get_nodes_in_group("pickups"):
			if pickup.item_id == reward: drops += pickup.amount
		check(drops == 1, "Axe kill did not award exactly one hide")
		enemy.position = original
	Save.clear()
	print("AXE COMBAT: %s" % ("PASS — both enemies/views, 10 vs 20 damage, one contact, reach, walls, cancellation, pickaxe exclusion and kill rewards" if failures == 0 else "FAIL"))
	quit(1 if failures else 0)
