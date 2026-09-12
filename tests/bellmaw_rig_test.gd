extends SceneTree
const Art = preload("res://scripts/bellmaw_model.gd")
var failed := false
func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error(message)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var art := Art.new()
	root.add_child(art)
	await process_frame
	var sk: Skeleton3D = art.skeleton
	check(sk.get_bone_count() == 16, "Bellmaw skeleton is incomplete")
	var meshes := sk.find_children("*", "MeshInstance3D", true, false)
	check(meshes.size() == 1, "Extra concept-sheet figures leaked into Bellmaw")
	var mesh: MeshInstance3D = meshes[0]
	check(mesh.skin != null, "Bellmaw mesh has no skin")
	var a := mesh.mesh.surface_get_arrays(0)
	var weights: PackedFloat32Array = a[Mesh.ARRAY_WEIGHTS]
	var bones: PackedInt32Array = a[Mesh.ARRAY_BONES]
	var vertices: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
	check(a[Mesh.ARRAY_INDEX].size() < 180000, "Gameplay mesh exceeds 60,000 triangles")
	check(weights.size() == vertices.size() * 4, "Missing vertex weights")
	var throat_bind := -1
	for i in range(mesh.skin.get_bind_count()):
		if str(mesh.skin.get_bind_name(i)) == "Throat": throat_bind = i
	var throat_vertices := 0
	for i in range(vertices.size()):
		var total := 0.0
		for j in range(4):
			var w := weights[i * 4 + j]
			total += w
			if bones[i * 4 + j] == throat_bind and w > .5: throat_vertices += 1
		check(absf(total - 1) < .001, "Unnormalized skin weights")
	check(throat_vertices > 100, "Warning throat is not bound to visible geometry")
	var throat := sk.find_bone("Throat")
	var leg := sk.find_bone("FrontLUpper")
	art.pose(0, 0, "idle", 0, 0)
	sk.force_update_all_bone_transforms()
	var neutral := sk.get_bone_global_pose(throat)
	var leg_neutral := sk.get_bone_global_pose(leg)
	art.pose(.2, 3.3, "approach", .2, 0)
	sk.force_update_all_bone_transforms()
	check(not sk.get_bone_global_pose(leg).basis.is_equal_approx(leg_neutral.basis), "Walking did not bend the actual skeleton")
	art.pose(.2, 2.3, "return", .2, 0)
	check(art.stride > 0, "Return-home state lost its gait")
	art.pose(0, 0, "warn", 1.2, 0)
	sk.force_update_all_bone_transforms()
	check(sk.get_bone_global_pose(throat).basis.determinant() > neutral.basis.determinant() * 1.4, "Warning did not inflate the skinned throat")
	check(art.limbs[0].rotation.is_zero_approx(), "Warning did not plant the feet")
	check(art.pulse.visible and art.pulse.scale.x == 6, "Six-meter warning ring changed")
	art.pose(0, 0, "idle", 0, 0)
	sk.force_update_all_bone_transforms()
	check(sk.get_bone_global_pose(throat).basis.is_equal_approx(neutral.basis), "Idle retained warning deformation")
	art.body.scale = Vector3.ONE * 2
	art.pose(0, 0, "warn", 1.2, 0)
	check(art.pulse.global_basis.get_scale().x == 6, "Body scale incorrectly doubled the blast ring")
	art.queue_free()
	await process_frame
	if not failed: print("PASS: Bellmaw skin, weighted throat, gait, recovery and independent warning ring")
	quit(1 if failed else 0)
