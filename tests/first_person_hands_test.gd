extends SceneTree
const Paths = preload("res://tests/test_paths.gd")
const Profile = preload("res://scripts/character_profile.gd")
const Save = preload("res://scripts/game_save.gd")
var failures := 0
func _initialize() -> void:
	Profile.storage_path = Paths.path("first_person_hands_profile.json")
	Save.storage_path = Paths.path("first_person_hands_save.json")
	Save.clear()
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func check_sleeves(player: Node3D) -> void:
	for pair in [[player.first_left_hand, -.43], [player.axe.hand, .43]]:
		var hand: Node3D = pair[0]
		var sleeve: Node3D = hand.arm
		var end: Vector3 = player.camera.to_local(sleeve.to_global(Vector3(0,0,.5)))
		check(end.distance_to(Vector3(pair[1],-.48,-.025)) < .001, "Sleeve end detached from its camera-side shoulder")
		check(sleeve.global_basis.determinant() > 0, "Sleeve mirrored or collapsed through a wrist turn")
		check(sleeve.position.distance_to(Vector3(0,-.07,.065)) < .001, "Sleeve left the wrist anchor")
func run() -> void:
	change_scene_to_file("res://scenes/main.tscn")
	await scene_changed
	var player: Node3D = current_scene.get_node("Player")
	player._capture_controls(false)
	player.set_physics_process(false)
	player.set_third_person(false)
	player.equip_item("")
	player.update_first_person_hands()
	for hand in [player.first_left_hand, player.axe.hand]:
		var fingers: Vector3 = player.camera.global_basis.inverse() * hand.global_basis.y.normalized()
		check(fingers.z < -.7, "Empty fingers still point upright like claws")
	check_sleeves(player)
	for item in ["stone_axe", "copper_axe", "stone_pickaxe", "stone_spear", "torch"]:
		player.inventory.add(item,1)
		player.equip_item(item)
		for frame in range(37):
			player.axe.elapsed = float(frame) / 60
			if item != "torch": player.axe.pose_swing(player.axe.elapsed)
			player.update_first_person_hands()
			check_sleeves(player)
			if item == "stone_axe":
				# Native cutting edge is +X from the haft; it must lead toward the target.
				var tool: Node3D = player.axe.get_node("Tool")
				var edge_lead: Vector3 = player.camera.to_local(tool.to_global(Vector3(.14,.4,0))) - player.camera.to_local(tool.to_global(Vector3(0,.4,0)))
				check(edge_lead.z < -.08, "Stone axe cutting edge faces back toward the player")
			check(player.axe.hand.position.is_zero_approx(), "Tool hand moved away from the shaft grip")
		player.axe.cancel_swing()
	player.inventory.add("bow",1)
	player.inventory.add("arrow",1)
	player.equip_item("bow")
	player.bow.begin_draw()
	for frame in range(52):
		player.bow.advance(1.0 / 60)
		player.camera.rotation.x = sin(float(frame) / 12) * .8
		player.update_first_person_hands()
		check_sleeves(player)
		var nock: Vector3 = player.bow.to_global(player.bow.nocked.position + Vector3(0,0,.39))
		check(player.axe.hand.global_position.distance_to(nock) < .001, "Drawing wrist lost the moving nock")
		check(player.first_left_hand.global_position.distance_to(player.bow.global_position) < .001, "Bow-support wrist lost the grip")
	player.bow.cancel_draw()
	player.equip_item("")
	player.update_first_person_hands()
	check_sleeves(player)
	check(player.axe.hand.relaxed.visible and not player.axe.hand.gripping.visible, "Hand did not relax after holstering")
	Save.clear()
	print("FIRST PERSON HANDS: %s" % ("PASS" if failures == 0 else "FAIL"))
	quit(1 if failures else 0)
