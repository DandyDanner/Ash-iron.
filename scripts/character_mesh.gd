extends RefCounted
## Detailed surfaces used only by the traveler and wildlife, never world props.

static func material(color: Color, roughness: float = 0.86) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	mat.metallic_specular = 0.22
	mat.vertex_color_use_as_albedo = true
	return mat

static func mesh_node(parent: Node3D, mesh: Mesh, color: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = material(color)
	parent.add_child(node)
	return node

static func oval(parent: Node3D, pos: Vector3, dimensions: Vector3, color: Color) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = 32
	mesh.rings = 20
	var node := mesh_node(parent, mesh, color)
	node.position = pos
	node.scale = dimensions
	return node

static func interpolate(a: Vector4, b: Vector4, c: Vector4, d: Vector4, t: float) -> Vector4:
	return (2 * b + (c - a) * t + (2 * a - 5 * b + 4 * c - d) * t * t + (-a + 3 * b - 3 * c + d) * t * t * t) * 0.5

static func loft(parent: Node3D, rings: Array, color: Color, sides: int = 24, folds: float = 0.0) -> MeshInstance3D:
	var samples: Array[Vector4] = []
	for row in range(rings.size() - 1):
		for step in range(5):
			samples.append(interpolate(rings[maxi(0, row - 1)], rings[row], rings[row + 1], rings[mini(rings.size() - 1, row + 2)], step / 5.0))
	samples.append(rings[-1])
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row in range(samples.size() - 1):
		for col in range(sides):
			for index in [Vector2i(row, col), Vector2i(row + 1, col), Vector2i(row + 1, (col + 1) % sides), Vector2i(row, col), Vector2i(row + 1, (col + 1) % sides), Vector2i(row, (col + 1) % sides)]:
				var ring := samples[index.x]
				var a := float(index.y) / sides * TAU
				var crease := sin(a * 7 + ring.x * 5) * sin(a * 3 - ring.x * 8)
				var radius := 1 + crease * folds
				surface.set_color(Color.WHITE.darkened(maxf(0, -crease) * folds * 0.65))
				surface.add_vertex(Vector3(sin(a) * maxf(0.001, ring.y) * radius, ring.x, cos(a) * maxf(0.001, ring.z) * radius + ring.w))
	for end in [0, samples.size() - 1]:
		var ring := samples[end]
		for col in range(sides):
			var a := float(col) / sides * TAU
			var b := float((col + 1) % sides) / sides * TAU
			var points := [Vector3(0, ring.x, ring.w), Vector3(sin(a) * ring.y, ring.x, cos(a) * ring.z + ring.w), Vector3(sin(b) * ring.y, ring.x, cos(b) * ring.z + ring.w)]
			for index in ([0, 1, 2] if end == 0 else [0, 2, 1]):
				surface.set_color(Color.WHITE)
				surface.add_vertex(points[index])
	surface.index()
	surface.generate_normals()
	return mesh_node(parent, surface.commit(), color)

static func strand(parent: Node3D, points: Array, widths: Array, color: Color, depth: float = 0.45, reference: Vector3 = Vector3.FORWARD) -> MeshInstance3D:
	# Curved tapered volumes for swept hair locks, fur clumps, and tusks.
	var centers: Array[Vector3] = []
	var radii: Array[float] = []
	for row in range(points.size() - 1):
		for step in range(5):
			var t := step / 5.0
			var a: Vector3 = points[maxi(0, row - 1)]
			var b: Vector3 = points[row]
			var c: Vector3 = points[row + 1]
			var d: Vector3 = points[mini(points.size() - 1, row + 2)]
			centers.append(b.cubic_interpolate(c, a, d, t))
			radii.append(lerpf(widths[row], widths[row + 1], t))
	centers.append(points[-1])
	radii.append(maxf(0.0005, widths[-1]))
	var vertices: Array[Vector3] = []
	var previous_side := Vector3.ZERO
	for row in range(centers.size()):
		var tangent := (centers[mini(row + 1, centers.size() - 1)] - centers[maxi(row - 1, 0)]).normalized()
		var normal := reference
		if absf(tangent.dot(normal)) > 0.94: normal = Vector3.UP
		var side := tangent.cross(normal).normalized()
		if row > 0:
			side = (previous_side - tangent * previous_side.dot(tangent)).normalized()
		previous_side = side
		var facing := side.cross(tangent).normalized()
		for col in range(12):
			var a := float(col) / 12 * TAU
			vertices.append(centers[row] + (side * sin(a) + facing * cos(a) * depth) * radii[row])
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row in range(centers.size() - 1):
		for col in range(12):
			var a := row * 12 + col
			var b := (row + 1) * 12 + col
			var c := (row + 1) * 12 + (col + 1) % 12
			var d := row * 12 + (col + 1) % 12
			for index in [a, b, c, a, c, d]:
				surface.set_color(Color.WHITE.darkened((1 + cos(float(index % 12) / 12 * TAU)) * 0.035))
				surface.add_vertex(vertices[index])
	surface.index()
	surface.generate_normals()
	var node := mesh_node(parent, surface.commit(), color)
	node.material_override.cull_mode = BaseMaterial3D.CULL_DISABLED
	return node
