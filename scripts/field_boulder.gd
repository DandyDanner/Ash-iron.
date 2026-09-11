extends StaticBody3D
const Model = preload("res://scripts/traveler_model.gd")
@export var dimensions := Vector3(3, 2, 3)

func _ready() -> void:
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = 7
	mesh.rings = 3
	Model.part(self, mesh, Vector3.ZERO, Color("798375"), dimensions)
	var vertices: PackedVector3Array = mesh.get_mesh_arrays()[Mesh.ARRAY_VERTEX]
	for i in range(vertices.size()):
		vertices[i] *= dimensions
	var shape := ConvexPolygonShape3D.new()
	shape.points = vertices
	var collision := CollisionShape3D.new()
	collision.shape = shape
	add_child(collision)

func prompt() -> String:
	return "Large boulder • Gather the loose stones nearby"
