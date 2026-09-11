extends StaticBody3D
const Model = preload("res://scripts/traveler_model.gd")
@export var dimensions := Vector3(3, 2, 3)
## Ordinary boulders hide a little iron: each strike may also shed one chunk of ore.
@export var ore_chance := 0.35
var last_ore := false
var rng := RandomNumberGenerator.new()

var hits_left := 4
var art: Node3D
var collision: CollisionShape3D

func _ready() -> void:
	add_to_group("mineable_rocks")
	rng.seed = hash(str(name) + str(position))
	art = Node3D.new()
	add_child(art)
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = 7
	mesh.rings = 3
	Model.part(art, mesh, Vector3.ZERO, Color("929b89"), dimensions)
	# Lichen patches sit on the upper facets; all decoration follows depletion.
	for i in range(5):
		var angle := i * 2.4
		var patch := Model.oval(art, Vector3(sin(angle) * dimensions.x * 0.16, dimensions.y * (0.41 - (i % 2) * 0.035), cos(angle) * dimensions.z * 0.13), Vector3(dimensions.x * 0.22, dimensions.y * 0.065, dimensions.z * 0.19), Color("788b50").lightened((i % 3) * 0.04))
		patch.rotation.z = -sin(angle) * 0.30
	var vertices: PackedVector3Array = mesh.get_mesh_arrays()[Mesh.ARRAY_VERTEX]
	for i in range(vertices.size()):
		vertices[i] *= dimensions
	var shape := ConvexPolygonShape3D.new()
	shape.points = vertices
	collision = CollisionShape3D.new()
	collision.shape = shape
	add_child(collision)

func prompt() -> String:
	return "Stone pickaxe • Left click to mine (%d / 4)" % (4 - hits_left) if hits_left > 0 else "Depleted boulder"

func mined_message() -> String:
	var base := "Boulder broken! E to gather stones." if hits_left == 0 else "Stone chipped"
	return base + ("  •  A chunk of iron ore!" if last_ore else "")

func mine(hit_position: Vector3) -> bool:
	if hits_left <= 0:
		return false
	hits_left -= 1
	# Every impact sheds two stones outside the rock, on the player's side.
	var outward := hit_position - global_position
	outward.y = 0
	outward = outward.normalized() if outward.length_squared() > 0.001 else Vector3.FORWARD
	var spot := global_position + outward * (maxf(dimensions.x, dimensions.z) * 0.5 + 0.65)
	_shed("stone", 2, spot)
	last_ore = rng.randf() < ore_chance
	if last_ore:
		_shed("iron_ore", 1, spot + Vector3(cos(hits_left * 2.3), 0, sin(hits_left * 2.3)) * 0.5)
	restore(hits_left)
	return true

func _shed(item: String, amount: int, spot: Vector3) -> void:
	var query := PhysicsRayQueryParameters3D.create(spot + Vector3.UP * 3, spot + Vector3.DOWN * 6, 1, [get_rid()])
	var ground := get_world_3d().direct_space_state.intersect_ray(query)
	var pickup := preload("res://scripts/resource_pickup.gd").new()
	pickup.item_id = item
	pickup.amount = amount
	get_parent().add_child(pickup)
	pickup.global_position = ground.position + Vector3(0, 0.04, 0) if not ground.is_empty() else Vector3(spot.x, 0.24, spot.z)

func restore(hits: int) -> void:
	hits_left = clampi(hits, 0, 4)
	art.scale = Vector3.ONE * (0.23 if hits_left == 0 else 1.0)
	art.position.y = -dimensions.y * 0.5 * (1.0 - art.scale.y)
	collision.set_deferred("scale", art.scale)
	collision.set_deferred("position", art.position)
	if hits_left == 0:
		collision.set_deferred("disabled", true)
