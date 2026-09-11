extends Node3D
const Pickup = preload("res://scripts/resource_pickup.gd")
const Bench = preload("res://scripts/workbench.gd")

func _ready() -> void:
	var bench := Bench.new()
	bench.name = "CampWorkbench"
	bench.position = Vector3(-3.5, 0.2, 0.3)
	add_child(bench)
	var target := preload("res://scripts/archery_target.gd").new()
	target.name = "PracticeTarget"
	target.position = Vector3(10, 0.2, -9)
	add_child(target)
	# Guaranteed starting supplies: the player never needs a tool to make their first tool.
	var sticks := [Vector2(-1, 4), Vector2(1.2, 4.2), Vector2(-2, 2.5), Vector2(2, 2.8), Vector2(-2, -1.4), Vector2(3.3, 0.8), Vector2(5.5, 2.5), Vector2(-5.5, 1), Vector2(-4, -2), Vector2(4, -2), Vector2(7, -1), Vector2(-6, -5), Vector2(1, -5), Vector2(-2, -7), Vector2(6, -10), Vector2(-7, 6), Vector2(4.5, 7), Vector2(-1, 9)]
	var stones := [Vector2(-0.9, 3), Vector2(1, 2), Vector2(-2.4, 4.8), Vector2(2.6, 4.8), Vector2(3.8, -4.8), Vector2(6.5, -5), Vector2(7, -7), Vector2(4, -9.5), Vector2(-4.5, -3.2), Vector2(-7.5, -2), Vector2(-5, -7), Vector2(0, -9), Vector2(-4, 7), Vector2(6, 6)]
	for item in ["stick", "stone"]:
		var positions: Array = sticks if item == "stick" else stones
		for i in range(positions.size()):
			var pickup := Pickup.new()
			pickup.name = item + "_" + str(i)
			pickup.item_id = item
			pickup.position = Vector3(positions[i].x, 0.22, positions[i].y)
			pickup.rotation.y = i * 0.77
			add_child(pickup)
