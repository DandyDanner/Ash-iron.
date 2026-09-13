extends RefCounted
## Native stone spear. The point faces -Z; the palm grip remains at zero.
const Equipment = preload("res://scripts/native_equipment.gd")

static func build(parent: Node3D) -> void:
	Equipment.add(parent, "stone_spear")
