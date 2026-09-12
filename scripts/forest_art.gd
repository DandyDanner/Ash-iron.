extends RefCounted
## Shared supplied pine for harvestable trees and the portrait stage.
static func pine(parent: Node3D, variation: int = 0) -> void:
	preload("res://scripts/imported_props.gd").pine(parent, variation)
