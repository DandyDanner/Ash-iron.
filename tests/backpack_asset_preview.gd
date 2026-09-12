extends SceneTree
## Inspect the source GLB through Godot; native mode also saves a renderer preview.
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var document := GLTFDocument.new()
	var state := GLTFState.new()
	var error := document.append_from_file("res://assets/equipment/leather_backpack.glb", state)
	if error != OK:
		push_error("Backpack GLB could not load: %s" % error)
		quit(1)
		return
	var model := document.generate_scene(state)
	root.add_child(model)
	var meshes := model.find_children("*", "MeshInstance3D", true, false)
	var triangles := 0
	for mesh in meshes:
		for surface in range(mesh.mesh.get_surface_count()):
			var arrays: Array = mesh.mesh.surface_get_arrays(surface)
			triangles += arrays[Mesh.ARRAY_INDEX].size() / 3
			var mat: StandardMaterial3D = mesh.get_active_material(surface)
			if mat.albedo_texture == null or mat.normal_texture == null:
				push_error("Backpack material lost embedded textures")
				quit(1)
				return
	if meshes.size() != 1 or triangles > 21000:
		push_error("Backpack geometry budget/mesh count is wrong")
		quit(1)
		return
	print("PASS: Backpack GLB loads, one mesh, %d triangles, embedded color/normal textures" % triangles)
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_title("Ash & Iron — backpack asset review")
		var environment := WorldEnvironment.new()
		environment.environment = Environment.new()
		environment.environment.background_mode = Environment.BG_COLOR
		environment.environment.background_color = Color(.15, .17, .18)
		environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		environment.environment.ambient_light_color = Color(.82, .84, .88)
		environment.environment.ambient_light_energy = .65
		root.add_child(environment)
		var light := DirectionalLight3D.new()
		light.rotation_degrees = Vector3(-45, -35, 0)
		light.light_energy = 1.6
		root.add_child(light)
		var camera := Camera3D.new()
		root.add_child(camera)
		camera.position = Vector3(.8, .68, 1.25)
		camera.look_at(Vector3(0, .3, 0))
		camera.projection = Camera3D.PROJECTION_ORTHOGONAL
		camera.size = .85
		camera.make_current()
		for i in range(5): await process_frame
		RenderingServer.force_draw(false)
		var path := OS.get_environment("TMPDIR").path_join("ash-backpack-godot.png")
		root.get_texture().get_image().save_png(path)
		print("CAPTURE: " + path)
	quit()
