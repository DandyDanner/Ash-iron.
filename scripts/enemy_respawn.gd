extends RefCounted
## Active-play countdown, persisted across saves. Wait until home is clear and out of view range.
const DELAY := 120.0
const SAFE_DISTANCE := 8.0
var remaining := 0.0

func start() -> void:
	remaining = DELAY

func restore(data: Dictionary, dead: bool) -> void:
	var value: Variant = data.get("respawn_remaining", DELAY)
	remaining = clampf(float(value), 0, DELAY) if dead and (value is float or value is int) else (DELAY if dead else 0.0)

func advance(enemy: CharacterBody3D, player: Node3D, delta: float) -> void:
	if not is_instance_valid(player) or not player.controls_active: return
	remaining = maxf(0, remaining - delta)
	if remaining > 0 or player.global_position.distance_to(enemy.HOME) < SAFE_DISTANCE: return
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = enemy.collider.shape
	query.transform = enemy.collider.global_transform
	query.transform.origin = enemy.HOME + enemy.collider.position
	query.collision_mask = 1
	query.exclude = [enemy.get_rid()]
	if not enemy.get_world_3d().direct_space_state.intersect_shape(query).is_empty(): return
	enemy.restore({"health": enemy.MAX_HEALTH})
	enemy.hit_flash = 0
	enemy.get_parent().mark_dirty()
