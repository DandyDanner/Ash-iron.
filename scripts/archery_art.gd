extends RefCounted
## Shared original bow and arrow silhouettes for held gear and world pickups.
const Model = preload("res://scripts/traveler_model.gd")

static func segment(parent: Node3D, a: Vector3, b: Vector3, radius: float, color: Color) -> MeshInstance3D:
	var mesh := Model.cylinder(parent, Vector3.ZERO, radius, 1.0, color)
	place_segment(mesh, a, b)
	return mesh

static func place_segment(mesh: Node3D, a: Vector3, b: Vector3) -> void:
	mesh.position = (a + b) * 0.5
	mesh.quaternion = Quaternion(Vector3.UP, (b - a).normalized())
	mesh.scale = Vector3(1, a.distance_to(b), 1)

static func arrow(parent: Node3D) -> Node3D:
	var result := Node3D.new()
	parent.add_child(result)
	var shaft := Model.cylinder(result, Vector3.ZERO, 0.012, 0.78, Color("ceb685"), 0.009)
	shaft.rotation.x = PI / 2
	var tip := Model.cylinder(result, Vector3(0, 0, -0.43), 0.035, 0.11, Color("7f9698"), 0.0)
	tip.rotation.x = -PI / 2
	for angle in [0.0, PI / 2]:
		var feather := Model.box(result, Vector3(0, 0, 0.27), Vector3(0.105, 0.009, 0.13), Color("d7ded0"))
		feather.rotation.z = angle
	return result

static func bow(parent: Node3D) -> Dictionary:
	var points := [Vector3(0, -0.52, 0.04), Vector3(-0.10, -0.35, -0.06), Vector3(-0.13, -0.16, -0.15), Vector3(-0.10, 0, -0.18), Vector3(-0.13, 0.16, -0.15), Vector3(-0.10, 0.35, -0.06), Vector3(0, 0.52, 0.04)]
	for i in range(points.size() - 1):
		segment(parent, points[i], points[i + 1], 0.024, Color("b0804e"))
	for i in range(5):
		Model.cylinder(parent, Vector3(-0.10, -0.07 + i * 0.035, -0.18), 0.033, 0.025, Color("465c4c"))
	var lower := segment(parent, points[0], Vector3.ZERO, 0.004, Color("e4d4ab"))
	var upper := segment(parent, Vector3.ZERO, points[-1], 0.004, Color("e4d4ab"))
	return {"lower": lower, "upper": upper}
