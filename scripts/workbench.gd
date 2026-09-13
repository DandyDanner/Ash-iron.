extends StaticBody3D
const Model = preload("res://scripts/traveler_model.gd")
const NATIVE_SCENE = preload("res://assets/props/workbench.glb")
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
	var native: Node3D = NATIVE_SCENE.instantiate()
	native.name = "NativeWorkbench"
	art.add_child(native)
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
	var kit := Node3D.new()
	kit.name = "CopperworkingKit"
	art.add_child(kit)
	for x in [-0.78, 0.78]:
		Model.box(kit, Vector3(x, 0.825, 0), Vector3(0.08, 0.035, 0.78), Color("bd784b"))
	Model.box(kit, Vector3(0.15, 0.89, -0.2), Vector3(0.36, 0.14, 0.24), Color("c98752"))

func to_data() -> Dictionary:
	return {"x": global_position.x, "y": global_position.y, "z": global_position.z, "yaw": rotation.y}
