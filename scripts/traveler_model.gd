extends Node3D
## Original procedural blockout: replaceable with a rigged art asset later.
const Profile = preload("res://scripts/character_profile.gd")
var body: Node3D
var elapsed := 0.0

static func part(parent: Node3D, mesh: Mesh, pos: Vector3, color: Color, dimensions: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.position = pos
	node.scale = dimensions
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.92
	node.material_override = material
	parent.add_child(node)
	return node

static func oval(parent: Node3D, pos: Vector3, dimensions: Vector3, color: Color) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = 12
	mesh.rings = 6
	return part(parent, mesh, pos, color, dimensions)

static func box(parent: Node3D, pos: Vector3, dimensions: Vector3, color: Color) -> MeshInstance3D:
	return part(parent, BoxMesh.new(), pos, color, dimensions)

static func cylinder(parent: Node3D, pos: Vector3, radius: float, height: float, color: Color, top: float = -1.0) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius if top < 0.0 else top
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 12
	return part(parent, mesh, pos, color)

func rebuild(profile: Dictionary) -> void:
	if is_instance_valid(body):
		remove_child(body)
		body.queue_free()
	body = Node3D.new()
	add_child(body)
	var skin: Color = Profile.SKINS[profile.skin]
	var cloth: Color = Profile.CLOTHES[profile.clothes]
	var hair: Color = Profile.HAIR_COLORS[profile.hair_color]
	var leather := Color("654634")
	var boots := Color("3a332d")
	var width: float = [0.87, 1.0, 1.18][profile.build]
	body.scale.x = width
	for side in [-1.0, 1.0]:
		oval(body, Vector3(side * 0.18, 0.55, 0), Vector3(0.27, 0.83, 0.3), Color("454a40"))
		oval(body, Vector3(side * 0.18, 0.15, 0.075), Vector3(0.32, 0.29, 0.49), boots)
		cylinder(body, Vector3(side * 0.18, 0.32, 0), 0.15, 0.24, leather)
	oval(body, Vector3(0, 1.15, 0), Vector3(0.76, 0.82, 0.42), cloth)
	cylinder(body, Vector3(0, 0.89, 0), 0.32, 0.16, cloth.darkened(0.08), 0.28)
	oval(body, Vector3(0, 0.95, 0), Vector3(0.7, 0.1, 0.44), leather)
	box(body, Vector3(0, 0.95, 0.226), Vector3(0.12, 0.09, 0.035), Color("bd9b5a"))
	for side in [-1.0, 1.0]:
		var sleeve := oval(body, Vector3(side * 0.43, 1.19, 0), Vector3(0.26, 0.62, 0.3), cloth)
		sleeve.rotation.z = side * 0.16
		oval(body, Vector3(side * 0.49, 0.89, 0.015), Vector3(0.19, 0.24, 0.22), skin)
		oval(body, Vector3(side * 0.485, 0.99, 0), Vector3(0.235, 0.13, 0.265), leather)
	cylinder(body, Vector3(0, 1.57, 0), 0.12, 0.22, skin)
	var head := Node3D.new()
	head.position = Vector3(0, 1.88, 0)
	head.scale = [Vector3(1, 1, 1), Vector3(0.92, 1.08, 0.95), Vector3(1.12, 0.95, 1)][profile.face]
	body.add_child(head)
	oval(head, Vector3.ZERO, Vector3(0.59, 0.63, 0.5), skin)
	for side in [-1.0, 1.0]:
		oval(head, Vector3(side * 0.29, 0, 0), Vector3(0.13, 0.21, 0.12), skin)
		oval(head, Vector3(side * 0.115, 0.035, 0.222), Vector3(0.105, 0.12, 0.035), Color("f6edd7"))
		oval(head, Vector3(side * 0.115, 0.027, 0.242), Vector3(0.046, 0.073, 0.02), Color("2e3931"))
		var brow := box(head, Vector3(side * 0.12, 0.12, 0.234), Vector3(0.11, 0.022, 0.025), hair)
		brow.rotation.z = side * -0.1
	oval(head, Vector3(0, -0.05, 0.257), Vector3(0.085, 0.11, 0.12), skin.lightened(0.05))
	oval(head, Vector3(0, -0.16, 0.222), Vector3(0.095, 0.022, 0.025), skin.darkened(0.35))
	if profile.hair != 5:
		oval(head, Vector3(0, 0.22, -0.035), Vector3(0.62, 0.3, 0.51), hair)
		if profile.hair == 0:
			for i in range(5):
				var tuft := oval(head, Vector3(-0.24 + i * 0.1, 0.2 - (i % 2) * 0.035, 0.18), Vector3(0.2, 0.25, 0.22), hair)
				tuft.rotation.z = -0.35
		if profile.hair == 2 or profile.hair == 4:
			oval(head, Vector3(0, -0.02, -0.17), Vector3(0.6, 0.73, 0.24), hair)
			for side in [-1.0, 1.0]:
				oval(head, Vector3(side * 0.255, -0.15, 0.02), Vector3(0.15, 0.65, 0.19), hair)
				if profile.hair == 4:
					for i in range(4):
						oval(head, Vector3(side * 0.27, -0.25 - i * 0.1, 0.11), Vector3(0.12, 0.14, 0.12), hair)
		if profile.hair == 3:
			oval(head, Vector3(0, 0.4, -0.06), Vector3(0.27, 0.27, 0.26), hair)
			cylinder(head, Vector3(0, 0.3, -0.06), 0.115, 0.045, cloth)
	# A pack and diagonal strap anchor every traveler in the frontier setting.
	oval(body, Vector3(0, 1.25, -0.29), Vector3(0.6, 0.67, 0.3), leather)
	var strap := box(body, Vector3(0.05, 1.24, 0.23), Vector3(0.08, 0.64, 0.035), leather)
	strap.rotation.z = -0.48
	oval(body, Vector3(-0.36, 0.88, 0.08), Vector3(0.3, 0.32, 0.25), leather)
	match int(profile.background):
		0:
			oval(body, Vector3(0, 1.47, 0), Vector3(0.9, 0.23, 0.6), Color("c5ba93"))
			box(body, Vector3(0.25, 1.25, -0.45), Vector3(0.14, 0.66, 0.15), boots)
		1:
			box(body, Vector3(0, 1.03, 0.25), Vector3(0.45, 0.68, 0.04), leather)
			box(body, Vector3(0, 1.06, 0.28), Vector3(0.28, 0.18, 0.02), leather.lightened(0.08))
		2:
			oval(body, Vector3(0, 1.55, 0), Vector3(0.4, 0.19, 0.4), Color("c79550"))
			var scarf := box(body, Vector3(-0.13, 1.31, 0.29), Vector3(0.14, 0.42, 0.05), Color("c79550"))
			scarf.rotation.z = -0.12
		3:
			cylinder(head, Vector3(0, 0.27, 0), 0.47, 0.055, leather)
			cylinder(head, Vector3(0, 0.38, 0), 0.29, 0.2, leather, 0.25)
			cylinder(head, Vector3(0, 0.3, 0), 0.295, 0.055, cloth)
	if profile.keepsake == 2:
		oval(body, Vector3(0, 1.56, 0), Vector3(0.43, 0.17, 0.43), Color("a94e42"))
	elif profile.keepsake == 0:
		var wood := Color("bb8150")
		oval(body, Vector3(0.27, 0.85, 0.26), Vector3(0.09, 0.14, 0.05), wood)
		oval(body, Vector3(0.27, 0.93, 0.27), Vector3(0.11, 0.085, 0.06), wood)
		for side in [-1.0, 1.0]:
			cylinder(body, Vector3(0.27 + side * 0.032, 0.985, 0.27), 0.024, 0.055, wood, 0.0)
	elif profile.keepsake == 1:
		var compass := cylinder(body, Vector3(0.27, 0.86, 0.26), 0.07, 0.025, Color("d1b567"))
		compass.rotation.x = PI / 2.0
		box(body, Vector3(0.27, 0.86, 0.279), Vector3(0.015, 0.09, 0.01), Color("f1e8c9"))
	else:
		box(body, Vector3(0.27, 0.85, 0.25), Vector3(0.13, 0.17, 0.055), Color("654c3e"))
		box(body, Vector3(0.27, 0.85, 0.28), Vector3(0.018, 0.17, 0.012), Color("baaa86"))

func _process(delta: float) -> void:
	elapsed += delta
	if is_instance_valid(body):
		body.position.y = sin(elapsed * 1.8) * 0.008
