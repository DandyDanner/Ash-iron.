extends Node3D
## Authored viewmodel hand with seamless relaxed and shaft-grip poses.
const M = preload("res://scripts/traveler_model.gd")
const HAND_ART: PackedScene = preload("res://assets/models/first_person_hands.glb")
var relaxed: Node3D
var gripping: Node3D
var arm: Node3D

func build(skin: Color, cloth: Color, left: bool = false) -> void:
	# Stable marker retained for scene/test callers; the visible palm and wrist
	# are part of each pose mesh so their visibility changes atomically.
	M.joint(self, "PalmAndWrist", Vector3.ZERO)
	relaxed = M.joint(self, "RelaxedFingers", Vector3.ZERO)
	gripping = M.joint(self, "GripFingers", Vector3.ZERO)
	# Local +Z runs cuff-to-elbow for simple camera-space aiming and scaling.
	arm = M.joint(self, "Forearm", Vector3(0,-0.070,0.065))
	var source := HAND_ART.instantiate()
	_add_asset_mesh(source, "RelaxedHand", relaxed, skin, 0.90)
	_add_asset_mesh(source, "RelaxedNails", relaxed, skin.lerp(Color("f4d1c0"), 0.08), 0.82)
	_add_asset_mesh(source, "GripHand", gripping, skin, 0.90)
	_add_asset_mesh(source, "GripNails", gripping, skin.lerp(Color("f4d1c0"), 0.08), 0.82)
	_add_asset_mesh(source, "ArmSleeve", arm, cloth, 0.94)
	_add_asset_mesh(source, "Cuff", arm, cloth.lightened(0.22), 0.92)
	source.free()
	if left: _mirror_geometry()
	set_grip(false)

func _add_asset_mesh(source: Node, mesh_name: String, parent: Node3D, tint: Color, roughness: float) -> MeshInstance3D:
	var authored := source.find_child(mesh_name, true, false) as MeshInstance3D
	assert(authored != null, "Missing first-person hand mesh: %s" % mesh_name)
	var node := MeshInstance3D.new()
	node.name = mesh_name
	node.mesh = authored.mesh
	node.transform = _asset_transform(authored, source)
	node.material_override = _material(tint, roughness)
	parent.add_child(node)
	return node

func _asset_transform(authored: Node3D, source: Node) -> Transform3D:
	# Imported GLBs can insert intermediate Node3Ds. Compose their local
	# transforms without asking an unparented PackedScene for global state.
	var result := authored.transform
	var ancestor := authored.get_parent()
	while ancestor != source:
		assert(ancestor != null, "First-person hand mesh is outside its asset root")
		if ancestor is Node3D:
			result = (ancestor as Node3D).transform * result
		ancestor = ancestor.get_parent()
	return result

func _material(color: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic_specular = 0.18
	return material

func set_grip(enabled: bool) -> void:
	gripping.visible = enabled
	relaxed.visible = not enabled

func set_draw_pose(drawing: bool) -> void:
	# Kept as a compatibility hook; player.gd fits the +Z sleeve axis to its elbow.
	var _drawing := drawing

func _mirror_geometry() -> void:
	# Bake reflection with corrected triangle winding; negative node scale reverses face culling.
	for node in find_children("*", "Node3D", true, false):
		node.position.x = -node.position.x
		if not node is MeshInstance3D: continue
		var mirrored := ArrayMesh.new()
		for surface_index in range(node.mesh.get_surface_count()):
			var arrays: Array = node.mesh.surface_get_arrays(surface_index)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
			for i in range(vertices.size()):
				vertices[i].x = -vertices[i].x
				normals[i].x = -normals[i].x
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			for i in range(0, indices.size(), 3):
				var old := indices[i + 1]
				indices[i + 1] = indices[i + 2]
				indices[i + 2] = old
			arrays[Mesh.ARRAY_VERTEX] = vertices
			arrays[Mesh.ARRAY_NORMAL] = normals
			arrays[Mesh.ARRAY_INDEX] = indices
			arrays[Mesh.ARRAY_TANGENT] = null
			mirrored.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		node.mesh = mirrored
