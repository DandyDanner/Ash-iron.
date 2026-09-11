extends Node3D
## Shared movement/tool rig with authored travelers and the original customizable scout.
const Detail = preload("res://scripts/character_mesh.gd")
const Profile = preload("res://scripts/character_profile.gd")
var body: Node3D
var elapsed := 0.0
var authored: RefCounted
var skin_color := Color.WHITE
var arm_rest: Array[Quaternion] = []
var forearm_rest: Array[Quaternion] = []

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
var tool_grip: Node3D
var open_right_fingers: Node3D
var closed_right_fingers: Node3D
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
	authored = null
	arm_rest.clear()
	forearm_rest.clear()
	skin_color = Profile.skin_color(profile)
	arms.clear()
	forearms.clear()
	legs.clear()
	knees.clear()
	if profile.get("traveler", 0) < 4:
		authored = preload("res://scripts/authored_traveler.gd").new()
		authored.build(self, int(profile.get("traveler", 0)))
		return
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
		Detail.loft(leg, [Vector4(-0.43, 0.093, 0.10, 0), Vector4(-0.24, 0.115, 0.115, 0.006), Vector4(0, 0.11, 0.12, 0)], trousers, 32, 0.06)
		var knee := joint(leg, "Knee", Vector3(0, -0.43, 0))
		knees.append(knee)
		Detail.loft(knee, [Vector4(-0.30, 0.077, 0.08, 0), Vector4(-0.22, 0.097, 0.10, 0.004), Vector4(0, 0.095, 0.10, 0)], trousers.lightened(0.035), 32, 0.075)
		cylinder(knee, Vector3(0, -0.31, 0), 0.082, 0.052, trousers.darkened(0.08))
		cylinder(knee, Vector3(0, -0.37, 0), 0.054, 0.085, skin)
		# Shaped boots, folded cuffs, soles, and a few readable laces.
		Detail.loft(knee, [Vector4(-0.55, 0.085, 0.15, 0.035), Vector4(-0.49, 0.09, 0.16, 0.034), Vector4(-0.43, 0.063, 0.076, 0), Vector4(-0.37, 0.073, 0.073, -0.005)], leather, 10)
		Detail.oval(knee, Vector3(0, -0.535, 0.04), Vector3(0.185, 0.047, 0.32), leather.darkened(0.38))
		Detail.loft(knee, [Vector4(-0.40, 0.073, 0.08, 0), Vector4(-0.35, 0.091, 0.09, 0)], leather.darkened(0.16), 8)
		for n in range(3):
			segment(knee, Vector3(-0.048, -0.46 + n * 0.027, 0.086), Vector3(0.048, -0.445 + n * 0.027, 0.086), 0.005, Color("c9ac76"))
		# Cargo-pocket flap stays a large, simple accent.
		box(leg, Vector3(side * 0.095, -0.19, 0.05), Vector3(0.035, 0.15, 0.14), trousers.darkened(0.08))
	torso = joint(body, "Torso", Vector3(0, 1.02, 0))
	Detail.loft(torso, [Vector4(-0.07, 0.22, 0.135, 0), Vector4(0.11, 0.20, 0.14, 0), Vector4(0.34, 0.26, 0.155, 0), Vector4(0.48, 0.24, 0.13, 0)], cream, 32, 0.045)
	# Shirt placket and open collar.
	box(torso, Vector3(0, 0.27, 0.154), Vector3(0.032, 0.38, 0.013), cream.darkened(0.07))
	for n in range(4):
		Detail.oval(torso, Vector3(0, 0.15 + n * 0.063, 0.167), Vector3(0.012, 0.012, 0.008), leather)
	for side in [-1.0, 1.0]:
		var collar := box(torso, Vector3(side * 0.078, 0.455, 0.131), Vector3(0.088, 0.14, 0.025), cream.lightened(0.10))
		collar.rotation.z = side * -0.34
		var arm := joint(body, "LeftArm" if side < 0 else "RightArm", Vector3(side * 0.285, 1.46, 0))
		arm.rotation.z = side * 0.10
		arms.append(arm)
		Detail.loft(arm, [Vector4(-0.28, 0.077, 0.084, 0), Vector4(-0.13, 0.095, 0.09, 0), Vector4(0.025, 0.076, 0.08, 0)], cream, 28, 0.06)
		var elbow := joint(arm, "Elbow", Vector3(0, -0.28, 0))
		forearms.append(elbow)
		cylinder(elbow, Vector3(0, -0.01, 0), 0.084, 0.063, cream.darkened(0.10))
		Detail.loft(elbow, [Vector4(-0.23, 0.043, 0.042, 0), Vector4(-0.10, 0.059, 0.052, 0), Vector4(0, 0.061, 0.057, 0)], skin)
		for n in range(3):
			cylinder(elbow, Vector3(0, -0.195 + n * 0.015, 0), 0.047, 0.01, leather.darkened(0.18))
		var hand := joint(elbow, "Hand", Vector3(0, -0.26, 0))
		Detail.oval(hand, Vector3.ZERO, Vector3(0.095, 0.12, 0.055), skin)
		var fingers := joint(hand, "OpenFingers", Vector3.ZERO)
		for n in range(4):
			Detail.oval(fingers, Vector3(-0.032 + n * 0.021, -0.06, 0.01), Vector3(0.022, 0.065, 0.027), skin)
		Detail.oval(fingers, Vector3(-side * 0.05, -0.012, 0.014), Vector3(0.036, 0.062, 0.034), skin)
		if side < 0:
			left_hand = hand
		else:
			right_hand = hand
			open_right_fingers = fingers
			# The tool's long axis crosses the palm instead of pointing into the elbow.
			tool_grip = joint(hand, "ToolGrip", Vector3(0, -0.02, 0.045))
			tool_grip.rotation.x = 1.35
			closed_right_fingers = gripping_fingers(tool_grip, skin)
			closed_right_fingers.hide()
	# Layered sash follows the waist, and a loose tail reads clearly from behind.
	for n in range(5):
		var wrap := Detail.oval(body, Vector3(0, 1.005 + n * 0.019, 0.008), Vector3(0.47, 0.039, 0.32), sash.lightened(n * 0.015))
		wrap.rotation.z = -0.05 + n * 0.012
	var tail := box(body, Vector3(-0.20, 0.83, 0.11), Vector3(0.105, 0.4, 0.025), sash)
	tail.rotation.z = -0.22
	segment(body, Vector3(-0.20, 1.00, 0.15), Vector3(0.20, 1.09, 0.15), 0.026, leather)
	for side in [-1.0, 1.0]:
		Detail.oval(body, Vector3(side * 0.24, 0.94, 0.06), Vector3(0.16, 0.20, 0.105), leather)
		box(body, Vector3(side * 0.24, 0.985, 0.12), Vector3(0.15, 0.07, 0.024), leather.lightened(0.1))
		Detail.oval(body, Vector3(side * 0.24, 0.97, 0.14), Vector3(0.022, 0.022, 0.01), Color("c8aa67"))
	segment(torso, Vector3(-0.21, 0.46, 0.15), Vector3(0.18, 0.02, 0.17), 0.025, leather)
	segment(torso, Vector3(-0.21, 0.46, -0.16), Vector3(0.18, 0.02, -0.17), 0.025, leather)
	cylinder(body, Vector3(0, 1.60, 0), 0.077, 0.19, skin)
	head = joint(body, "Head", Vector3(0, 1.86, 0))
	head.scale = [Vector3.ONE, Vector3(0.94, 1.06, 0.98), Vector3(1.08, 0.97, 1)][profile.face]
	Detail.loft(head, [Vector4(-0.174, 0.057, 0.066, 0.032), Vector4(-0.13, 0.115, 0.106, 0.020), Vector4(-0.02, 0.16, 0.127, 0), Vector4(0.10, 0.158, 0.127, -0.004), Vector4(0.19, 0.11, 0.095, -0.02), Vector4(0.21, 0.025, 0.025, -0.02)], skin, 20)
	for side in [-1.0, 1.0]:
		Detail.oval(head, Vector3(side * 0.157, -0.005, -0.002), Vector3(0.056, 0.086, 0.042), skin)
		Detail.oval(head, Vector3(side * 0.169, -0.004, 0.017), Vector3(0.024, 0.053, 0.016), skin.darkened(0.14))
		Detail.oval(head, Vector3(side * 0.070, 0.010, 0.116), Vector3(0.065, 0.043, 0.024), Color("eee6d5"))
		Detail.oval(head, Vector3(side * 0.068, 0.008, 0.130), Vector3(0.031, 0.036, 0.012), Color("69452a"))
		Detail.oval(head, Vector3(side * 0.068, 0.009, 0.136), Vector3(0.016, 0.025, 0.005), Color("24241d"))
		Detail.oval(head, Vector3(side * 0.068 - 0.006, 0.017, 0.139), Vector3(0.007, 0.008, 0.004), Color("fff4da"))
		Detail.strand(head, [Vector3(side * 0.037, 0.011, 0.123), Vector3(side * 0.070, 0.034, 0.128), Vector3(side * 0.103, 0.014, 0.111)], [0.002, 0.005, 0.001], hair.darkened(0.2), 0.7)
		Detail.strand(head, [Vector3(side * 0.038, 0.003, 0.123), Vector3(side * 0.070, -0.013, 0.126), Vector3(side * 0.102, 0.008, 0.11)], [0.001, 0.004, 0.001], skin.darkened(0.10), 0.65)
		Detail.strand(head, [Vector3(side * 0.038, 0.055, 0.118), Vector3(side * 0.067, 0.066, 0.122), Vector3(side * 0.105, 0.052, 0.104)], [0.007, 0.008, 0.002], hair, 0.45)
	Detail.loft(head, [Vector4(-0.058, 0.021, 0.021, 0.142), Vector4(-0.032, 0.020, 0.025, 0.141), Vector4(0.011, 0.013, 0.012, 0.127), Vector4(0.054, 0.009, 0.004, 0.122)], skin, 24)
	Detail.oval(head, Vector3(0, -0.045, 0.158), Vector3(0.032, 0.023, 0.025), skin.lightened(0.03))
	for side in [-1.0, 1.0]:
		Detail.oval(head, Vector3(side * 0.014, -0.055, 0.152), Vector3(0.009, 0.005, 0.005), skin.darkened(0.20))
	Detail.strand(head, [Vector3(-0.028, -0.095, 0.132), Vector3(0, -0.100, 0.142), Vector3(0.029, -0.093, 0.132)], [0.001, 0.0025, 0.001], skin.darkened(0.35), 0.5)
	Detail.strand(head, [Vector3(-0.022, -0.102, 0.133), Vector3(0, -0.106, 0.140), Vector3(0.022, -0.101, 0.133)], [0.001, 0.004, 0.001], skin.lerp(Color("b27662"), 0.18), 0.5)
	_hair(profile.hair, hair, cloth)
	_build_cape(cloth)
	# Small background and keepsake details preserve customization without replacing the scout outfit.
	var token_color: Color = [Color("bba372"), Color("9b684a"), Color("658a83"), Color("8894a0")][profile.background]
	Detail.oval(torso, Vector3(-0.11, 0.40, 0.17), Vector3(0.032, 0.041, 0.013), token_color)
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
		Detail.oval(token, Vector3.ZERO, Vector3(0.043, 0.059, 0.022), leather.lightened(0.22))

func _hair(style: int, color: Color, cloth: Color) -> void:
	if style == 5: return
	Detail.oval(head, Vector3(0, 0.105, -0.046), Vector3(0.326, 0.259, 0.274), color)
	# Swept locks follow the skull and taper to points, instead of spherical bangs.
	for i in range(9 if style != 1 else 5):
		var x := -0.142 + i * (0.035 if style != 1 else 0.069)
		var y := 0.159 + sin(i * 0.38) * 0.05
		var tip_y := 0.022 + i * 0.006 if style != 1 else 0.10
		Detail.strand(head, [Vector3(x + 0.075, y + 0.018, -0.035), Vector3(x + 0.043, y + sin(i) * 0.015, 0.090), Vector3(x - 0.027, tip_y + 0.040 + sin(i * 1.8) * 0.02, 0.130), Vector3(x - 0.040, tip_y + sin(i * 1.8) * 0.024, 0.110)], [0.013, 0.047, 0.026, 0.001], color.lightened((i % 3) * 0.025), 0.25)
	for side in [-1.0, 1.0]:
		for i in range(4):
			Detail.strand(head, [Vector3(side * 0.10, 0.18 - i * 0.023, -0.02 - i * 0.021), Vector3(side * 0.171, 0.06 - i * 0.015, -0.01 - i * 0.027), Vector3(side * (0.17 + i * 0.011), -0.03 - i * 0.02, 0.026 - i * 0.032)], [0.016, 0.033, 0.001], color.lightened((i % 2) * 0.035), 0.45)
	if style in [0, 3]:
		var root := Vector3(0, 0.13 if style == 0 else 0.25, -0.17)
		for i in range(6):
			Detail.strand(head, [root, root + Vector3((i - 2.5) * 0.025, 0.055, -0.075), root + Vector3((i - 2.5) * 0.033, -0.055 + (i % 2) * 0.03, -0.13)], [0.021, 0.034, 0.001], color.lightened((i % 3) * 0.025), 0.6)
		var tie := Detail.oval(head, root, Vector3(0.096, 0.049, 0.056), cloth.darkened(0.1))
		tie.rotation.x = -0.4
	if style in [2, 4]:
		for i in range(9):
			var x := (i - 4) * 0.036
			Detail.strand(head, [Vector3(x, 0.05, -0.12), Vector3(x * 1.15, -0.15, -0.15), Vector3(x * 1.05, -0.31, -0.10)], [0.033, 0.037, 0.002], color.lightened((i % 3) * 0.025), 0.5)
		if style == 4:
			for side in [-1.0, 1.0]:
				for i in range(6):
					Detail.oval(head, Vector3(side * (0.15 + sin(i * PI) * 0.01), -0.07 - i * 0.036, 0.0), Vector3(0.054, 0.056, 0.052), color.lightened((i % 2) * 0.03))

func _cape_point(t: float, a: float) -> Vector3:
	var spread := smoothstep(0, 0.42, t)
	var width := lerpf(0.106, 0.37, spread) + 0.055 * t * t
	var depth := lerpf(0.105, 0.17, spread) + 0.066 * t * t
	var fold := sin(a * 8 + t * 0.7) * 0.017 * t + sin(a * 13 - t) * 0.005 * t
	return Vector3(sin(a) * (width + fold), 0.12 - 0.35 * t + sin(a * 3) * 0.014 * t * t, cos(a) * (depth + fold))

func _build_cape(color: Color) -> void:
	cape = joint(body, "Cape", Vector3(0, 1.53, 0))
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row in range(10):
		for col in range(64):
			for pair in [Vector2i(row, col), Vector2i(row + 1, col + 1), Vector2i(row + 1, col), Vector2i(row, col), Vector2i(row, col + 1), Vector2i(row + 1, col + 1)]:
				var t: float = pair.x / 10.0
				var a: float = 0.30 + pair.y / 64.0 * (TAU - 0.60)
				surface.set_color(Color.WHITE.darkened(maxf(0, sin(a * 8 + t * 0.7)) * 0.10 * t))
				surface.add_vertex(_cape_point(t, a))
	surface.index()
	surface.generate_normals()
	var mesh := Detail.mesh_node(cape, surface.commit(), color)
	mesh.material_override.cull_mode = BaseMaterial3D.CULL_DISABLED
	# Hem piping and spaced embroidered chevrons follow the cloth in three dimensions.
	for i in range(32):
		var a := 0.30 + i / 32.0 * (TAU - 0.60)
		var b := 0.30 + (i + 1) / 32.0 * (TAU - 0.60)
		segment(cape, _cape_point(0.96, a), _cape_point(0.96, b), 0.004, color.darkened(0.22))
	for i in range(13):
		var a := 0.42 + i / 12.0 * (TAU - 0.84)
		var points := [_cape_point(0.88, a - 0.065), _cape_point(0.74, a), _cape_point(0.88, a + 0.065)]
		for n in range(2):
			for k in range(2):
				points[k + n] += Vector3(points[k + n].x, 0, points[k + n].z).normalized() * 0.001
			segment(cape, points[n], points[n + 1], 0.006, Color("d4cba3"))
	# A hanging, folded hood gives the third-person back its characteristic shape.
	var hood := Detail.loft(cape, [Vector4(-0.19, 0.016, 0.01, -0.241), Vector4(-0.11, 0.095, 0.025, -0.232), Vector4(0.01, 0.133, 0.05, -0.175), Vector4(0.13, 0.115, 0.062, -0.065)], color.darkened(0.09), 32, 0.08)
	hood.name = "FoldedHood"
	Detail.strand(cape, [Vector3(0, 0.11, -0.131), Vector3(0, 0, -0.224), Vector3(0, -0.18, -0.25)], [0.003, 0.003, 0.001], color.darkened(0.26), 0.8)
	segment(cape, Vector3(-0.07, 0.08, 0.10), Vector3(0.07, 0.08, 0.10), 0.008, Color("a7824e"))
	for side in [-1.0, 1.0]:
		var clasp := Detail.oval(cape, Vector3(side * 0.07, 0.08, 0.115), Vector3(0.031, 0.032, 0.012), Color("d7b870"))
		clasp.material_override.roughness = 0.42

static func gripping_fingers(parent: Node3D, skin: Color) -> Node3D:
	var fingers := joint(parent, "ClosedFingers", Vector3.ZERO)
	for finger in range(4):
		var y := -0.034 + finger * 0.023
		for bend in range(5):
			var a := 0.45 + bend * 0.82
			var b := a + 0.82
			segment(fingers, Vector3(cos(a) * 0.027, y, sin(a) * 0.027), Vector3(cos(b) * 0.027, y, sin(b) * 0.027), 0.011, skin)
	oval(fingers, Vector3(0.028, 0.047, 0), Vector3(0.035, 0.059, 0.032), skin)
	return fingers

func set_tool_grip(gripping: bool) -> void:
	open_right_fingers.visible = not gripping
	closed_right_fingers.visible = gripping

func reach_hand(index: int, target: Vector3, bend_hint: Vector3) -> void:
	# Two rigid arm segments reach the bow grip/string without stretching the model.
	var shoulder: Vector3 = arms[index].global_position
	var scale_factor := global_basis.get_scale().x
	var upper_length: float = forearms[index].position.length() * scale_factor
	var lower_length: float = (left_hand if index == 0 else right_hand).position.length() * scale_factor
	var offset := target - shoulder
	var distance := clampf(offset.length(), 0.03, upper_length + lower_length - 0.001)
	var direction := offset.normalized()
	var hint := global_basis.orthonormalized() * bend_hint
	var bend := (hint - direction * hint.dot(direction)).normalized()
	var along := (upper_length * upper_length - lower_length * lower_length + distance * distance) / (2 * distance)
	var elbow := shoulder + direction * along + bend * sqrt(maxf(0, upper_length * upper_length - along * along))
	arms[index].global_basis = Basis(Quaternion(Vector3.DOWN, (elbow - shoulder).normalized())) * Basis.from_scale(Vector3.ONE * scale_factor)
	forearms[index].global_basis = Basis(Quaternion(Vector3.DOWN, (shoulder + direction * distance - elbow).normalized())) * Basis.from_scale(Vector3.ONE * scale_factor)

func animate_movement(delta: float, speed: float, grounded: bool, vertical_speed: float, item: String, swing: float, draw: float) -> void:
	gameplay = true
	right_hand.rotation = Vector3.ZERO
	elapsed += delta
	motion = lerpf(motion, minf(speed / 5.0, 1.35), minf(1, delta * 12))
	gait += delta * (8.0 + speed * 0.55) if speed > 0.1 and grounded else delta * 2
	var stride := sin(gait) * motion * 0.62 if grounded else 0.0
	for i in range(2):
		var side := -1.0 if i == 0 else 1.0
		legs[i].rotation.x = stride * side if grounded else (-0.25 if i == 0 else 0.35)
		knees[i].rotation.x = maxf(0, -stride * side) * 0.85 if grounded else 0.48
		arms[i].rotation = Vector3(-stride * side * 0.65, 0, side * 0.10)
		forearms[i].rotation = Vector3(-0.10, 0, 0)
		if authored != null:
			arms[i].quaternion = arm_rest[i] * Quaternion.from_euler(Vector3(-stride * side * .65, 0, side * .04))
			forearms[i].quaternion = forearm_rest[i] * Quaternion(Vector3.RIGHT, -.10)
	if item in ["stone_axe", "stone_pickaxe", "torch"]:
		arms[1].rotation.x = -0.40
		forearms[1].rotation.x = -0.45
		if swing >= 0:
			# Wind up, chop forward at contact (0.22 s), follow through, recover.
			if swing < 0.08:
				arms[1].rotation.x = lerpf(-0.40, -2.1, smoothstep(0, 0.08, swing))
			elif swing < 0.22:
				arms[1].rotation.x = lerpf(-2.1, -0.65, smoothstep(0.08, 0.22, swing))
			elif swing < 0.32:
				arms[1].rotation.x = lerpf(-0.65, -0.25, smoothstep(0.22, 0.32, swing))
			else:
				arms[1].rotation.x = lerpf(-0.25, -0.40, smoothstep(0.32, 0.6, swing))
	if item == "bow":
		arms[0].rotation.x = -1.35
		forearms[0].rotation.x = -0.12
		arms[1].rotation.x = -1.22 * draw - 0.15
		arms[1].rotation.z = -0.25 * draw + 0.10
		forearms[1].rotation.x = -1.3 * draw
	else:
		arms[1].rotation.z = 0.0 if item in ["stone_axe", "stone_pickaxe"] else (0.20 if item == "torch" else 0.10)
	if item in ["stone_axe", "stone_pickaxe"]:
		arms[1].rotation.y = 0.0
		forearms[1].rotation.y = 0.0
		forearms[1].rotation.z = 0.0
	body.position.y = absf(sin(gait)) * 0.025 * motion if grounded else 0.02
	torso.rotation.x = motion * 0.035
	cape.rotation.x = sin(elapsed * 2.1) * 0.025 + motion * 0.08 + clampf(-vertical_speed * 0.025, -0.12, 0.16)

func sync_authored_pose() -> void:
	if authored != null: authored.sync()

func _process(delta: float) -> void:
	if gameplay or not is_instance_valid(body): return
	elapsed += delta
	body.position.y = sin(elapsed * 1.8) * 0.005
	cape.rotation.x = sin(elapsed * 1.5) * 0.018
	sync_authored_pose()
