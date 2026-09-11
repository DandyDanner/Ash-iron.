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

# Bow coordinates: grip at the origin, limbs along Y, shooting direction -Z.
const HALF_HEIGHT := 0.68
const STRING_REST := 0.16
const DRAW_LENGTH := 0.34
const ARROW_REST := Vector3(0.045, 0.09, 0)

static func limb_point(t: float, side: float, pull: float) -> Vector3:
	var curve := 0.20 * sin(t * PI / 2) - 0.08 * smoothstep(0.78, 1.0, t)
	return Vector3(0, side * t * HALF_HEIGHT, curve + pull * 0.055 * sin(t * PI))

static func bow(parent: Node3D) -> Dictionary:
	var limbs: Array[MeshInstance3D] = []
	for side in [-1.0, 1.0]:
		for i in range(12):
			var t := float(i) / 12
			var limb := segment(parent, limb_point(t, side, 0), limb_point(t + 1.0 / 12, side, 0), lerpf(0.027, 0.010, t), Color("aa7547"))
			limb.name = "Limb_%s_%d" % [side, i]
			limbs.append(limb)
		# Pale horn tips and contrasting bindings make the recurve silhouette readable.
		segment(parent, limb_point(0.94, side, 0), limb_point(1, side, 0), 0.014, Color("d4c5a0"))
		for y in [0.12, 0.15]:
			Model.cylinder(parent, limb_point(y / HALF_HEIGHT, side, 0), 0.029, 0.012, Color("d0b481"))
	for i in range(7):
		Model.cylinder(parent, Vector3(0, -0.075 + i * 0.025, 0), 0.034, 0.021, Color("465c4c"))
	var lower := segment(parent, limb_point(1, -1, 0), ARROW_REST + Vector3(0, 0, STRING_REST), 0.003, Color("eee0bb"))
	var upper := segment(parent, ARROW_REST + Vector3(0, 0, STRING_REST), limb_point(1, 1, 0), 0.003, Color("eee0bb"))
	return {"lower": lower, "upper": upper, "limbs": limbs}

static func pose_bow(parts: Dictionary, pull: float) -> Vector3:
	var center := ARROW_REST + Vector3(0, 0, STRING_REST + pull * DRAW_LENGTH)
	place_segment(parts.lower, limb_point(1, -1, pull), center)
	place_segment(parts.upper, center, limb_point(1, 1, pull))
	for side_index in range(2):
		var side := -1.0 if side_index == 0 else 1.0
		for i in range(12):
			place_segment(parts.limbs[side_index * 12 + i], limb_point(float(i) / 12, side, pull), limb_point(float(i + 1) / 12, side, pull))
	return center
