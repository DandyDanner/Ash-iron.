extends Node3D
## Clearing scenery, harvestable grove pines, and outer terrain. The original camp stays flat.
const Model = preload("res://scripts/traveler_model.gd")
const Pine = preload("res://scripts/harvest_tree.gd")
var rng := RandomNumberGenerator.new()

static func terrain_height(x: float, z: float) -> float:
	var edge := smoothstep(20.0, 31.0, maxf(absf(x), absf(z)))
	return 0.18 + edge * (1.5 + sin(x * 0.08) * 1.2 + cos(z * 0.11) * 0.8)

func _ready() -> void:
	name = "VisualClearing"
	rng.seed = 9126
	_environment()
	_terrain()
	_grass()
	_forest()
	_flowers()

func _environment() -> void:
	var scene := get_parent()
	var env: Environment = scene.get_node("WorldEnvironment").environment.duplicate()
	scene.get_node("WorldEnvironment").environment = env
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("82acb9")
	sky_material.sky_horizon_color = Color("d9dfbf")
	sky_material.ground_horizon_color = Color("d9dfbf")
	sky_material.ground_bottom_color = Color("718366")
	sky_material.sky_curve = 0.22
	sky.sky_material = sky_material
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("c7d8cf")
	env.ambient_light_energy = 0.50
	env.fog_enabled = true
	env.fog_light_color = Color("bdcdb5")
	env.fog_density = 0.006
	env.fog_sky_affect = 0.15
	var sun: DirectionalLight3D = scene.get_node("Sun")
	sun.rotation_degrees = Vector3(-42, -30, 0)
	sun.light_color = Color("ffe5ae")
	sun.light_energy = 1.05
	sun.directional_shadow_max_distance = 65
	var ground: MeshInstance3D = scene.get_node("Ground/Mesh")
	var ground_material := ShaderMaterial.new()
	ground_material.shader = preload("res://assets/shaders/meadow.gdshader")
	ground.material_override = ground_material

func _terrain() -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for x in range(-72, 72, 3):
		for z in range(-72, 72, 3):
			for offset in [Vector2(0,0), Vector2(3,3), Vector2(0,3), Vector2(0,0), Vector2(3,0), Vector2(3,3)]:
				var px: float = x + offset.x
				var pz: float = z + offset.y
				surface.add_vertex(Vector3(px, terrain_height(px, pz), pz))
	surface.generate_normals()
	var ground := Model.part(self, surface.commit(), Vector3.ZERO, Color("738b4c"))
	var material := ShaderMaterial.new()
	material.shader = preload("res://assets/shaders/meadow.gdshader")
	ground.material_override = material
	ground.create_trimesh_collision()
	# Layered distant silhouettes are scenery beyond the playable meadow.
	for i in range(14):
		var a := i * TAU / 14
		var peak := Model.oval(self, Vector3(sin(a) * 87, 7, cos(a) * 87), Vector3(26, 16 + i % 4 * 5, 24), Color("78918b").lightened((i % 3) * 0.045))
		peak.rotation.z = sin(i) * 0.13

func _path_distance(p: Vector2, a: Vector2, b: Vector2) -> float:
	var d := b - a
	return p.distance_to(a + d * clampf((p - a).dot(d) / d.length_squared(), 0, 1))

func _grass() -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for a in [0.0, 2.1, 4.2]:
		var left := Vector3(cos(a) * 0.055, 0, sin(a) * 0.055)
		var right := -left
		var tip := Vector3(cos(a + 0.5) * 0.09, 0.38, sin(a + 0.5) * 0.09)
		for vertex in [left, right, tip]: surface.add_vertex(vertex)
	surface.generate_normals()
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = surface.commit()
	var points: Array[Vector3] = []
	for i in range(3100):
		var x := rng.randf_range(-39, 39)
		var z := rng.randf_range(-39, 39)
		var p := Vector2(x, z)
		if _path_distance(p, Vector2(0,10), Vector2(-3.5,0.3)) < 1.15 or _path_distance(p, Vector2(-3.5,0.3), Vector2(10,-9)) < 1.15:
			continue
		# Low tufts in the camp keep hand-gathered items readable.
		points.append(Vector3(x, maxf(0.205, terrain_height(x,z)), z))
	multimesh.instance_count = points.size()
	for i in range(points.size()):
		var size := rng.randf_range(0.65, 1.3)
		var basis := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * size)
		multimesh.set_instance_transform(i, Transform3D(basis, points[i]))
	var field := MultiMeshInstance3D.new()
	field.name = "MeadowGrass"
	field.multimesh = multimesh
	field.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material := ShaderMaterial.new()
	material.shader = preload("res://assets/shaders/meadow_grass.gdshader")
	field.material_override = material
	add_child(field)

func _forest() -> void:
	for i in range(32):
		var a := i * TAU / 32.0
		var distance := rng.randf_range(23, 40)
		var x := sin(a) * distance
		var z := cos(a) * distance
		var pine := Pine.new()
		pine.name = "GrovePine_%02d" % i
		pine.position = Vector3(x, terrain_height(x,z), z)
		pine.rotation.y = a
		add_child(pine)
	for i in range(18):
		var a := i * TAU / 18
		var x := sin(a) * rng.randf_range(18, 32)
		var z := cos(a) * rng.randf_range(18, 32)
		var rock := Model.oval(self, Vector3(x, terrain_height(x,z) + 0.18, z), Vector3(1.1, 0.55, 0.9), Color("89927b"))
		rock.rotation.y = a

func _flowers() -> void:
	for i in range(50):
		var a := rng.randf() * TAU
		var distance := rng.randf_range(12, 24)
		var x := sin(a) * distance
		var z := cos(a) * distance
		var y := maxf(0.21, terrain_height(x,z))
		var cluster := Node3D.new()
		cluster.position = Vector3(x,y,z)
		add_child(cluster)
		for flower in range(3):
			var pos := Vector3((flower - 1) * 0.13, 0.13 + flower * 0.025, flower * 0.06)
			Model.cylinder(cluster, pos * Vector3(1,0.5,1), 0.012, pos.y, Color("586e3e"))
			Model.oval(cluster, pos, Vector3(0.11, 0.04, 0.10), Color("e6dba7") if i % 3 else Color("be895e"))
			Model.oval(cluster, pos + Vector3(0,0.021,0), Vector3(0.032, 0.018, 0.032), Color("c49b46"))
