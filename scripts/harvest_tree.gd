extends StaticBody3D
const Model = preload("res://scripts/traveler_model.gd")
const Bundle = preload("res://scripts/wood_bundle.gd")
const MAX_HITS := 4
var hits_left := MAX_HITS
var crown: Node3D
var trunk_collision: CollisionShape3D
var response: Tween

func _ready() -> void:
	add_to_group("harvest_trees")
	crown = Node3D.new()
	add_child(crown)
	Model.cylinder(crown, Vector3(0, 2.0, 0), 0.38, 4.0, Color("69503a"), 0.22)
	for i in range(3):
		Model.cylinder(crown, Vector3(0, 3.3 + i * 0.8, 0), 1.65 - i * 0.35, 2.0, Color("456b45").lightened(i * 0.065), 0.05)
	trunk_collision = CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 0.38
	shape.height = 4.0
	trunk_collision.shape = shape
	trunk_collision.position.y = 2.0
	add_child(trunk_collision)

func prompt() -> String:
	return "Left click  •  Chop pine   (%d / %d)" % [MAX_HITS - hits_left, MAX_HITS] if hits_left > 0 else ""

func chop(hit_position: Vector3) -> bool:
	if hits_left <= 0:
		return false
	hits_left -= 1
	_chips(hit_position)
	if response and response.is_valid():
		response.kill()
	response = create_tween()
	if hits_left == 0:
		# The fall is visual only; the stump remains solid and cannot grant more wood.
		trunk_collision.set_deferred("disabled", true)
		Model.cylinder(self, Vector3(0, 0.15, 0), 0.4, 0.3, Color("b18d5e"))
		var stump := CollisionShape3D.new()
		var stump_shape := CylinderShape3D.new()
		stump_shape.radius = 0.4
		stump_shape.height = 0.3
		stump.shape = stump_shape
		stump.position.y = 0.15
		add_child(stump)
		response.tween_property(crown, "rotation:x", -PI / 2, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		response.tween_callback(_drop_wood)
		response.tween_interval(1.0)
		response.tween_property(crown, "scale", Vector3.ZERO, 0.45)
		response.tween_callback(crown.queue_free)
	else:
		response.tween_property(crown, "rotation:z", 0.035, 0.07)
		response.tween_property(crown, "rotation:z", 0.0, 0.14)
	return true

func _drop_wood() -> void:
	var bundle := Bundle.new()
	bundle.position = position + Vector3(0, 0.18, 1.0)
	get_parent().add_child(bundle)

func _chips(hit_position: Vector3) -> void:
	for i in range(7):
		var chip := Model.box(get_parent(), hit_position, Vector3(0.045, 0.07, 0.035), Color("d1ab70"))
		chip.global_position = hit_position
		var flight := create_tween().set_parallel(true)
		flight.tween_property(chip, "position", chip.position + Vector3(randf_range(-0.5, 0.5), randf_range(-0.2, 0.5), randf_range(-0.1, 0.6)), 0.3)
		flight.tween_property(chip, "scale", Vector3.ZERO, 0.4)
		flight.chain().tween_callback(chip.queue_free)
