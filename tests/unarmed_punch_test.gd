extends SceneTree
## Bare hands throw a short punch: three damage once per swing, useless against trees and rock.
const Paths = preload("res://tests/test_paths.gd")
const Profile = preload("res://scripts/character_profile.gd")
const Save = preload("res://scripts/game_save.gd")
const Axe = preload("res://scripts/starter_axe.gd")
var failures := 0

func _initialize() -> void:
	Profile.storage_path = Paths.path("punch_profile_%d.json" % Time.get_ticks_usec())
	Save.storage_path = Paths.path("punch_save_%d.json" % Time.get_ticks_usec())
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
	var boar: Node3D = current_scene.boar
	boar.set_physics_process(false)
	boar.position = Vector3(12, 0.2, 12)
	check(player.equipped_item.is_empty() and player.axe.selected_item.is_empty(), "A fresh traveler should start empty-handed")
	for third in [false, true]:
		boar.health = boar.MAX_HEALTH
		boar.state = "recover"
		await aim(player, boar, 1.3, third)
		check(player._melee_target(Axe.PUNCH_REACH).get("collider") == boar, "Punch fixture did not aim at the boar")
		var before: int = boar.health
		click(player)
		check(player.axe.elapsed >= 0.0 and player.axe.hand.gripping.visible, "Punch did not start with a closed fist")
		click(player)
		await ticks(45)
		check(boar.health == before - Axe.PUNCH_DAMAGE, "Punch must deal exactly %d once per swing (%s person)" % [Axe.PUNCH_DAMAGE, "third" if third else "first"])
		check(player.feedback.begins_with("Punch!"), "Punch feedback missing: " + player.feedback)
		check(player.axe.elapsed < 0.0 and not player.axe.hand.gripping.visible, "Fist did not relax after the punch")
		await aim(player, boar, 2.8, third)
		before = boar.health
		click(player)
		await ticks(45)
		check(boar.health == before, "Punch reached beyond %.1f m" % Axe.PUNCH_REACH)
	player.set_third_person(false)
	# Trees and rock shrug off bare hands and point at the tools instead.
	var pine: Node3D = current_scene.get_node("PracticePine")
	player.global_position = Vector3(0, 1.1, 2)
	player.rotation = Vector3.ZERO
	player.camera.rotation = Vector3.ZERO
	await ticks()
	check(player._melee_target(Axe.PUNCH_REACH).get("collider") == pine, "Tree fixture did not aim at the practice pine")
	click(player)
	await ticks(45)
	check(pine.hits_left == pine.MAX_HITS, "A punch chopped the tree")
	check(player.feedback.begins_with("Bare hands"), "Punching a tree should point at the axe: " + player.feedback)
	# Tools keep their own behaviour; a torch never punches.
	player.inventory.add("torch", 1)
	player.equip_item("torch")
	await ticks()
	click(player)
	check(player.axe.elapsed < 0.0, "A held torch started a punch")
	player.equip_item("")
	# Nothing in reach: the tutorial hint still explains the empty hands.
	player.global_position = Vector3(20, 1.1, 20)
	player.camera.rotation = Vector3(0.4, 0, 0)
	await ticks()
	click(player)
	await ticks(45)
	check(player.feedback.begins_with("Empty hands"), "A missed punch lost the empty-hands hint: " + player.feedback)
	Save.clear()
	print("UNARMED PUNCH: %s" % ("PASS — three damage once per swing in both views, reach limit, no effect on pines, torch excluded, miss hint" if failures == 0 else "FAIL"))
	quit(1 if failures else 0)
