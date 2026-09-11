extends RefCounted
## Original stone pick: hooked point, broad rear chisel, and a lashed hardwood haft.
const Model = preload("res://scripts/traveler_model.gd")

static func build(parent: Node3D) -> void:
	Model.loft(parent, [Vector4(-0.16, 0.026, 0.026, 0), Vector4(-0.10, 0.024, 0.024, 0), Vector4(0.20, 0.021, 0.025, 0), Vector4(0.49, 0.031, 0.028, 0), Vector4(0.53, 0.026, 0.024, 0)], Color("976c41"), 8)
	for i in range(7):
		var wrap := Model.cylinder(parent, Vector3(0, -0.11 + i * 0.026, 0), 0.029, 0.019, Color("514033"))
		wrap.rotation.z = 0.10
	Model.cylinder(parent, Vector3(0, -0.15, 0), 0.03, 0.018, Color("b18a57"))
	# Octagonal sections taper into a curved front point and a flat rear cutting edge.
	# Transform the loft's length axis to X and its curved centerline to Y.
	var head := Model.loft(parent, [Vector4(-0.38, 0.004, 0.004, 0.31), Vector4(-0.30, 0.014, 0.019, 0.38), Vector4(-0.17, 0.029, 0.040, 0.45), Vector4(-0.06, 0.043, 0.057, 0.465), Vector4(0.06, 0.043, 0.057, 0.465), Vector4(0.18, 0.029, 0.038, 0.44), Vector4(0.28, 0.043, 0.009, 0.38)], Color("78857d"), 8)
	head.name = "FacetedStoneHead"
	head.basis = Basis(Vector3.BACK, Vector3.RIGHT, Vector3.UP)
	var socket := Model.loft(parent, [Vector4(0.37, 0.041, 0.038, 0), Vector4(0.40, 0.055, 0.049, 0), Vector4(0.49, 0.055, 0.049, 0), Vector4(0.515, 0.039, 0.035, 0)], Color("58665e"), 8)
	socket.name = "HeadSocket"
	for x in [-0.045, 0.045]:
		var loop := [Vector3(x, 0.399, -0.049), Vector3(x, 0.516, -0.049), Vector3(x, 0.527, 0), Vector3(x, 0.516, 0.049), Vector3(x, 0.399, 0.049), Vector3(x, 0.390, 0)]
		for i in range(loop.size()):
			Model.segment(parent, loop[i], loop[(i + 1) % loop.size()], 0.009, Color("c4ac7b"))
	Model.segment(parent, Vector3(-0.05, 0.40, 0.058), Vector3(0.05, 0.51, 0.058), 0.008, Color("d3bd8c"))
