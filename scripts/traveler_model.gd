extends Node3D
## Willow Scout: original shaped meshes and an articulated procedural animation rig.
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
	material.roughness = 0.96
	material.diffuse_mode = BaseMaterial3D.DIFFUSE_BURLEY
	material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
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

var torso: Node3D
var head: Node3D
var cape: Node3D
var left_hand: Node3D
var right_hand: Node3D
var arms: Array[Node3D] = []
var forearms: Array[Node3D] = []
var legs: Array[Node3D] = []
var knees: Array[Node3D] = []
var gait := 0.0
var gameplay := false
var motion := 0.0

static func loft(parent: Node3D, rings: Array, color: Color, sides: int = 12) -> MeshInstance3D:
	# Rings: Vector4(y, half-width, half-depth, z-offset). Smooth, shaped silhouettes.
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row in range(rings.size() - 1):
		for col in range(sides):
			var points := []
			for pair in [Vector2i(row, col), Vector2i(row + 1, col), Vector2i(row + 1, col + 1), Vector2i(row, col + 1)]:
				var ring: Vector4 = rings[pair.x]
				var a := float(pair.y) / sides * TAU
				points.append(Vector3(sin(a) * ring.y, ring.x, cos(a) * ring.z + ring.w))
			for index in [0, 1, 2, 0, 2, 3]:
				surface.add_vertex(points[index])
	for end in [0, rings.size() - 1]:
		var ring: Vector4 = rings[end]
		for col in range(sides):
			var a := float(col) / sides * TAU
			var b := float(col + 1) / sides * TAU
			var points := [Vector3(0, ring.x, ring.w), Vector3(sin(a) * ring.y, ring.x, cos(a) * ring.z + ring.w), Vector3(sin(b) * ring.y, ring.x, cos(b) * ring.z + ring.w)]
			for index in ([0, 1, 2] if end == 0 else [0, 2, 1]):
				surface.add_vertex(points[index])
	surface.generate_normals()
	return part(parent, surface.commit(), Vector3.ZERO, color)

static func joint(parent: Node3D, title: String, pos: Vector3) -> Node3D:
	var node := Node3D.new()
	node.name = title
	node.position = pos
	parent.add_child(node)
	return node

static func segment(parent: Node3D, a: Vector3, b: Vector3, radius: float, color: Color, top: float = -1) -> MeshInstance3D:
	var result := cylinder(parent, (a + b) * 0.5, radius, a.distance_to(b), color, top)
	result.quaternion = Quaternion(Vector3.UP, (b - a).normalized())
	return result

func rebuild(profile: Dictionary) -> void:
	if is_instance_valid(body):
		remove_child(body)
		body.queue_free()
	arms.clear()
	forearms.clear()
	legs.clear()
	knees.clear()
	body = joint(self, "WillowScout", Vector3.ZERO)
	body.scale.x = [0.91, 1.0, 1.13][profile.build]
	var skin: Color = Profile.SKINS[profile.skin]
	var cloth: Color = Profile.CLOTHES[profile.clothes]
	var hair: Color = Profile.HAIR_COLORS[profile.hair_color]
	var cream := Color("e9ddbc")
	var trousers := Color("baa987")
	var leather := Color("79583c")
	var sash := Color("3c6665")
	for side in [-1.0, 1.0]:
		var leg := joint(body, "LeftLeg" if side < 0 else "RightLeg", Vector3(side * 0.13, 1.00, 0))
		legs.append(leg)
		loft(leg, [Vector4(-0.43, 0.093, 0.10, 0), Vector4(-0.24, 0.115, 0.115, 0.006), Vector4(0, 0.11, 0.12, 0)], trousers)
		var knee := joint(leg, "Knee", Vector3(0, -0.43, 0))
		knees.append(knee)
		loft(knee, [Vector4(-0.30, 0.077, 0.08, 0), Vector4(-0.22, 0.097, 0.10, 0.004), Vector4(0, 0.095, 0.10, 0)], trousers.lightened(0.035))
		cylinder(knee, Vector3(0, -0.31, 0), 0.082, 0.052, trousers.darkened(0.08))
		cylinder(knee, Vector3(0, -0.37, 0), 0.054, 0.085, skin)
		# Shaped boots, folded cuffs, soles, and a few readable laces.
		loft(knee, [Vector4(-0.55, 0.085, 0.15, 0.035), Vector4(-0.49, 0.09, 0.16, 0.034), Vector4(-0.43, 0.063, 0.076, 0), Vector4(-0.37, 0.073, 0.073, -0.005)], leather, 10)
		oval(knee, Vector3(0, -0.535, 0.04), Vector3(0.185, 0.047, 0.32), leather.darkened(0.38))
		loft(knee, [Vector4(-0.40, 0.073, 0.08, 0), Vector4(-0.35, 0.091, 0.09, 0)], leather.darkened(0.16), 8)
		for n in range(3):
			segment(knee, Vector3(-0.048, -0.46 + n * 0.027, 0.086), Vector3(0.048, -0.445 + n * 0.027, 0.086), 0.005, Color("c9ac76"))
		# Cargo-pocket flap stays a large, simple accent.
		box(leg, Vector3(side * 0.095, -0.19, 0.05), Vector3(0.035, 0.15, 0.14), trousers.darkened(0.08))
	torso = joint(body, "Torso", Vector3(0, 1.02, 0))
	loft(torso, [Vector4(-0.07, 0.22, 0.135, 0), Vector4(0.11, 0.20, 0.14, 0), Vector4(0.34, 0.26, 0.155, 0), Vector4(0.48, 0.24, 0.13, 0)], cream)
	# Shirt placket and open collar.
	box(torso, Vector3(0, 0.27, 0.154), Vector3(0.032, 0.38, 0.013), cream.darkened(0.07))
	for n in range(4):
		oval(torso, Vector3(0, 0.15 + n * 0.063, 0.167), Vector3(0.012, 0.012, 0.008), leather)
	for side in [-1.0, 1.0]:
		var collar := box(torso, Vector3(side * 0.078, 0.455, 0.131), Vector3(0.088, 0.14, 0.025), cream.lightened(0.10))
		collar.rotation.z = side * -0.34
		var arm := joint(body, "LeftArm" if side < 0 else "RightArm", Vector3(side * 0.285, 1.46, 0))
		arm.rotation.z = side * 0.10
		arms.append(arm)
		loft(arm, [Vector4(-0.28, 0.077, 0.084, 0), Vector4(-0.13, 0.095, 0.09, 0), Vector4(0.025, 0.076, 0.08, 0)], cream)
		var elbow := joint(arm, "Elbow", Vector3(0, -0.28, 0))
		forearms.append(elbow)
		cylinder(elbow, Vector3(0, -0.01, 0), 0.084, 0.063, cream.darkened(0.10))
		loft(elbow, [Vector4(-0.23, 0.043, 0.042, 0), Vector4(-0.10, 0.059, 0.052, 0), Vector4(0, 0.061, 0.057, 0)], skin)
		for n in range(3):
			cylinder(elbow, Vector3(0, -0.195 + n * 0.015, 0), 0.047, 0.01, leather.darkened(0.18))
		var hand := joint(elbow, "Hand", Vector3(0, -0.26, 0))
		oval(hand, Vector3.ZERO, Vector3(0.095, 0.12, 0.055), skin)
		for n in range(4):
			oval(hand, Vector3(-0.032 + n * 0.021, -0.06, 0.01), Vector3(0.022, 0.065, 0.027), skin)
		oval(hand, Vector3(-side * 0.05, -0.012, 0.014), Vector3(0.036, 0.062, 0.034), skin)
		if side < 0: left_hand = hand
		else: right_hand = hand
	# Layered sash follows the waist, and a loose tail reads clearly from behind.
	for n in range(5):
		var wrap := oval(body, Vector3(0, 1.005 + n * 0.019, 0.008), Vector3(0.47, 0.039, 0.32), sash.lightened(n * 0.015))
		wrap.rotation.z = -0.05 + n * 0.012
	var tail := box(body, Vector3(-0.20, 0.83, 0.11), Vector3(0.105, 0.4, 0.025), sash)
	tail.rotation.z = -0.22
	segment(body, Vector3(-0.20, 1.00, 0.15), Vector3(0.20, 1.09, 0.15), 0.026, leather)
	for side in [-1.0, 1.0]:
		oval(body, Vector3(side * 0.24, 0.94, 0.06), Vector3(0.16, 0.20, 0.105), leather)
		box(body, Vector3(side * 0.24, 0.985, 0.12), Vector3(0.15, 0.07, 0.024), leather.lightened(0.1))
		oval(body, Vector3(side * 0.24, 0.97, 0.14), Vector3(0.022, 0.022, 0.01), Color("c8aa67"))
	segment(torso, Vector3(-0.21, 0.46, 0.15), Vector3(0.18, 0.02, 0.17), 0.025, leather)
	segment(torso, Vector3(-0.21, 0.46, -0.16), Vector3(0.18, 0.02, -0.17), 0.025, leather)
	cylinder(body, Vector3(0, 1.60, 0), 0.077, 0.19, skin)
	head = joint(body, "Head", Vector3(0, 1.86, 0))
	head.scale = [Vector3.ONE, Vector3(0.94, 1.06, 0.98), Vector3(1.08, 0.97, 1)][profile.face]
	loft(head, [Vector4(-0.19, 0.064, 0.071, 0.032), Vector4(-0.13, 0.115, 0.106, 0.020), Vector4(-0.02, 0.16, 0.127, 0), Vector4(0.10, 0.158, 0.127, -0.004), Vector4(0.19, 0.11, 0.095, -0.02), Vector4(0.21, 0.025, 0.025, -0.02)], skin, 20)
	for side in [-1.0, 1.0]:
		oval(head, Vector3(side * 0.164, -0.002, 0), Vector3(0.059, 0.096, 0.047), skin)
		oval(head, Vector3(side * 0.167, -0.002, 0.022), Vector3(0.026, 0.058, 0.012), skin.darkened(0.17))
		oval(head, Vector3(side * 0.073, 0.016, 0.117), Vector3(0.071, 0.051, 0.027), Color("f4ecd7"))
		oval(head, Vector3(side * 0.072, 0.013, 0.134), Vector3(0.034, 0.043, 0.012), Color("614431"))
		oval(head, Vector3(side * 0.072, 0.013, 0.140), Vector3(0.016, 0.030, 0.006), Color("292d29"))
		oval(head, Vector3(side * 0.073 - 0.008, 0.023, 0.146), Vector3(0.010, 0.011, 0.005), Color("fff6db"))
		var brow := oval(head, Vector3(side * 0.073, 0.065, 0.124), Vector3(0.080, 0.014, 0.016), hair)
		brow.rotation.z = -side * 0.08
	oval(head, Vector3(0, -0.035, 0.131), Vector3(0.043, 0.060, 0.058), skin.lightened(0.04))
	oval(head, Vector3(0, -0.103, 0.115), Vector3(0.056, 0.009, 0.011), skin.darkened(0.32))
	_hair(profile.hair, hair, cloth)
	_build_cape(cloth)
	# Small background and keepsake details preserve customization without replacing the scout outfit.
	var token_color: Color = [Color("bba372"), Color("9b684a"), Color("658a83"), Color("8894a0")][profile.background]
	oval(torso, Vector3(-0.11, 0.40, 0.17), Vector3(0.032, 0.041, 0.013), token_color)
	var token := joint(body, "Keepsake", Vector3(0.24, 0.87, 0.135))
	if profile.keepsake == 1:
		var compass := cylinder(token, Vector3.ZERO, 0.032, 0.016, Color("c8aa67"))
		compass.rotation.x = PI / 2
	elif profile.keepsake == 2:
		box(token, Vector3.ZERO, Vector3(0.041, 0.17, 0.019), Color("aa614a"))
	elif profile.keepsake == 3:
		box(token, Vector3.ZERO, Vector3(0.08, 0.11, 0.025), leather.darkened(0.15))
		box(token, Vector3(0.004, 0, 0.017), Vector3(0.063, 0.095, 0.012), cream)
		box(token, Vector3(0, 0, 0.027), Vector3(0.08, 0.017, 0.014), leather)
	else:
		oval(token, Vector3.ZERO, Vector3(0.043, 0.059, 0.022), leather.lightened(0.22))

func _hair(style: int, color: Color, cloth: Color) -> void:
	if style == 5: return
	oval(head, Vector3(0, 0.115, -0.04), Vector3(0.34, 0.26, 0.29), color)
	for i in range(7 if style != 1 else 3):
		var x := -0.14 + i * (0.047 if style != 1 else 0.12)
		var tuft := oval(head, Vector3(x, 0.13 + sin(i * 1.7) * 0.025, 0.095), Vector3(0.10, 0.15 if style != 1 else 0.07, 0.095), color.lightened((i % 3) * 0.025))
		tuft.rotation.z = -0.47
	for side in [-1.0, 1.0]:
		var lock := oval(head, Vector3(side * 0.14, 0.04, -0.03), Vector3(0.07, 0.19, 0.14), color)
		lock.rotation.z = -side * 0.2
	if style in [0, 3]:
		oval(head, Vector3(0, 0.14 if style == 0 else 0.27, -0.17), Vector3(0.16, 0.13, 0.18), color)
		cylinder(head, Vector3(0, 0.17 if style == 0 else 0.24, -0.12), 0.043, 0.032, cloth)
	if style in [2, 4]:
		oval(head, Vector3(0, -0.10, -0.13), Vector3(0.31, 0.40, 0.15), color)
		for side in [-1.0, 1.0]:
			for i in range(5 if style == 4 else 1):
				oval(head, Vector3(side * 0.15, -0.09 - i * 0.044, 0.0), Vector3(0.060, 0.075 if style == 4 else 0.29, 0.067), color)

func _build_cape(color: Color) -> void:
	cape = joint(body, "Cape", Vector3(0, 1.53, 0))
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rows := [Vector3(0.105, 0.105, 0.12), Vector3(0.29, 0.17, 0.03), Vector3(0.385, 0.235, -0.22)]
	for row in range(2):
		for col in range(24):
			var vertices := []
			for pair in [Vector2i(row, col), Vector2i(row + 1, col), Vector2i(row + 1, col + 1), Vector2i(row, col + 1)]:
				var a := 0.30 + float(pair.y) / 24 * (TAU - 0.60)
				var ring: Vector3 = rows[pair.x]
				var fold := 1.0 + sin(a * 7) * 0.035
				vertices.append(Vector3(sin(a) * ring.x * fold, ring.z + (sin(a * 3) * 0.02 if pair.x == 2 else 0.0), cos(a) * ring.y * fold))
			for index in [0, 2, 1, 0, 3, 2]: surface.add_vertex(vertices[index])
			if row == 1:
				segment(cape, vertices[1] + Vector3(0, 0.015, 0), vertices[2] + Vector3(0, 0.015, 0), 0.007, Color("cccca5"))
	surface.generate_normals()
	var mesh := part(cape, surface.commit(), Vector3.ZERO, color)
	mesh.material_override.cull_mode = BaseMaterial3D.CULL_DISABLED
	oval(cape, Vector3(0, 0.055, -0.12), Vector3(0.28, 0.14, 0.22), color.darkened(0.06))
	segment(cape, Vector3(-0.07, 0.08, 0.10), Vector3(0.07, 0.08, 0.10), 0.008, Color("a7824e"))
	for side in [-1.0, 1.0]:
		oval(cape, Vector3(side * 0.07, 0.08, 0.11), Vector3(0.03, 0.03, 0.012), Color("d7b870"))

func animate_movement(delta: float, speed: float, grounded: bool, vertical_speed: float, item: String, swing: float, draw: float) -> void:
	gameplay = true
	elapsed += delta
	motion = lerpf(motion, minf(speed / 5.0, 1.35), minf(1, delta * 12))
	gait += delta * (8.0 + speed * 0.55) if speed > 0.1 and grounded else delta * 2
	var stride := sin(gait) * motion * 0.62 if grounded else 0.0
	for i in range(2):
		var side := -1.0 if i == 0 else 1.0
		legs[i].rotation.x = stride * side if grounded else (-0.25 if i == 0 else 0.35)
		knees[i].rotation.x = maxf(0, -stride * side) * 0.85 if grounded else 0.48
		arms[i].rotation.x = -stride * side * 0.65
		forearms[i].rotation.x = -0.10
	if item in ["stone_axe", "stone_pickaxe", "torch"]:
		arms[1].rotation.x = -0.40
		forearms[1].rotation.x = -0.45
		if swing >= 0:
			arms[1].rotation.x = -0.45 - sin(clampf(swing / 0.6, 0, 1) * PI) * 1.65
			forearms[1].rotation.x = -0.30
	if item == "bow":
		arms[0].rotation.x = -1.35
		forearms[0].rotation.x = -0.12
		arms[1].rotation.x = -1.22 * draw - 0.15
		arms[1].rotation.z = -0.25 * draw + 0.10
		forearms[1].rotation.x = -1.3 * draw
	else:
		arms[1].rotation.z = 0.10
	body.position.y = absf(sin(gait)) * 0.025 * motion if grounded else 0.02
	torso.rotation.x = motion * 0.035
	cape.rotation.x = sin(elapsed * 2.1) * 0.025 + motion * 0.08 + clampf(-vertical_speed * 0.025, -0.12, 0.16)

func _process(delta: float) -> void:
	if gameplay or not is_instance_valid(body): return
	elapsed += delta
	body.position.y = sin(elapsed * 1.8) * 0.005
	cape.rotation.x = sin(elapsed * 1.5) * 0.018
