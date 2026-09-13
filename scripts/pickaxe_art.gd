extends RefCounted
## Native stone pick normalized to the established palm/head contract.
const Equipment = preload("res://scripts/native_equipment.gd")

static func build(parent: Node3D) -> void:
	Equipment.add(parent, "stone_pickaxe")
