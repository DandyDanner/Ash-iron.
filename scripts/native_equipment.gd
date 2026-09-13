extends RefCounted
## Native Rodin equipment facade. Gameplay nodes keep ownership of timing and collision.

const ASSETS := {
	"stone_axe": "res://assets/equipment/stone_axe.glb",
	"copper_axe": "res://assets/equipment/copper_axe.glb",
	"stone_pickaxe": "res://assets/equipment/stone_pickaxe.glb",
	"stone_spear": "res://assets/equipment/stone_spear.glb",
	"bow": "res://assets/equipment/short_bow.glb",
	"arrow": "res://assets/equipment/arrow.glb",
}


static func add(parent: Node3D, item: String, node_name: String = "") -> Node3D:
	var scene: PackedScene = load(ASSETS[item])
	var art: Node3D = scene.instantiate()
	art.name = node_name if not node_name.is_empty() else item.to_pascal_case() + "NativeAsset"
	parent.add_child(art)
	return art


static func meshes(art: Node3D) -> Array[MeshInstance3D]:
	var result: Array[MeshInstance3D] = []
	for child in art.find_children("*", "MeshInstance3D", true, false):
		result.append(child)
	return result


static func bow_rig(art: Node3D) -> Dictionary:
	var skeletons := art.find_children("*", "Skeleton3D", true, false)
	if skeletons.is_empty():
		push_error("Native short bow has no bend skeleton")
		return {}
	var skeleton: Skeleton3D = skeletons[0]
	var tips := _bow_tips(art)
	_cache_anchor(tips.upper)
	_cache_anchor(tips.lower)
	var upper := skeleton.find_bone("UpperLimb")
	var lower := skeleton.find_bone("LowerLimb")
	return {
		"art": art,
		"skeleton": skeleton,
		"upper": upper,
		"lower": lower,
		"upper_base_pose": skeleton.get_bone_pose_rotation(upper),
		"lower_base_pose": skeleton.get_bone_pose_rotation(lower),
		"upper_anchor": tips.upper,
		"lower_anchor": tips.lower,
		"rest_upper": tips.upper.point,
		"rest_lower": tips.lower.point,
		"posed_upper": tips.upper.point,
		"posed_lower": tips.lower.point,
	}


static func _bow_tips(art: Node3D) -> Dictionary:
	var points: Array[Dictionary] = []
	for mesh in meshes(art):
		for surface in range(mesh.mesh.get_surface_count()):
			var vertices: PackedVector3Array = mesh.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]
			for vertex_index in range(vertices.size()):
				points.append({
					"mesh": mesh,
					"surface": surface,
					"vertex": vertex_index,
					"point": art.to_local(mesh.to_global(vertices[vertex_index])),
				})
	var low := INF
	var high := -INF
	for candidate in points:
		low = minf(low, candidate.point.y)
		high = maxf(high, candidate.point.y)
	var upper_candidates: Array[Dictionary] = []
	var lower_candidates: Array[Dictionary] = []
	for candidate in points:
		if candidate.point.y > high - .025:
			upper_candidates.append(candidate)
		if candidate.point.y < low + .025:
			lower_candidates.append(candidate)
	return {
		"upper": _string_side(upper_candidates),
		"lower": _string_side(lower_candidates),
	}


static func _string_side(candidates: Array[Dictionary]) -> Dictionary:
	var selected: Dictionary = candidates[0]
	for candidate in candidates:
		if candidate.point.z > selected.point.z:
			selected = candidate
	return selected


static func _cache_anchor(anchor: Dictionary) -> void:
	var mesh: MeshInstance3D = anchor.mesh
	var arrays := mesh.mesh.surface_get_arrays(anchor.surface)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
	var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
	anchor.source_vertex = vertices[anchor.vertex]
	anchor.influences = []
	for influence in range(4):
		anchor.influences.append({
			"bind": bones[anchor.vertex * 4 + influence],
			"weight": weights[anchor.vertex * 4 + influence],
		})


static func _posed_anchor(rig: Dictionary, anchor: Dictionary) -> Vector3:
	var mesh: MeshInstance3D = anchor.mesh
	var result := Vector3.ZERO
	for influence in anchor.influences:
		var bind: int = influence.bind
		var bone := mesh.skin.get_bind_bone(bind)
		if bone < 0:
			bone = rig.skeleton.find_bone(mesh.skin.get_bind_name(bind))
		var skin_transform: Transform3D = rig.skeleton.get_bone_global_pose(bone) * mesh.skin.get_bind_pose(bind)
		result += (skin_transform * anchor.source_vertex) * influence.weight
	return rig.art.to_local(mesh.to_global(result))


static func pose_bow(rig: Dictionary, pull: float) -> Dictionary:
	if rig.is_empty():
		return {"upper": Vector3(0, .68, .12), "lower": Vector3(0, -.68, .12)}
	var skeleton: Skeleton3D = rig.skeleton
	# Both limbs follow the string hand slightly. Opposite X rotations move the
	# upper and lower tips together in local +Z while leaving the grip planted.
	# Compose onto each imported pose: the lower limb carries a PI-around-X basis
	# correction that must survive draw animation.
	var angle := pull * .075
	if rig.upper >= 0:
		skeleton.set_bone_pose_rotation(rig.upper, rig.upper_base_pose * Quaternion(Vector3.RIGHT, angle))
	if rig.lower >= 0:
		skeleton.set_bone_pose_rotation(rig.lower, rig.lower_base_pose * Quaternion(Vector3.RIGHT, -angle))
	skeleton.force_update_all_bone_transforms()
	# Read the actual skinned nock vertices. This composes each pose with the
	# imported bone rest basis and skin bind transform, including the lower bone's
	# reversed rest axis, rather than approximating both tips around world origin.
	rig.posed_upper = _posed_anchor(rig, rig.upper_anchor)
	rig.posed_lower = _posed_anchor(rig, rig.lower_anchor)
	return {"upper": rig.posed_upper, "lower": rig.posed_lower}
