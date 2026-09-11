extends StaticBody3D
## A placeable banded chest. Its contents are an Inventory, exactly like the backpack.
const Model = preload("res://scripts/traveler_model.gd")
const Inventory = preload("res://scripts/inventory.gd")
var storage := Inventory.new(Inventory.CHEST_CAPACITY)
var lid: Node3D
var lid_motion: Tween
var is_open := false

func _ready() -> void:
	add_to_group("chests")
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.92, 0.62, 0.58)
	collision.shape = shape
	collision.position.y = 0.31
	add_child(collision)
	var wood := Color("a17b4e")
	var iron := Color("51564b")
	# An open inner cavity remains visible when the planked lid lifts.
	Model.box(self, Vector3(0, 0.06, 0), Vector3(0.9, 0.10, 0.55), wood.darkened(0.3))
	for row in range(3):
		var tone := wood.lightened(row * 0.035)
		for side in [-1.0, 1.0]:
			Model.box(self, Vector3(0, 0.17 + row * 0.13, side * 0.25), Vector3(0.90, 0.122, 0.05), tone)
			Model.box(self, Vector3(side * 0.425, 0.17 + row * 0.13, 0), Vector3(0.05, 0.122, 0.50), tone.darkened(0.06))
	for x in [-0.3, 0.3]:
		Model.box(self, Vector3(x, 0.25, 0), Vector3(0.07, 0.52, 0.575), iron)
		for z in [-0.292, 0.292]:
			for y in [0.15, 0.40]:
				Model.oval(self, Vector3(x, y, z), Vector3(0.026, 0.026, 0.016), Color("c2ad79"))
	Model.box(self, Vector3(0, 0.03, 0), Vector3(0.94, 0.06, 0.59), iron.darkened(0.2))
	# The lid pivots on its back edge so it can swing open while the chest is in use.
	lid = Node3D.new()
	lid.position = Vector3(0, 0.5, -0.275)
	add_child(lid)
	for i in range(4):
		Model.box(lid, Vector3(0, 0.06, 0.058 + i * 0.145), Vector3(0.92, 0.12, 0.138), wood.lightened(0.05 + i * 0.018))
	for x in [-0.3, 0.3]:
		Model.box(lid, Vector3(x, 0.065, 0.275), Vector3(0.07, 0.13, 0.59), iron)
	Model.box(lid, Vector3(0, 0.02, 0.565), Vector3(0.1, 0.1, 0.04), Color("c9b47a"))
	Model.box(lid, Vector3(0, 0.015, 0.587), Vector3(0.026, 0.038, 0.006), iron)
	storage.changed.connect(_contents_changed)

func prompt() -> String:
	return "E  •  Open storage chest   (%d / %d slots)" % [storage.used_slots(), Inventory.CHEST_CAPACITY]

func set_open(open: bool) -> void:
	is_open = open
	if lid_motion and lid_motion.is_valid():
		lid_motion.kill()
	lid_motion = create_tween()
	lid_motion.tween_property(lid, "rotation:x", -1.75 if open else 0.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _contents_changed() -> void:
	var world := get_parent()
	if world and world.has_method("mark_dirty"):
		world.mark_dirty()

func to_data() -> Dictionary:
	return {"x": global_position.x, "y": global_position.y, "z": global_position.z, "yaw": rotation.y, "slots": storage.to_data()}

func restore(data: Dictionary) -> void:
	storage.restore(data.get("slots", []))
