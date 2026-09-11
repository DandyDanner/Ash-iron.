extends CharacterBody3D
## Territorial first enemy: approach, readable warning, committed charge, recovery.
const Art = preload("res://scripts/bristleback_model.gd")
const Pickup = preload("res://scripts/resource_pickup.gd")
const MAX_HEALTH := 60
const HOME := Vector3(-15, 0.22, -13)
const NOTICE_RADIUS := 8.0
const LEASH_RADIUS := 13.0
var respawn := preload("res://scripts/enemy_respawn.gd").new()
var health := MAX_HEALTH
var state := "idle"
var state_time := 0.0
var charge_direction := Vector3.ZERO
var struck := false
var art: Node3D
var label: Label3D
var collider: CollisionShape3D
var hit_flash := 0.0
var player: Node3D

func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 1
	collision_mask = 1
	floor_snap_length = 0.4
	art = Art.new()
	add_child(art)
	collider = CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.42
	shape.height = 1.35
	collider.shape = shape
	collider.position = Vector3(0, 0.42, 0.1)
	collider.rotation.x = PI / 2
	add_child(collider)
	label = Label3D.new()
	label.position = Vector3(0, 1.65, 0)
	label.font_size = 34
	label.pixel_size = 0.007
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)
	player = get_parent().get_node_or_null("Player")
	_refresh()

func _physics_process(delta: float) -> void:
	if health <= 0:
		respawn.advance(self, player, delta)
		return
	if not is_instance_valid(player) or not player.controls_active:
		return
	state_time += delta
	hit_flash = maxf(0, hit_flash - delta)
	var offset: Vector3 = player.global_position - global_position
	offset.y = 0
	var distance := offset.length()
	var from_home := Vector2(global_position.x - HOME.x, global_position.z - HOME.z).length()
	var player_from_home := Vector2(player.global_position.x - HOME.x, player.global_position.z - HOME.z).length()
	if state != "return" and (from_home > LEASH_RADIUS or player_from_home > LEASH_RADIUS + 2 or player.global_position.distance_to(player.spawn_position) < 6):
		_set_state("return")
	var direction := Vector3.ZERO
	var speed := 0.0
	match state:
		"idle":
			if distance < NOTICE_RADIUS and _sees_player(): _set_state("approach")
		"approach":
			direction = offset.normalized()
			speed = 2.2
			if distance < 5 and _sees_player():
				charge_direction = direction
				_set_state("warn")
		"warn":
			direction = charge_direction
			if state_time >= 1.0: _set_state("charge")
		"charge":
			direction = charge_direction
			speed = 7.5
			if state_time >= 1.05: _set_state("recover")
		"recover":
			if state_time >= 1.6: _set_state("approach")
		"return":
			var home_offset := HOME - global_position
			home_offset.y = 0
			direction = home_offset.normalized()
			speed = 2.5
			if home_offset.length() < 0.5:
				health = MAX_HEALTH
				_set_state("idle")
	if state in ["approach", "return"] and speed > 0:
		direction = _clear_direction(direction)
	if direction.length_squared() > 0.1:
		rotation.y = lerp_angle(rotation.y, atan2(direction.x, direction.z), minf(1, delta * 10))
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	velocity.y = -0.5 if is_on_floor() else velocity.y - 9.8 * delta
	move_and_slide()
	if state == "charge":
		for i in range(get_slide_collision_count()):
			var hit := get_slide_collision(i)
			if absf(hit.get_normal().y) < 0.6:
				if hit.get_collider() == player and not struck:
					struck = true
					player.receive_damage(25)
				_set_state("recover")
				break
	art.pose(delta, Vector2(velocity.x, velocity.z).length(), state, hit_flash)
	_refresh()

func _clear_direction(desired: Vector3) -> Vector3:
	# Short body-width probes let the boar go around trunks while approaching/returning.
	for angle in [0.0, 0.8, -0.8, 1.4, -1.4]:
		var candidate := desired.rotated(Vector3.UP, angle)
		var side := candidate.cross(Vector3.UP).normalized() * 0.35
		var clear := true
		for lateral in [-side, side]:
			var origin: Vector3 = global_position + Vector3.UP * 0.5 + lateral
			var query := PhysicsRayQueryParameters3D.create(origin, origin + candidate * 1.5, 1, [get_rid(), player.get_rid()])
			if not get_world_3d().direct_space_state.intersect_ray(query).is_empty(): clear = false
		if clear: return candidate
	return Vector3.ZERO

func _sees_player() -> bool:
	var origin := global_position + Vector3.UP * 0.7
	var query := PhysicsRayQueryParameters3D.create(origin, player.global_position, 1, [get_rid()])
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return not hit.is_empty() and hit.collider == player

func _set_state(next: String) -> void:
	state = next
	state_time = 0
	if next == "charge": struck = false
	_refresh()

func _refresh() -> void:
	label.visible = health > 0 and state != "idle" and state != "return"
	label.text = "Bristleback  %d / %d\n%s" % [health, MAX_HEALTH, "CHARGE INCOMING — sidestep!" if state == "warn" else ("Recovering — strike now" if state == "recover" else "")]
	label.modulate = Color("f5b76c") if state == "warn" else Color("fff0c6")

func receive_melee_hit(damage: int, _point: Vector3) -> String:
	return _take_hit(damage)

func hit_by_arrow(_point: Vector3) -> String:
	return _take_hit(25)

func _take_hit(damage: int) -> String:
	if health <= 0 or damage <= 0: return ""
	health = maxi(0, health - damage)
	hit_flash = 0.22
	if health == 0:
		respawn.start()
		state = "dead"
		hide()
		collider.set_deferred("disabled", true)
		var drop := Pickup.new()
		drop.item_id = "boar_hide"
		drop.amount = 1
		get_parent().add_child(drop)
		drop.global_position = global_position + Vector3.UP * 0.05
	else:
		if state in ["idle", "return"]: _set_state("approach")
	_refresh()
	get_parent().mark_dirty()
	return "Bristleback defeated • E to gather its hide" if health == 0 else "Bristleback: %d / %d" % [health, MAX_HEALTH]

func to_data() -> Dictionary:
	return {"respawn_remaining": respawn.remaining, "health": health, "x": global_position.x, "y": global_position.y, "z": global_position.z}

func restore(data: Dictionary) -> void:
	health = clampi(int(get_parent()._num(data.get("health"), MAX_HEALTH)), 0, MAX_HEALTH)
	respawn.restore(data, health <= 0)
	global_position = get_parent()._vec(data, HOME)
	if global_position.distance_to(HOME) > 20: global_position = HOME
	velocity = Vector3.ZERO
	_set_state("idle" if health > 0 else "dead")
	visible = health > 0
	collider.set_deferred("disabled", health <= 0)
