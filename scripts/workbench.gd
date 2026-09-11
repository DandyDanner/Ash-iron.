extends StaticBody3D
const Model = preload("res://scripts/traveler_model.gd")
const USE_DISTANCE := 3.2
const STORAGE_RANGE := 8.0
var built := false
var art: Node3D
var sign_label: Label3D
var collision: CollisionShape3D

func _ready() -> void:
	add_to_group("workbenches")
	art = Node3D.new()
	add_child(art)
	collision = CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.8, 1.4, 0.15)
	collision.shape = shape
	collision.position.y = 0.7
	add_child(collision)
	sign_label = Label3D.new()
	sign_label.text = "CAMP WORKSITE\nE • Build your first bench"
	sign_label.font_size = 48
	sign_label.pixel_size = 0.002
	sign_label.position.y = 1.7
	sign_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sign_label.modulate = Color("efd494")
	add_child(sign_label)
	for side in [-1.0, 1.0]:
		for depth in [-1.0, 1.0]:
			Model.cylinder(art, Vector3(side * 0.8, 0.15, depth * 0.4), 0.045, 0.3, Color("bb9f68"))
	Model.box(art, Vector3(0, 0.012, 0), Vector3(1.8, 0.025, 1.0), Color("798063"))
	Model.cylinder(art, Vector3(0, 0.65, 0), 0.05, 1.3, Color("98754a"))
	Model.box(art, Vector3(0, 1.15, 0), Vector3(0.8, 0.35, 0.08), Color("bc9a63"))

func within_reach(player: Node3D) -> bool:
	return player.global_position.distance_to(global_position + Vector3(0, 0.9, 0)) <= USE_DISTANCE

func linked_chests() -> Array:
	## Chests close to the bench count as connected storage: recipes can draw from them.
	var linked := []
	for chest in get_tree().get_nodes_in_group("chests"):
		if not chest.is_queued_for_deletion() and chest.global_position.distance_to(global_position) <= STORAGE_RANGE:
			linked.append(chest)
	return linked

func prompt() -> String:
	if not built:
		return "E  •  Build a simple bench (6 sticks + 4 stones)"
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
	for i in range(4):
		Model.cylinder(art, Vector3(0, 0.91, (i - 1.5) * 0.21), 0.12, 1.9, Color("b18a57")).rotation.z = PI / 2
	Model.box(art, Vector3(0, 0.45, 0), Vector3(1.5, 0.1, 0.1), Color("795a3d"))
	Model.oval(art, Vector3(0.4, 1.06, 0), Vector3(0.28, 0.12, 0.25), Color("8e978b"))
	Model.box(art, Vector3(-0.3, 1.04, 0), Vector3(0.3, 0.035, 0.25), Color("c5b582"))
	sign_label.text = "SIMPLE WORKBENCH\nE • Craft tools"
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.9, 1.05, 1.0)
	collision.shape = shape
	collision.position.y = 0.525
	return true
