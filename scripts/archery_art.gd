extends RefCounted
## Shared native bow and arrow for held gear, carry, projectiles, and world pickups.
const Model = preload("res://scripts/traveler_model.gd")
const Equipment = preload("res://scripts/native_equipment.gd")

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
	result.name = "NativeArrow"
	parent.add_child(result)
	Equipment.add(result, "arrow")
	return result

# Bow coordinates: grip at the origin, limbs along Y, shooting direction -Z.
const STRING_REST := 0.16
const DRAW_LENGTH := 0.34
const ARROW_REST := Vector3(0.045, 0.09, 0)

static func bow(parent: Node3D) -> Dictionary:
	var native := Equipment.add(parent, "bow", "ShortBowNativeAsset")
	var rig := Equipment.bow_rig(native)
	var lower := segment(parent, rig.rest_lower, ARROW_REST + Vector3(0, 0, STRING_REST), 0.003, Color("eee0bb"))
	lower.name = "LowerString"
	var upper := segment(parent, ARROW_REST + Vector3(0, 0, STRING_REST), rig.rest_upper, 0.003, Color("eee0bb"))
	upper.name = "UpperString"
	return {"lower": lower, "upper": upper, "native": native, "rig": rig}

static func pose_bow(parts: Dictionary, pull: float) -> Vector3:
	var center := ARROW_REST + Vector3(0, 0, STRING_REST + pull * DRAW_LENGTH)
	var tips := Equipment.pose_bow(parts.rig, pull)
	place_segment(parts.lower, tips.lower, center)
	place_segment(parts.upper, center, tips.upper)
	return center
