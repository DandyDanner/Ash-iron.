extends CharacterBody3D
## Echo Hollow's territorial creature. A planted, warned radial boom rewards distance/cover.
const Attacks = preload("res://scripts/bellmaw_attacks.gd")
const Art = preload("res://scripts/bellmaw_model.gd")
const Pickup = preload("res://scripts/resource_pickup.gd")
const HOME := Vector3(42, 1.03, -20)
const BODY_SCALE := 4.0
const MAX_HEALTH := 300
const BOOM_DAMAGE := 34
const BOOM_RADIUS := 6.0
const WARNING_TIME := 1.2
const RECOVERY_TIME := 1.25
const LEASH_RADIUS := 12.0
var respawn := preload("res://scripts/enemy_respawn.gd").new()
var health := MAX_HEALTH
var state := "idle"
var state_time := 0.0
var art: Node3D
var player: Node3D
var collider: CollisionShape3D
var label: Label3D
var sound: AudioStreamPlayer3D
var warning_sound: AudioStreamWAV
var boom_sound: AudioStreamWAV
var hit_flash := 0.0
var swipe_ready := false
var swipe_cooldown := 0.0
var swipe_side := 1.0
var swipe_hit_sent := false
var swipe_warning_sound: AudioStreamWAV
var swipe_sound: AudioStreamWAV

func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 1
	collision_mask = 1
	floor_snap_length = 0.5
	art = Art.new()
	add_child(art)
	art.boom_radius = BOOM_RADIUS
	# Enlarge the creature only; the sibling warning ring stays at BOOM_RADIUS.
	art.body.scale = Vector3.ONE * BODY_SCALE
	collider = CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.66 * BODY_SCALE
	shape.height = 2.7 * BODY_SCALE # Match the imported body/throat length.
	collider.shape = shape
	collider.position = Vector3(0, 0.67 * BODY_SCALE, 0)
	collider.rotation.x = PI / 2
	add_child(collider)
	label = Label3D.new()
	label.position.y = 2.1 * BODY_SCALE
	label.font_size = 30
	label.pixel_size = 0.007
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)
	sound = AudioStreamPlayer3D.new()
	sound.volume_db = -12
	sound.max_distance = 22
	add_child(sound)
	warning_sound = _tone(125, 0.65)
	boom_sound = _tone(55, 0.55)
	swipe_warning_sound = _tone(190, .35)
	swipe_sound = _tone(80, .20)
	player = get_parent().get_node_or_null("Player")
	_refresh()

func _physics_process(delta: float) -> void:
	if health <= 0:
		respawn.advance(self, player, delta)
		return
	if not is_instance_valid(player) or not player.controls_active:
		return
	state_time += delta
	swipe_cooldown = maxf(0, swipe_cooldown - delta)
	hit_flash = maxf(0, hit_flash - delta)
	var offset: Vector3 = player.global_position - global_position
	offset.y = 0
	var distance := offset.length()
	if state != "return" and (global_position.distance_to(HOME) > LEASH_RADIUS or player.global_position.distance_to(HOME) > LEASH_RADIUS + 2 or player.global_position.distance_to(player.spawn_position) < 6):
		_set_state("return")
	var direction := Vector3.ZERO
	var speed := 0.0
	match state:
		"idle":
			if distance < 9 and _sees_player(): _set_state("approach")
		"approach":
			direction = offset.normalized()
			speed = 3.3
			if _can_swipe():
				swipe_side = -1.0 if to_local(player.global_position).x < 0 else 1.0
				art.swipe_side = swipe_side
				swipe_ready = false
				swipe_cooldown = Attacks.SWIPE_COOLDOWN
				_set_state("swipe_warn")
			elif distance < BOOM_RADIUS - 0.3 and _sees_player(): _set_state("warn")
		"warn":
			if state_time >= WARNING_TIME:
				_boom()
				_set_state("recover")
		"recover":
			if state_time >= RECOVERY_TIME: _set_state("approach")
		"swipe_warn":
			if state_time >= Attacks.SWIPE_WARNING: _set_state("swipe")
		"swipe":
			if not swipe_hit_sent and state_time >= Attacks.SWIPE_CONTACT:
				swipe_hit_sent = true
				_swipe()
			if state_time >= Attacks.SWIPE_SWING: _set_state("swipe_recover")
		"swipe_recover":
			if state_time >= Attacks.SWIPE_RECOVERY: _set_state("approach")
		"return":
			var home_offset := HOME - global_position
			home_offset.y = 0
			direction = home_offset.normalized()
			speed = 2.3
			if home_offset.length() < 0.4:
				health = MAX_HEALTH
				_set_state("idle")
	if state in ["warn", "recover", "swipe_warn", "swipe", "swipe_recover", "idle"]: speed = 0
	if speed > 0:
		direction = _clear_direction(direction)
		if direction.length_squared() > 0.1:
			rotation.y = lerp_angle(rotation.y, atan2(direction.x, direction.z), minf(1, delta * 7))
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	velocity.y = -0.5 if is_on_floor() else velocity.y - 9.8 * delta
	move_and_slide()
	art.pose(delta, Vector2(velocity.x, velocity.z).length(), state, state_time, hit_flash)
	_refresh()

func _clear_direction(desired: Vector3) -> Vector3:
	for angle in [0.0, 0.8, -0.8, 1.4, -1.4]:
		var candidate := desired.rotated(Vector3.UP, angle)
		var side := candidate.cross(Vector3.UP).normalized() * 0.6 * BODY_SCALE
		var clear := true
		for lateral in [-side, Vector3.ZERO, side]:
			var origin: Vector3 = global_position + Vector3.UP * 0.7 * BODY_SCALE + lateral
			var query := PhysicsRayQueryParameters3D.create(origin, origin + candidate * 1.8 * BODY_SCALE, 1, [get_rid(), player.get_rid()])
			if not get_world_3d().direct_space_state.intersect_ray(query).is_empty(): clear = false
		if clear: return candidate
	return Vector3.ZERO

func _sees_player() -> bool:
	# Keep the low cover-check origin: the larger silhouette must not invalidate rock cover.
	var query := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 0.85, player.global_position, 1, [get_rid()])
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return not hit.is_empty() and hit.collider == player

func _can_swipe() -> bool:
	if not swipe_ready or swipe_cooldown > 0: return false
	var local_offset := to_local(player.global_position)
	var side := -1.0 if local_offset.x < 0 else 1.0
	return Attacks.in_swipe_arc(local_offset, side) and _sees_player()

func _swipe() -> void:
	sound.stream = swipe_sound
	sound.play()
	# One contact in a fixed, visibly warned side sector. Never tracks through the windup.
	if Attacks.in_swipe_arc(to_local(player.global_position), swipe_side) and _sees_player():
		player.receive_damage(Attacks.SWIPE_DAMAGE, "Bellmaw paw swipe! • Back away or circle behind.")

func _boom() -> void:
	swipe_ready = true
	sound.stream = boom_sound
	sound.play()
	var offset: Vector3 = player.global_position - global_position
	# Cover and height matter. No damage is applied through rocks, or beyond the warned radius.
	if Vector2(offset.x, offset.z).length() <= BOOM_RADIUS and absf(offset.y) < 2.5 and _sees_player():
		player.receive_damage(BOOM_DAMAGE, "Bellmaw boom! • Back away or use rock cover.")

func _set_state(next: String) -> void:
	state = next
	state_time = 0
	swipe_hit_sent = false
	if next in ["idle", "return"]: swipe_ready = false
	if next == "swipe_warn":
		sound.stream = swipe_warning_sound
		sound.play()
	if next == "warn":
		sound.stream = warning_sound
		sound.play()
	_refresh()

func _refresh() -> void:
	label.visible = health > 0 and state in ["approach", "warn", "recover", "swipe_warn", "swipe", "swipe_recover"]
	var cue := "GROUND SLAM — back away or take cover!" if state == "warn" else ("SOFT THROAT — strike now!" if state in ["recover", "swipe_recover"] else "Thick hide • half damage until recovery")
	if state in ["swipe_warn", "swipe"]: cue = "PAW SWIPE — back away or circle behind!"
	label.text = "Bellmaw  %d / %d\n%s" % [health, MAX_HEALTH, cue]
	label.modulate = Color("f9c26b") if state in ["warn", "swipe_warn", "swipe"] else Color("f0e5c5")

func receive_melee_hit(damage: int, _point: Vector3) -> String:
	return _take_hit(damage)

func hit_by_arrow(_point: Vector3) -> String:
	return _take_hit(15)

func _take_hit(damage: int) -> String:
	if health <= 0 or damage <= 0: return ""
	var applied := damage if state in ["recover", "swipe_recover"] else maxi(1, int(damage * 0.5))
	health = maxi(0, health - applied)
	hit_flash = 0.25
	if health == 0:
		respawn.start()
		_set_state("dead")
		hide()
		sound.stop()
		collider.set_deferred("disabled", true)
		var drop := Pickup.new()
		drop.item_id = "bellmaw_hide"
		drop.amount = 1
		get_parent().add_child(drop)
		drop.global_position = global_position + Vector3.UP * 0.05
	elif state == "idle":
		_set_state("approach")
	_refresh()
	get_parent().mark_dirty()
	return "Bellmaw defeated • Gather its hide for an Explorer Pack" if health == 0 else "Bellmaw: %d / %d" % [health, MAX_HEALTH]

func to_data() -> Dictionary:
	# Resume in its clear home territory, with health/death preserved and a fresh warning.
	return {"respawn_remaining": respawn.remaining, "health": health}

func restore(data: Dictionary) -> void:
	health = clampi(int(get_parent()._num(data.get("health"), MAX_HEALTH)), 0, MAX_HEALTH)
	respawn.restore(data, health <= 0)
	swipe_ready = false
	swipe_cooldown = 0
	swipe_side = 1
	art.swipe_side = swipe_side
	global_position = HOME
	velocity = Vector3.ZERO
	_set_state("idle" if health > 0 else "dead")
	visible = health > 0
	collider.set_deferred("disabled", health <= 0)

func _tone(frequency: float, duration: float) -> AudioStreamWAV:
	# Original synthesized voice: soft onset, descending harmonics, short decay.
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	var bytes := PackedByteArray()
	var count := int(duration * stream.mix_rate)
	bytes.resize(count * 2)
	for i in range(count):
		var t := float(i) / stream.mix_rate
		var envelope := minf(t / 0.07, 1) * pow(1 - t / duration, 1.6)
		var phase := TAU * frequency * (t - 0.12 * t * t / duration)
		var sample := (sin(phase) + 0.25 * sin(phase * 2.03)) * envelope * 13000
		bytes.encode_s16(i * 2, int(sample))
	stream.data = bytes
	return stream
