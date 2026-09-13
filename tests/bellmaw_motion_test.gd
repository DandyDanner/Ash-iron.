extends SceneTree
const Art = preload("res://scripts/bellmaw_model.gd")
const Paths = preload("res://tests/test_paths.gd")
const Profile = preload("res://scripts/character_profile.gd")
const Save = preload("res://scripts/game_save.gd")
var failures := 0
func _initialize() -> void:
	Profile.storage_path = Paths.path("bellmaw_motion_profile.json")
	Save.storage_path = Paths.path("bellmaw_motion_save.json")
	Save.clear()
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func run() -> void:
	var art := Art.new()
	root.add_child(art)
	art.body.scale = Vector3.ONE * 4
	for side in [-1.0, 1.0]:
		art.swipe_side = side
		var active := 0 if side < 0 else 2
		var previous := Vector3.ZERO
		for phase in [["swipe_warn", .85], ["swipe", .24], ["swipe_recover", 1.05]]:
			var steps := ceili(float(phase[1]) * 120)
			for frame in range(steps + 1):
				art.pose(0, 0, phase[0], float(frame) / steps * float(phase[1]), 0)
				for i in range(4):
					check(art.limbs[i].position.distance_to(art.limb_rest[i]) < .0001, "Swipe detached a shoulder from its socket")
					if i != active:
						check(art.body.to_local(art.feet[i].global_position).distance_to(art._foot_rest(i)) < .002, "Swipe supporting paw slid")
				var paw: Vector3 = art.body.to_local(art.feet[active].global_position)
				if previous != Vector3.ZERO: check(paw.distance_to(previous) < .065, "Swipe paw snapped between frames/states")
				previous = paw
		art.pose(0, 0, "idle", 0, 0)
		check(art.body.to_local(art.feet[active].global_position).distance_to(previous) < .002, "Swipe recovery did not settle into idle")
	# Real frame-by-frame starts, stops and attack entry must not teleport paws.
	art.pose(0, 0, "idle", 0, 0)
	var prior_feet: Array[Vector3] = []
	for foot in art.feet: prior_feet.append(foot.global_position)
	for phase in [["roam", 1.15], ["idle", 0.0], ["approach", 3.3], ["swipe_warn", 0.0]]:
		for frame in range(30):
			art.pose(1.0 / 60, phase[1], phase[0], float(frame) / 60, 0)
			for i in range(4):
				check(art.feet[i].global_position.distance_to(prior_feet[i]) < .25, "Locomotion transition snapped a paw: " + str(phase[0]))
				prior_feet[i] = art.feet[i].global_position
	# A stance paw is stationary in world space as the body moves over it.
	art.elapsed = 0
	art.gait = .10 * TAU
	art.pose(0, 1.15, "roam", 0, 0)
	var planted: Vector3 = art.feet[0].global_position
	for frame in range(10):
		art.position.z += 1.15 / 60
		art.pose(1.0 / 60, 1.15, "roam", float(frame) / 60, 0)
	check(art.feet[0].global_position.distance_to(planted) < .015, "Walking stance foot skated instead of staying planted")
	var lifted := 0
	for frame in range(80):
		art.pose(1.0 / 60, 2.3, "return", float(frame) / 60, 0)
		for foot in art.feet:
			if art.body.to_local(foot.global_position).y > .15: lifted += 1
	check(lifted > 10, "Four-beat gait never lifted its paws")
	check(art.blink_meshes.size() == 1, "Native eye mesh is missing its Blink shape")
	art.blink_clock = art.next_blink + .075
	art.pose(0, 0, "idle", 0, 0)
	check(art.blink_amount > .98, "Blink does not close")
	check(art.blink_meshes[0].get_blend_shape_value(art.blink_indices[0]) > .98, "Blink timer never reached the actual native eyelids")
	art.pose(.3, 0, "idle", 0, 0)
	check(art.blink_amount < .001, "Blink does not reopen")
	art.blink_clock = art.next_blink + .08
	art.pose(0, 0, "swipe_warn", .6, 0)
	check(art.blink_amount == 0, "Blink obscures the attack warning")
	art.queue_free()
	await process_frame
	change_scene_to_file("res://scenes/main.tscn")
	await scene_changed
	var bell: Node3D = current_scene.bellmaw
	var player: Node3D = current_scene.get_node("Player")
	bell.set_physics_process(false)
	player.set_physics_process(false)
	current_scene.boar.set_physics_process(false)
	player._capture_controls(true)
	player.global_position = player.spawn_position
	bell._set_state("idle")
	bell._physics_process(bell.ROAM_PAUSE + .01)
	check(bell.state == "roam", "Distant Bellmaw does not start a calm patrol")
	check(bell.roam_target.distance_to(bell.HOME) <= bell.ROAM_RADIUS + .01, "Patrol target leaves the home area")
	var started: Vector3 = bell.global_position
	for frame in range(90):
		await physics_frame
		bell._physics_process(1.0 / 60)
	var moved: Vector3 = bell.global_position - started
	check(Vector2(moved.x, moved.z).length() > .15, "Patrol never moved through the actual arena")
	check(Vector2(bell.position.x - bell.HOME.x, bell.position.z - bell.HOME.z).length() < bell.ROAM_RADIUS + 1.0, "Patrol left its home bounds")
	var timer: float = bell.state_time
	player._capture_controls(false)
	bell._physics_process(2)
	check(bell.state_time == timer, "Paused patrol kept running")
	player._capture_controls(true)
	bell.state_time = 7.1
	bell._physics_process(.01)
	check(bell.state == "idle", "Blocked patrol never pauses/replans")
	bell._set_state("roam")
	bell.global_position = bell.HOME + Vector3(4.1, 0, 0)
	bell.rotation.y = -PI / 2
	bell._physics_process(.01)
	check(bell.roam_target == bell.HOME, "Outlying patrol did not steer back home")
	bell.receive_melee_hit(2, bell.position)
	check(bell.state == "approach", "Hit during patrol failed to engage Bellmaw")
	Save.clear()
	print("BELLMAW MOTION: %s" % ("PASS" if failures == 0 else "FAIL"))
	quit(1 if failures else 0)
