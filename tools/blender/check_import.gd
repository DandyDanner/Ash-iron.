extends SceneTree
## Validate the Blender-produced GLB without importing or replacing live assets.
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var document := GLTFDocument.new()
	var state := GLTFState.new()
	var result := document.append_from_file(ProjectSettings.globalize_path("res://art/blender/pipeline_check.glb"), state)
	if result != OK:
		push_error("Blender GLB could not be read")
		quit(1)
		return
	var imported := document.generate_scene(state)
	root.add_child(imported)
	var meshes := imported.find_children("*", "MeshInstance3D", true, false)
	var bounds := AABB()
	var first := true
	for mesh in meshes:
		var box: AABB = mesh.global_transform * mesh.get_aabb()
		bounds = box if first else bounds.merge(box)
		first = false
	if meshes.size() < 100 or not bounds.size.is_finite() or bounds.size.y < 1.7 or bounds.size.y > 2.4 or bounds.size.x > 5:
		push_error("Round-trip geometry or axis/scale check failed: " + str(bounds))
		quit(1)
		return
	print("BLENDER ROUND TRIP PASS: ", meshes.size(), " meshes; dimensions ", bounds.size)
	imported.free()
	quit()
