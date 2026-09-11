extends Node3D
## Original shaped-mesh interpretation of the approved russet Bristleback concept.
const Model = preload("res://scripts/traveler_model.gd")
var body: Node3D
var head: Node3D
var legs: Array[Node3D] = []
var time := 0.0

func _ready() -> void:
	body = Model.joint(self, "Body", Vector3.ZERO)
	var torso := Model.loft(body, [Vector4(-0.72, 0.20, 0.24, -0.60), Vector4(-0.48, 0.35, 0.35, -0.65), Vector4(-0.05, 0.43, 0.43, -0.72), Vector4(0.32, 0.39, 0.40, -0.73), Vector4(0.57, 0.25, 0.28, -0.65)], Color("885334"), 12)
	torso.rotation.x = PI / 2
	for side in [-1.0, 1.0]:
		for z in [-0.45, 0.38]:
			var leg := Model.joint(body, "Leg", Vector3(side * 0.28, 0.45, z))
			legs.append(leg)
			Model.loft(leg, [Vector4(-0.35, 0.078, 0.082, 0), Vector4(-0.18, 0.092, 0.09, 0.035), Vector4(0.08, 0.12, 0.12, 0)], Color("5c4030"), 8)
			for hoof_side in [-1.0, 1.0]:
				Model.box(leg, Vector3(hoof_side * 0.04, -0.39, 0.035), Vector3(0.069, 0.12, 0.15), Color("33352d"))
		# Layered wedges on the shoulders read as clumped fur, not simulated strands.
		for i in range(5):
			var tuft := Model.loft(body, [Vector4(0, 0.09, 0.055, 0), Vector4(0.15, 0.13, 0.07, 0), Vector4(0.28, 0.008, 0.008, 0)], Color("a06a40").darkened(i * 0.04), 4)
			tuft.position = Vector3(side * 0.33, 0.64 + (i % 2) * 0.1, -0.38 + i * 0.16)
			tuft.rotation = Vector3(-0.6, 0, -side * 1.0)
	head = Model.joint(body, "Head", Vector3(0, 0.69, 0.47))
	var skull := Model.loft(head, [Vector4(0, 0.29, 0.31, -0.03), Vector4(0.23, 0.25, 0.25, 0.005), Vector4(0.48, 0.17, 0.15, 0.08), Vector4(0.68, 0.15, 0.11, 0.10)], Color("795034"), 8)
	skull.rotation.x = PI / 2
	var nose := Model.cylinder(head, Vector3(0, -0.10, 0.70), 0.15, 0.06, Color("49382e"))
	nose.rotation.x = PI / 2
	nose.scale.x = 1.12
	for side in [-1.0, 1.0]:
		Model.oval(head, Vector3(side * 0.064, -0.08, 0.736), Vector3(0.046, 0.029, 0.013), Color("211f1a"))
		Model.oval(head, Vector3(side * 0.224, 0.11, 0.23), Vector3(0.063, 0.052, 0.060), Color("392b1e"))
		Model.oval(head, Vector3(side * 0.241, 0.112, 0.247), Vector3(0.024, 0.028, 0.024), Color("c49745"))
		Model.oval(head, Vector3(side * 0.245, 0.114, 0.259), Vector3(0.010, 0.019, 0.012), Color("1e211b"))
		var brow := Model.box(head, Vector3(side * 0.235, 0.16, 0.22), Vector3(0.08, 0.035, 0.14), Color("533b29"))
		brow.rotation.z = -side * 0.25
		var ear := Model.loft(head, [Vector4(0, 0.08, 0.035, 0), Vector4(0.10, 0.12, 0.04, 0), Vector4(0.28, 0.006, 0.006, 0)], Color("5b3b2b"), 4)
		ear.position = Vector3(side * 0.20, 0.21, 0.02)
		ear.rotation = Vector3(-0.25, 0, -side * 0.55)
		var tusk_points := [Vector3(side * 0.15, -0.17, 0.50), Vector3(side * 0.24, -0.11, 0.56), Vector3(side * 0.26, 0.015, 0.59), Vector3(side * 0.22, 0.13, 0.61)]
		for i in range(3):
			var length: float = tusk_points[i].distance_to(tusk_points[i + 1])
			var tusk := Model.cylinder(head, (tusk_points[i] + tusk_points[i + 1]) * 0.5, 0.042 - i * 0.011, length, Color("dfcea0"), 0.002 if i == 2 else 0.031 - i * 0.011)
			tusk.quaternion = Quaternion(Vector3.UP, (tusk_points[i + 1] - tusk_points[i]).normalized())
	for i in range(9):
		var bristle := Model.loft(body, [Vector4(0, 0.11, 0.10, 0), Vector4(0.11, 0.075, 0.09, 0), Vector4(0.30 - absf(i - 5) * 0.025, 0.004, 0.004, -0.09)], Color("3e352b"), 4)
		bristle.position = Vector3((i % 2 - 0.5) * 0.09, 0.93 + sin(i / 8.0 * PI) * 0.12, -0.59 + i * 0.135)
	Model.segment(body, Vector3(0, 0.63, -0.68), Vector3(0.08, 0.53, -0.90), 0.018, Color("5b3b2b"))

func pose(delta: float, speed: float, state: String, hit_flash: float) -> void:
	time += delta
	var stride := sin(time * (12 if state == "charge" else 6)) * minf(speed / 5, 1) * 0.5
	for i in range(legs.size()):
		legs[i].rotation.x = stride * (1 if i in [0, 3] else -1)
	body.position.y = absf(sin(time * 9)) * minf(speed / 8, 1) * 0.05
	head.rotation.x = 0.25 if state in ["warn", "charge"] else sin(time * 1.8) * 0.035
	if state == "warn": legs[2].rotation.x = sin(time * 16) * 0.28
	body.rotation.z = sin(time * 40) * hit_flash * 0.2
