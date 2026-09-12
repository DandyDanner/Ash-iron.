extends StaticBody3D
## A placeable banded chest. Its contents are an Inventory, exactly like the backpack.
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
	lid = preload("res://scripts/imported_props.gd").chest(self)
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
