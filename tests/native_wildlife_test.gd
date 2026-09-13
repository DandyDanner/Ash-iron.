extends SceneTree
## Native wildlife contract: geometry/PBR preservation, grounding, seam-safe skinning and real bone motion.

const Wildlife = preload("res://scripts/native_wildlife_model.gd")
const EXPECTED := {
	"boar": {"asset": "res://assets/creatures/bristleback.glb", "material": "Bristleback Native PBR", "height": 1.20},
	"deer": {"asset": "res://assets/creatures/meadow_buck.glb", "material": "Meadow Buck Native PBR", "height": 2.00},
	"wolf": {"asset": "res://assets/creatures/hollow_wolf.glb", "material": "Hollow Wolf Native PBR", "height": 1.25},
}
var failures := 0


func _initialize() -> void:
	call_deferred("run")


func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)


func arrays_for(mesh: MeshInstance3D, surface: int) -> Array:
	return mesh.mesh.surface_get_arrays(surface)


func posed_vertex(mesh: MeshInstance3D, skeleton: Skeleton3D, arrays: Array, vertex_index: int) -> Vector3:
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
	var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
	var result := Vector3.ZERO
	for influence in range(4):
		var bind := bones[vertex_index * 4 + influence]
		var bone := mesh.skin.get_bind_bone(bind)
		if bone < 0:
			bone = skeleton.find_bone(mesh.skin.get_bind_name(bind))
		var transform := skeleton.get_bone_global_pose(bone) * mesh.skin.get_bind_pose(bind)
		result += (transform * vertices[vertex_index]) * weights[vertex_index * 4 + influence]
	return result


func inspect_species(kind: String) -> void:
	var expected: Dictionary = EXPECTED[kind]
	var packed: PackedScene = load(expected.asset)
	check(packed != null, kind + " GLB did not load")
	if packed == null:
		return
	var imported := packed.instantiate()
	root.add_child(imported)
	var skeletons := imported.find_children("*", "Skeleton3D", true, false)
	check(skeletons.size() == 1, kind + " must contain exactly one skeleton")
	if skeletons.is_empty():
		imported.free()
		return
	var skeleton: Skeleton3D = skeletons[0]
	check(skeleton.get_bone_count() == 19, kind + " rig lost its 19 measured body/leg/head/tail bones")
	for bone in ["Root", "Spine", "Chest", "Neck", "Head", "TailBase", "TailTip", "FrontLLower", "FrontLPaw", "HindRLower", "HindRPaw"]:
		check(skeleton.find_bone(bone) >= 0, kind + " rig is missing " + bone)
	var triangle_count := 0
	var duplicate_points := 0
	var min_y := INF
	var max_y := -INF
	var sample_mesh: MeshInstance3D
	var sample_arrays: Array
	var low_foot_vertices := 0
	var axial_foot_vertices := 0
	var high_antler_vertices := 0
	var nonrigid_antler_vertices := 0
	for node in imported.find_children("*", "MeshInstance3D", true, false):
		var mesh: MeshInstance3D = node
		check(mesh.skin != null, kind + " mesh lost its skin")
		if mesh.skin == null:
			continue
		for surface in range(mesh.mesh.get_surface_count()):
			var arrays := arrays_for(mesh, surface)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
			var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
			var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
			triangle_count += indices.size() / 3
			check(uvs.size() == vertices.size(), kind + " native UV array is missing")
			check(bones.size() == vertices.size() * 4 and weights.size() == vertices.size() * 4, kind + " skin does not have four portable weight slots")
			var material: Material = mesh.get_active_material(surface)
			check(material is StandardMaterial3D and material.resource_name == expected.material, kind + " lost its named native PBR material")
			if material is StandardMaterial3D:
				check(material.albedo_texture != null and material.albedo_texture.get_width() == 2048, kind + " native albedo is missing or not 2K")
				check(material.normal_enabled and material.normal_texture != null and material.normal_texture.get_width() == 2048, kind + " native normal is missing or not 2K")
				check(material.metallic_texture != null and material.roughness_texture != null and material.roughness_texture.get_width() == 2048, kind + " native metallic/roughness map is missing or not 2K")
				check(not material.uv1_triplanar and not material.vertex_color_use_as_albedo, kind + " native UV material was replaced by generated projection/color")
			var at_position := {}
			for vertex_index in range(vertices.size()):
				var point := vertices[vertex_index]
				min_y = minf(min_y, point.y)
				max_y = maxf(max_y, point.y)
				var total := 0.0
				var axial_weight := 0.0
				var head_weight := 0.0
				for influence in range(4):
					var weight := weights[vertex_index * 4 + influence]
					total += weight
					var bind_name := String(mesh.skin.get_bind_name(bones[vertex_index * 4 + influence]))
					if bind_name in ["Head", "TailBase", "TailTip"]:
						axial_weight += weight
					if bind_name == "Head":
						head_weight += weight
				check(absf(total - 1.0) < .001, kind + " has unnormalized skin weights")
				if point.y < .20 and absf(point.x) > .10:
					low_foot_vertices += 1
					if axial_weight > .001:
						axial_foot_vertices += 1
				if kind == "deer" and point.y > 1.45:
					high_antler_vertices += 1
					if head_weight < .999:
						nonrigid_antler_vertices += 1
				var key := "%d:%d:%d" % [roundi(point.x * 100000.0), roundi(point.y * 100000.0), roundi(point.z * 100000.0)]
				var signature := PackedFloat32Array()
				for influence in range(4):
					signature.append(float(bones[vertex_index * 4 + influence]))
					signature.append(snappedf(weights[vertex_index * 4 + influence], .00001))
				if at_position.has(key):
					duplicate_points += 1
					check(at_position[key] == signature, kind + " has mismatched weights across a coincident UV/normal seam")
				else:
					at_position[key] = signature
			if sample_mesh == null:
				sample_mesh = mesh
				sample_arrays = arrays
	check(triangle_count == 60000, kind + " source triangle count changed: %d" % triangle_count)
	check(duplicate_points > 500, kind + " seam regression did not exercise enough exported split vertices")
	check(low_foot_vertices > 500 and axial_foot_vertices == 0, kind + " has %d low foot vertices following Head/Tail" % axial_foot_vertices)
	if kind == "deer":
		check(high_antler_vertices > 500 and nonrigid_antler_vertices == 0, "Deer upper antlers are not rigid to Head: %d / %d" % [nonrigid_antler_vertices, high_antler_vertices])
	check(absf(min_y) < .0015 and absf(max_y - float(expected.height)) < .002, kind + " is not grounded at its declared height: %.4f..%.4f" % [min_y, max_y])
	# Drive the actual runtime wrapper and verify both a bone and weighted vertices move.
	var model := Wildlife.new()
	model.species = kind
	root.add_child(model)
	await process_frame
	var driven_skeleton: Skeleton3D = model.skeleton
	var upper := driven_skeleton.find_bone("FrontLUpper")
	var neutral_rotation := driven_skeleton.get_bone_pose_rotation(upper)
	var driven_mesh: MeshInstance3D = model.meshes[0]
	var driven_arrays := arrays_for(driven_mesh, 0)
	var before := PackedVector3Array()
	var vertex_total: int = (driven_arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
	for vertex_index in range(0, vertex_total, maxi(1, vertex_total / 400)):
		before.append(posed_vertex(driven_mesh, driven_skeleton, driven_arrays, vertex_index))
	var movement_state := "charge" if kind == "boar" else "flee"
	model.pose(.19, 6.0, movement_state, 0.0)
	driven_skeleton.force_update_all_bone_transforms()
	check(not driven_skeleton.get_bone_pose_rotation(upper).is_equal_approx(neutral_rotation), kind + " runtime gait did not rotate the actual front leg bone")
	var largest_displacement := 0.0
	var sample := 0
	for vertex_index in range(0, vertex_total, maxi(1, vertex_total / 400)):
		largest_displacement = maxf(largest_displacement, before[sample].distance_to(posed_vertex(driven_mesh, driven_skeleton, driven_arrays, vertex_index)))
		sample += 1
	check(largest_displacement > .005 and largest_displacement < .45, kind + " weighted surface deformation is absent or unstable: %.4f m" % largest_displacement)
	check(model.body != null and model.head != null and model.legs.size() == 4, kind + " runtime body/head/leg inspection handles are incomplete")
	model.free()
	imported.free()


func run() -> void:
	for kind in EXPECTED:
		await inspect_species(kind)
	var facade := preload("res://scripts/bristleback_model.gd").new()
	root.add_child(facade)
	await process_frame
	check(facade.species == "boar" and facade.skeleton != null, "Gameplay Bristleback facade did not select the native boar")
	facade.pose(.1, 7.5, "warn", .2)
	facade.pose(.1, 7.5, "charge", 0.0)
	facade.pose(.1, 0.0, "recover", 0.0)
	facade.free()
	print("NATIVE WILDLIFE: %s" % ("PASS — native PBR/UV/triangles, grounded scales, seam weights and live deformation" if failures == 0 else "FAIL"))
	quit(1 if failures else 0)
