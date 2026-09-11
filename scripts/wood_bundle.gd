extends Area3D
const Model = preload("res://scripts/traveler_model.gd")
var collected := false
const AMOUNT := 5
var item_id := "wood"
var amount := AMOUNT
var marker: Label3D

func _ready() -> void:
	add_to_group("wood_bundles")
	collision_layer = 2
	collision_mask = 0
	var collider := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.6
	collider.shape = shape
	add_child(collider)
	for i in range(3):
		var log_piece := Model.cylinder(self, Vector3((i - 1) * 0.22, 0.05 if i != 1 else 0.23, 0), 0.13, 0.7, Color("95633f"))
		log_piece.rotation.x = PI / 2
	Model.box(self, Vector3(0, 0.11, 0), Vector3(0.74, 0.26, 0.06), Color("c5ab73"))
	marker = Label3D.new()
	marker.text = "%d wood" % amount
	marker.position.y = 0.55
	marker.font_size = 48
	marker.pixel_size = 0.0015
	marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	marker.modulate = Color("f3d397")
	add_child(marker)

func prompt() -> String:
	return "E  •  Collect %d wood" % amount

func collect_into(inventory: RefCounted) -> int:
	if collected:
		return 0
	var received: int = inventory.add(item_id, amount)
	amount -= received
	marker.text = "%d wood" % amount
	if amount == 0:
		collected = true
		queue_free()
	return received
