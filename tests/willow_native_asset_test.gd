extends SceneTree
## UV seams must move together; the approved face must stay on its head bone.
var failures := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _initialize() -> void:
	var packed: PackedScene = load("res://assets/characters/willow_scout.glb")
	var avatar := packed.instantiate()
	var seams := {}
	var duplicate_points := 0
	var head_points := 0
	var bounds := AABB()
	var first := true
	for mesh in avatar.find_children("*", "MeshInstance3D", true, false):
		if mesh.skin == null: continue
		for surface in range(mesh.mesh.get_surface_count()):
			var arrays: Array = mesh.mesh.surface_get_arrays(surface)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
			var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
			for i in range(vertices.size()):
				var p := vertices[i]
				bounds = AABB(p, Vector3.ZERO) if first else bounds.expand(p)
				first = false
				var by_name := {}
				var total := 0.0
				for j in range(4):
					var weight := weights[i * 4 + j]
					total += weight
					if weight > .00001:
						by_name[String(mesh.skin.get_bind_name(bones[i * 4 + j]))] = weight
				check(absf(total - 1.0) < .001, "Willow has unnormalized skin weights")
				if p.y > 1.78:
					head_points += 1
					check(float(by_name.get("Head", 0.0)) > .999, "Willow's face or hair follows another bone")
				var key := Vector3i(roundi(p.x * 100000.0), roundi(p.y * 100000.0), roundi(p.z * 100000.0))
				if seams.has(key):
					duplicate_points += 1
					var previous: Dictionary = seams[key]
					for bone in by_name:
						check(absf(float(previous.get(bone, 0.0)) - float(by_name[bone])) < .005, "A Willow texture seam has different bone weights and would open in motion")
				else:
					seams[key] = by_name
	check(duplicate_points > 1000, "Did not exercise Willow's duplicated UV seam vertices")
	check(head_points > 1000, "Did not exercise the full Willow head")
	check(absf(bounds.position.y) < .001 and absf(bounds.end.y - 2.06) < .001, "Willow must remain grounded at the original traveler height")
	avatar.free()
	print("WILLOW NATIVE ASSET: %s — %d seam points, %d head points" % ["PASS" if failures == 0 else "FAIL", duplicate_points, head_points])
	quit(1 if failures else 0)
