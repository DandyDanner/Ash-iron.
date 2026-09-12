extends SceneTree
const Paths = preload("res://tests/test_paths.gd")
const Profile = preload("res://scripts/character_profile.gd")
const Save = preload("res://scripts/game_save.gd")
const A = preload("res://scripts/bellmaw_attacks.gd")
var failures := 0
func _initialize() -> void:
	Profile.storage_path = Paths.path("bellmaw_attacks_profile.json")
	Save.storage_path = Paths.path("bellmaw_attacks_save.json")
	Save.clear()
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func ticks(n: int = 3) -> void:
	for i in range(n):
		await physics_frame
		await process_frame
func aim_point(bell: Node3D, angle: float, radius: float) -> Vector3:
	return bell.to_global(Vector3(sin(angle) * radius, .9, cos(angle) * radius))
func run() -> void:
	change_scene_to_file("res://scenes/main.tscn")
	await scene_changed
	await ticks()
	var player: Node3D = current_scene.get_node("Player")
	var bell: Node3D = current_scene.bellmaw
	current_scene.boar.set_physics_process(false)
	player._capture_controls(true)
	player.set_physics_process(false)
	bell.set_physics_process(false)
	bell.rotation.y = 0
	# Isolate the attack sector from scenic rocks; the explicit wall below tests cover.
	for obstacle in current_scene.find_children("*", "StaticBody3D", true, false):
		obstacle.collision_layer = 0
	player.global_position = aim_point(bell, PI / 4, 6.4)
	await ticks()
	check(not bell._can_swipe(), "Fresh encounter must teach the slam before allowing a swipe")
	bell.art.pose(0, 0, "warn", 0, 0)
	var rear: Vector3 = bell.art.feet[1].global_position
	var front: Vector3 = bell.art.feet[0].global_position
	bell.art.pose(0, 0, "warn", .9, 0)
	check(bell.art.feet[0].global_position.y > front.y + .65 and bell.art.feet[2].global_position.y > front.y + .65, "Slam did not visibly raise both front paws")
	check(bell.art.feet[1].global_position.distance_to(rear) < .001, "Rear supporting paw slipped during slam windup")
	check(not bell.art.dust.visible, "Dust appeared before paw impact")
	bell.art.pose(0, 0, "warn", 1.2, 0)
	check(bell.art.feet[0].global_position.distance_to(front) < .001, "Paws did not meet the ground at boom contact")
	bell.art.pose(0, 0, "recover", .05, 0)
	check(bell.art.dust.visible, "Slam impact has no dust burst")
	bell.art.pose(0, 0, "recover", .7, 0)
	check(not bell.art.dust.visible and bell.art.head.rotation.x > .1, "Recovery lacks a sag or retained dust too long")
	# The actual slam is the sole unlock for the side attack; cooldown prevents repetition.
	bell._boom()
	player.health = 100
	player.damage_grace = 0
	check(bell._can_swipe(), "Slam did not enable the close-range swipe")
	bell.swipe_cooldown = 1
	check(not bell._can_swipe(), "Swipe ignored its cooldown")
	bell.swipe_cooldown = 0
	bell._set_state("approach")
	bell._physics_process(.01)
	check(bell.state == "swipe_warn" and bell.swipe_side == 1 and not bell.swipe_ready, "Approach did not choose and consume a warned right-paw attack")
	var facing: float = bell.rotation.y
	bell._physics_process(.60)
	check(player.health == 100 and bell.rotation.y == facing and bell.art.swipe_marker.visible, "Swipe windup hit early or tracked the player")
	check(bell.art.feet[2].global_position.y > bell.art.feet[0].global_position.y + .2, "Swipe did not lift its chosen paw")
	# Pause does not advance the windup, cooldown or visual pose.
	player._capture_controls(false)
	var before: float = bell.state_time
	var cooldown: float = bell.swipe_cooldown
	bell._physics_process(2)
	check(bell.state_time == before and bell.swipe_cooldown == cooldown, "Paused swipe advanced its timers")
	player._capture_controls(true)
	bell._physics_process(.25)
	check(bell.state == "swipe" and player.health == 100, "Swipe hit at warning end instead of paw contact")
	bell._physics_process(.11)
	check(player.health == 100, "Swipe dealt damage before contact")
	bell._physics_process(.02)
	check(player.health == 82, "Paw contact did not deal exactly 18 damage")
	player.damage_grace = 0
	bell._physics_process(.05)
	check(player.health == 82, "Swipe inflicted multiple hits")
	bell._physics_process(.1)
	check(bell.state == "swipe_recover", "Swipe lacks recovery")
	var health: int = bell.health
	bell.receive_melee_hit(20, bell.position)
	check(bell.health == health - 20, "Swipe recovery did not expose the throat")
	# Actually leave the sector during a live windup: facing stays locked and contact misses.
	bell._set_state("swipe_warn")
	player.health = 100
	player.damage_grace = 0
	bell._physics_process(.60)
	player.global_position = bell.to_global(Vector3(0, .9, -6.8))
	await ticks()
	bell._physics_process(.25)
	bell._physics_process(.13)
	check(player.health == 100 and bell.rotation.y == facing, "A dodge during the warned swipe still took damage or was tracked")
	bell.swipe_ready = true
	bell._set_state("return")
	check(not bell.swipe_ready, "Leaving the encounter did not reset its slam-first opening")
	# Dodges: outside radius, behind, and on the opposite flank all avoid contact.
	for point in [Vector3(0, .9, 8.0), Vector3(0, .9, -6.8), Vector3(-6.4, .9, 0)]:
		player.global_position = bell.to_global(point)
		player.health = 100
		player.damage_grace = 0
		await ticks()
		bell._swipe()
		check(player.health == 100, "Swipe hit outside its warned side sector")
	# Test both mirrors after rotating the whole enemy, using its local attack geometry.
	bell.rotation.y = .7
	for side in [-1.0, 1.0]:
		bell.swipe_side = side
		bell.art.swipe_side = side
		player.global_position = aim_point(bell, side * PI / 4, 6.4)
		player.health = 100
		player.damage_grace = 0
		await ticks()
		bell._swipe()
		check(player.health == 82, "Mirrored/rotated swipe lost its local hit sector")
		bell.art.pose(0, 0, "swipe_warn", .7, 0)
		check(bell.art.swipe_marker.scale.x == side and not bell.art.pulse.visible, "Swipe marker was not mirrored or showed the slam ring")
	# Solid cover still blocks contact.
	var wall := StaticBody3D.new()
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(.5, 3, 1.6)
	collider.shape = shape
	wall.add_child(collider)
	current_scene.add_child(wall)
	wall.global_position = bell.to_global(Vector3(3.4, 1, 3.4))
	wall.rotation.y = bell.rotation.y - PI / 4
	await ticks()
	player.health = 100
	player.damage_grace = 0
	bell._swipe()
	check(player.health == 100, "Swipe hit through cover")
	wall.queue_free()
	await ticks()
	bell.restore({"health": 140})
	check(not bell.swipe_ready and bell.state == "idle", "Reload/respawn resumed an armed swipe")
	bell.art.pose(0, 0, "return", 0, 0)
	check(not bell.art.dust.visible and not bell.art.swipe_marker.visible, "Canceled attack retained effects")
	Save.clear()
	bell.sound.stop()
	current_scene.queue_free()
	current_scene = null
	await ticks(3)
	print("BELLMAW ATTACKS: " + ("PASS" if failures == 0 else "FAIL"))
	quit(1 if failures else 0)
