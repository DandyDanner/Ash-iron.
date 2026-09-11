extends StaticBody3D
const Model = preload("res://scripts/traveler_model.gd")
const USE_DISTANCE := 3.2
const STORAGE_RANGE := 8.0
var built := false
var copperworking := false
var art: Node3D
var sign_label: Label3D
var collision: CollisionShape3D

func _ready() -> void:
	add_to_group("workbenches")
	art = Node3D.new()
	add_child(art)
	collision = CollisionShape3D.new()
	add_child(collision)
	sign_label = Label3D.new()
	sign_label.font_size = 48
	sign_label.pixel_size = 0.002
	sign_label.position.y = 1.7
	sign_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sign_label.modulate = Color("efd494")
	add_child(sign_label)
	build()

func within_reach(player: Node3D) -> bool:
	if is_queued_for_deletion() or not built or player.global_position.distance_to(global_position + Vector3(0, 0.9, 0)) > USE_DISTANCE:
		return false
	var query := PhysicsRayQueryParameters3D.create(player.camera.global_position, global_position + Vector3(0, 0.9, 0), 1, [player.get_rid(), get_rid()])
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func linked_chests() -> Array:
	## Chests close to the bench count as connected storage: recipes can draw from them.
	var linked := []
	for chest in get_tree().get_nodes_in_group("chests"):
		if not chest.is_queued_for_deletion() and chest.global_position.distance_to(global_position) <= STORAGE_RANGE:
			linked.append(chest)
	return linked

func prompt() -> String:
	var connected := linked_chests().size()
	if connected == 0:
		return "E  •  Use workbench"
	return "E  •  Use workbench   (%d chest%s connected)" % [connected, "" if connected == 1 else "s"]

func build() -> bool:
	if built:
		return false
	built = true
	for child in art.get_children():
		child.queue_free()
	for side in [-1.0, 1.0]:
		for depth in [-1.0, 1.0]:
			var leg := Model.box(art, Vector3(side * 0.65, 0.43, depth * 0.32), Vector3(0.13, 0.85, 0.13), Color("795a3d"))
			leg.rotation.z = side * -0.08
	for i in range(5):
		Model.box(art, Vector3(0, 0.94, (i - 2) * 0.185), Vector3(1.9, 0.15, 0.175), Color("b18a57").lightened((i % 3) * 0.025))
		for side in [-1.0, 1.0]:
			Model.cylinder(art, Vector3(side * 0.66, 1.017, (i - 2) * 0.185), 0.014, 0.006, Color("674f37"))
	for side in [-1.0, 1.0]:
		Model.segment(art, Vector3(side * 0.65, 0.25, -0.32), Vector3(side * 0.65, 0.83, 0.32), 0.047, Color("947246"))
		Model.box(art, Vector3(side * 0.65, 0.83, 0), Vector3(0.15, 0.12, 0.9), Color("86633e"))
	Model.box(art, Vector3(0, 0.45, 0), Vector3(1.5, 0.1, 0.1), Color("795a3d"))
	Model.oval(art, Vector3(0.4, 1.06, 0), Vector3(0.28, 0.12, 0.25), Color("8e978b"))
	Model.box(art, Vector3(-0.3, 1.04, 0), Vector3(0.3, 0.035, 0.25), Color("c5b582"))
	Model.segment(art, Vector3(-0.66, 1.045, 0.20), Vector3(-0.22, 1.045, 0.30), 0.020, Color("715336"))
	Model.oval(art, Vector3(-0.61, 1.075, 0.21), Vector3(0.14, 0.11, 0.20), Color("8b9585"))
	sign_label.text = "SIMPLE WORKBENCH\nE • Craft tools"
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.9, 1.05, 1.0)
	collision.shape = shape
	collision.position.y = 0.525
	return true

func show_copperworking() -> void:
	if copperworking: return
	copperworking = true
	sign_label.text = "COPPERWORKING BENCH\nE • Craft tools"
	for x in [-0.78, 0.78]:
		Model.box(art, Vector3(x, 1.025, 0), Vector3(0.11, 0.035, 0.95), Color("bd784b"))
	Model.box(art, Vector3(0.15, 1.09, -0.2), Vector3(0.36, 0.14, 0.24), Color("c98752"))

func to_data() -> Dictionary:
	return {"x": global_position.x, "y": global_position.y, "z": global_position.z, "yaw": rotation.y}
