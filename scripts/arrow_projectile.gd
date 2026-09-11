extends Node3D
## Swept rays avoid tunneling. Impact converts the spent projectile into one recoverable arrow.
const Art = preload("res://scripts/archery_art.gd")
const Pickup = preload("res://scripts/resource_pickup.gd")
const MAX_AGE := 8.0
var velocity := Vector3.ZERO
var age := 0.0
var shooter_rid: RID
var landed := false

func _ready() -> void:
	add_to_group("flying_arrows")
	Art.arrow(self)

func _physics_process(delta: float) -> void:
	if landed:
		return
	age += delta
	if age > MAX_AGE or global_position.y < -15:
		queue_free()
		return
	var previous := global_position
	velocity += Vector3.DOWN * 9.8 * delta
	var next := previous + velocity * delta
	var excluded: Array[RID] = []
	if shooter_rid.is_valid():
		excluded.append(shooter_rid)
	var query := PhysicsRayQueryParameters3D.create(previous, next, 1, excluded)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		_land(hit)
		return
	global_position = next
	if velocity.length_squared() > 0.001:
		var direction := velocity.normalized()
		look_at(next + direction, Vector3.RIGHT if absf(direction.dot(Vector3.UP)) > 0.98 else Vector3.UP)

func _land(hit: Dictionary) -> void:
	landed = true
	if hit.collider.has_method("hit_by_arrow"):
		var message: String = hit.collider.hit_by_arrow(hit.position)
		var player := get_parent().get_node_or_null("Player")
		if player:
			player._show_feedback(message)
	var pickup := Pickup.new()
	pickup.item_id = "arrow"
	pickup.amount = 1
	get_parent().add_child(pickup)
	pickup.global_position = hit.position + hit.normal * 0.12
	if get_parent().has_method("mark_dirty"):
		get_parent().mark_dirty()
	queue_free()

func to_data() -> Dictionary:
	return {"x": global_position.x, "y": global_position.y, "z": global_position.z,
		"vx": velocity.x, "vy": velocity.y, "vz": velocity.z, "age": age}
