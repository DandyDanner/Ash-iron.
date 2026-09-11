extends RefCounted
## Original leaf-shaped stone spear. The point faces -Z; the palm grip is at zero.
const Model = preload("res://scripts/traveler_model.gd")

static func build(parent: Node3D) -> void:
	var shaft := Model.cylinder(parent, Vector3(0, 0, -0.26), 0.021, 1.48, Color("9d7547"), 0.017)
	shaft.rotation.x = PI / 2
	for i in range(7):
		var grip := Model.cylinder(parent, Vector3(0, 0, -0.09 + i * 0.03), 0.026, 0.024, Color("465b4b"))
		grip.rotation.x = PI / 2
	var blade := Model.loft(parent, [Vector4(0.92, 0.023, 0.012, 0), Vector4(0.99, 0.078, 0.023, 0), Vector4(1.10, 0.067, 0.018, 0), Vector4(1.28, 0.002, 0.002, 0)], Color("97a394"), 4)
	blade.rotation.x = -PI / 2
	blade.name = "StonePoint"
	for i in range(5):
		var binding := Model.cylinder(parent, Vector3(0, 0, -0.91 - i * 0.021), 0.027, 0.016, Color("ccb689"))
		binding.rotation.x = PI / 2
	var butt := Model.cylinder(parent, Vector3(0, 0, 0.47), 0.025, 0.055, Color("554333"))
	butt.rotation.x = PI / 2
