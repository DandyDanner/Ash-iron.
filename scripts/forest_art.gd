extends RefCounted
## Reusable stylized tree shapes for harvestable trees and the portrait stage.
const Model = preload("res://scripts/traveler_model.gd")

static func pine(parent: Node3D, variation: int = 0) -> void:
	Model.loft(parent, [Vector4(0, 0.39, 0.36, 0), Vector4(0.35, 0.29, 0.27, 0), Vector4(2.0, 0.23, 0.22, 0.06), Vector4(3.5, 0.13, 0.12, 0.03), Vector4(4.7, 0.02, 0.02, 0)], Color("756046"), 9)
	for i in range(5):
		var a := i * TAU / 5.0 + variation * 0.3
		Model.segment(parent, Vector3(sin(a) * 0.6, 0.08, cos(a) * 0.6), Vector3(sin(a) * 0.18, 0.65, cos(a) * 0.18), 0.07, Color("756046"), 0.045)
	for i in range(7):
		var a := i * 2.4 + variation
		var height := 2.7 + (i / 3) * 0.72
		var radius := 0.68 if i < 4 else 0.39
		var pos := Vector3(sin(a) * radius, height, cos(a) * radius)
		Model.segment(parent, Vector3(0, height - 0.6, 0), pos, 0.065, Color("826849"), 0.025)
		var color := Color("527650").lightened((i % 3) * 0.065)
		var leaves := Model.oval(parent, pos, Vector3(2.1 - (i / 4) * 0.38, 1.35, 1.9 - (i / 4) * 0.26), color)
		leaves.rotation.y = a
	Model.oval(parent, Vector3(0, 4.35, 0), Vector3(1.5, 1.6, 1.55), Color("75904f"))
