extends Node3D
## Original shaped-mesh interpretation of the approved russet Bristleback concept.
const Detail = preload("res://scripts/character_mesh.gd")
const Model = preload("res://scripts/traveler_model.gd")
var body: Node3D
var head: Node3D
var legs: Array[Node3D] = []
var time := 0.0
const BODY_RINGS := [Vector4(-0.72, 0.20, 0.24, -0.60), Vector4(-0.48, 0.35, 0.35, -0.65), Vector4(-0.05, 0.43, 0.43, -0.72), Vector4(0.32, 0.39, 0.40, -0.73), Vector4(0.57, 0.25, 0.28, -0.65)]

func _fur_surface(z: float, angle: float, side: float) -> Vector3:
	var index := 0
	while index < BODY_RINGS.size() - 2 and z > BODY_RINGS[index + 1].x: index += 1
	var t := clampf((z - BODY_RINGS[index].x) / (BODY_RINGS[index + 1].x - BODY_RINGS[index].x), 0, 1)
	var ring := Detail.interpolate(BODY_RINGS[maxi(0, index - 1)], BODY_RINGS[index], BODY_RINGS[index + 1], BODY_RINGS[mini(BODY_RINGS.size() - 1, index + 2)], t)
	return Vector3(side * sin(angle) * ring.y, -ring.w + cos(angle) * ring.z, ring.x)


func _ready() -> void:
	body = Model.joint(self, "Body", Vector3.ZERO)
	var torso := Detail.loft(body, BODY_RINGS, Color("885334"), 36)
	torso.rotation.x = PI / 2
	for side in [-1.0, 1.0]:
		for z in [-0.45, 0.38]:
			var leg := Model.joint(body, "Leg", Vector3(side * 0.28, 0.45, z))
			legs.append(leg)
			Detail.loft(leg, [Vector4(-0.35, 0.078, 0.082, 0), Vector4(-0.18, 0.092, 0.09, 0.035), Vector4(0.08, 0.12, 0.12, 0)], Color("5c4030"), 20)
			for hoof_side in [-1.0, 1.0]:
				var hoof := Detail.loft(leg, [Vector4(-0.45,0.031,0.068,0.02),Vector4(-0.42,0.039,0.08,0.03),Vector4(-0.36,0.033,0.069,0.015),Vector4(-0.32,0.025,0.05,0)], Color("33352d"), 16)
				hoof.position.x = hoof_side * 0.037
		# Overlapping curved fur clumps lie against the flank, with backward tips.
		for row in range(6):
			for i in range(14):
				var z := -0.51 + i * 0.072 + (row % 2) * 0.025
				var angle := 0.55 + row * 0.25
				var normal := Vector3(side * sin(angle), cos(angle), 0)
				var root := _fur_surface(z, angle, side) - normal * 0.012
				var middle := _fur_surface(z - 0.055, angle + 0.09, side) + normal * 0.008
				var tip := _fur_surface(z - 0.12, angle + 0.15, side) + normal * 0.008
				var fur_color := Color("a7683c").darkened(row * 0.035 + (i % 3) * 0.025)
				Detail.strand(body, [root, middle, tip], [0.009, 0.013, 0.0007], fur_color, 0.12, normal)

	head = Model.joint(body, "Head", Vector3(0, 0.69, 0.47))
	var skull := Detail.loft(head, [Vector4(0, 0.29, 0.31, -0.03), Vector4(0.23, 0.25, 0.25, 0.005), Vector4(0.48, 0.17, 0.15, 0.08), Vector4(0.68, 0.15, 0.11, 0.10)], Color("91603b"), 32)
	skull.rotation.x = PI / 2
	var nose := Detail.oval(head, Vector3(0, -0.10, 0.706), Vector3(0.33, 0.195, 0.062), Color("513b30"))
	nose.material_override.roughness = 0.58
	Detail.oval(head, Vector3(0, -0.108, 0.738), Vector3(0.28, 0.15, 0.016), Color("634538"))
	# Short muzzle ridges keep the snout readable in a three-quarter view.
	for i in range(4):
		var z := 0.39 + i * 0.071
		Detail.strand(head, [Vector3(-0.115, -0.038, z), Vector3(0, 0.015 - i * 0.02, z + 0.017), Vector3(0.115, -0.038, z)], [0.001, 0.006, 0.001], Color("63442e"), 0.4)
	for side in [-1.0, 1.0]:
		Detail.oval(head, Vector3(side * 0.070, -0.098, 0.750), Vector3(0.054, 0.033, 0.014), Color("211f1a"))
		Detail.oval(head, Vector3(side * 0.224, 0.11, 0.23), Vector3(0.063, 0.052, 0.060), Color("392b1e"))
		Detail.oval(head, Vector3(side * 0.241, 0.112, 0.247), Vector3(0.024, 0.028, 0.024), Color("c49745"))
		Detail.oval(head, Vector3(side * 0.245, 0.114, 0.259), Vector3(0.010, 0.019, 0.012), Color("1e211b"))
		Detail.strand(head, [Vector3(side * 0.184, 0.19, 0.04), Vector3(side * 0.255, 0.17, 0.19), Vector3(side * 0.247, 0.105, 0.29)], [0.018, 0.030, 0.001], Color("69452e"), 0.48)
		var ear_points := [Vector3(side * 0.19, 0.20, 0.015), Vector3(side * 0.28, 0.36, -0.025), Vector3(side * 0.34, 0.47, 0.015)]
		Detail.strand(head, ear_points, [0.044, 0.088, 0.001], Color("65432d"), 0.30)
		Detail.strand(head, [ear_points[0] + Vector3(0, 0.045, 0.023), ear_points[1] + Vector3(0, -0.01, 0.031), ear_points[2] - Vector3(side * 0.02, 0.04, 0)], [0.010, 0.045, 0.001], Color("996a4f"), 0.12)
		for i in range(5):
			var root := Vector3(side * (0.24 - i * 0.012), 0.04 - i * 0.026, 0.10 + i * 0.055)
			Detail.strand(head, [root, root + Vector3(side * 0.025, -0.04, -0.02), root + Vector3(side * 0.02, -0.09, -0.08)], [0.021, 0.035, 0.001], Color("aa7747").darkened(i * 0.02), 0.21, Vector3.RIGHT)
		Detail.strand(head, [Vector3(side * 0.146, -0.19, 0.60), Vector3(side * 0.180, -0.21, 0.42), Vector3(side * 0.209, -0.13, 0.24)], [0.002, 0.004, 0.001], Color("483224"), 0.6)
		var tusk_points := [Vector3(side * 0.15, -0.17, 0.50), Vector3(side * 0.24, -0.11, 0.56), Vector3(side * 0.26, 0.015, 0.59), Vector3(side * 0.22, 0.13, 0.61)]
		var tusk := Detail.strand(head, tusk_points, [0.043, 0.033, 0.020, 0.0005], Color("e0cea5"), 1.0)
		tusk.material_override.roughness = 0.50
	# A layered swept mane, tallest over the shoulders, rather than upright spikes.
	for row in range(5):
		for i in range(15):
			var z := -0.57 + i * 0.075
			var y := _fur_surface(z, 0, 1).y - 0.018 - absf(row - 2) * 0.010
			var root := Vector3((row - 2) * 0.035, y, z)
			var height := 0.045 + sin(i / 14.0 * PI) * 0.025
			Detail.strand(body, [root, root + Vector3((row - 1) * 0.012, height, -0.055), root + Vector3((row - 1) * 0.018, height + 0.01, -0.155)], [0.016, 0.014, 0.0006], Color("44372b").lightened((i % 3) * 0.022), 0.40)
	Detail.strand(body, [Vector3(0,0.68,-0.66),Vector3(0.04,0.61,-0.84),Vector3(0.1,0.51,-0.88),Vector3(0.13,0.53,-0.84)], [0.021,0.018,0.011,0.004], Color("5b3b2b"))
	for mesh in body.find_children("*", "MeshInstance3D", true, false):
		var material: StandardMaterial3D = mesh.material_override
		if material.albedo_color.r > 0.25 and material.albedo_color.b < 0.4:
			mesh.material_override = preload("res://scripts/surface_detail.gd").refine(material, "fur")

func pose(delta: float, speed: float, state: String, hit_flash: float) -> void:
	time += delta
	var stride := sin(time * (12 if state == "charge" else 6)) * minf(speed / 5, 1) * 0.5
	for i in range(legs.size()):
		legs[i].rotation.x = stride * (1 if i in [0, 3] else -1)
	body.position.y = absf(sin(time * 9)) * minf(speed / 8, 1) * 0.05
	head.rotation.x = 0.25 if state in ["warn", "charge"] else sin(time * 1.8) * 0.035
	if state == "warn": legs[2].rotation.x = sin(time * 16) * 0.28
	body.rotation.z = sin(time * 40) * hit_flash * 0.2
