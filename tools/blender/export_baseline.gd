extends SceneTree
## One-time reference export: the existing prototypes, not replacement game assets.
func _initialize() -> void:
	call_deferred("run")
func remove_hidden(node: Node) -> void:
	for child in node.get_children():
		if child is Node3D and not child.visible:
			child.free()
		else:
			remove_hidden(child)
func run() -> void:
	var directory := ProjectSettings.globalize_path("res://art/blender/baseline")
	DirAccess.make_dir_recursive_absolute(directory)
	for kind in ["willow_scout", "bristleback"]:
		var model: Node3D
		if kind == "willow_scout":
			model = preload("res://scripts/traveler_model.gd").new()
			root.add_child(model)
			var profile := preload("res://scripts/character_profile.gd").defaults()
			profile.build = 0
			model.rebuild(profile)
		else:
			model = preload("res://scripts/bristleback_model.gd").new()
			root.add_child(model)
		model.name = kind
		model.set_process(false)
		remove_hidden(model)
		var document := GLTFDocument.new()
		var state := GLTFState.new()
		var error := document.append_from_scene(model, state)
		if error == OK: error = document.write_to_filesystem(state, directory.path_join(kind + ".glb"))
		if error != OK:
			push_error("Baseline export failed: " + kind)
			quit(1)
			return
		print("BASELINE EXPORTED: ", kind)
		model.free()
	quit()
