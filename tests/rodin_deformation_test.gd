extends SceneTree
## Regression: short hip triangles must not stretch into long hand-to-trouser webs.
const Profile = preload("res://scripts/character_profile.gd")
const Save = preload("res://scripts/game_save.gd")
const Paths = preload("res://tests/test_paths.gd")
var failures := 0
func _initialize() -> void:
	Profile.storage_path = Paths.path("rodin_deformation_profile.json")
	Save.storage_path = Paths.path("rodin_deformation_save.json")
	call_deferred("run")
func hip_stretch(avatar: Node3D) -> float:
	var skeleton: Skeleton3D = avatar.authored.skeleton
	skeleton.force_update_all_bone_transforms()
	var largest := 0.0
	for mesh in avatar.body.find_children("*", "MeshInstance3D", true, false):
		if mesh.skin == null or not mesh.visible: continue
		var transforms: Array[Transform3D] = []
		for bind in range(mesh.skin.get_bind_count()):
			var bone: int = mesh.skin.get_bind_bone(bind)
			if bone < 0: bone = skeleton.find_bone(mesh.skin.get_bind_name(bind))
			transforms.append(skeleton.get_bone_global_pose(bone) * mesh.skin.get_bind_pose(bind))
		for surface in range(mesh.mesh.get_surface_count()):
			var arrays: Array = mesh.mesh.surface_get_arrays(surface)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
			var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			var posed := PackedVector3Array()
			posed.resize(vertices.size())
			for v in range(vertices.size()):
				var point := Vector3.ZERO
				for influence in range(4):
					point += (transforms[bones[v * 4 + influence]] * vertices[v]) * weights[v * 4 + influence]
				posed[v] = point
			for face in range(0, indices.size(), 3):
				for edge in range(3):
					var a := indices[face + edge]
					var b := indices[face + (edge + 1) % 3]
					if vertices[a].y < .8 or vertices[a].y > 1.15: continue
					largest = maxf(largest, posed[a].distance_to(posed[b]) - vertices[a].distance_to(vertices[b]))
	return largest
func check_ranger_jaw(avatar: Node3D) -> void:
	var checked := 0
	var incorrect := 0
	for mesh in avatar.body.find_children("*", "MeshInstance3D", true, false):
		if mesh.skin == null: continue
		for surface in range(mesh.mesh.get_surface_count()):
			var material: Material = mesh.get_active_material(surface)
			if not ("Skin" in material.resource_name or "Hair" in material.resource_name): continue
			var arrays: Array = mesh.mesh.surface_get_arrays(surface)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
			var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
			for v in range(vertices.size()):
				var point := vertices[v]
				if point.y < 1.78 or point.y > 1.86 or absf(point.x) > .17 or point.z < -.17: continue
				checked += 1
				var head_weight := 0.0
				for influence in range(4):
					if mesh.skin.get_bind_name(bones[v * 4 + influence]) == &"Head":
						head_weight += weights[v * 4 + influence]
				if head_weight < .999: incorrect += 1
	if checked < 100 or incorrect > 0:
		failures += 1
		push_error("Ranger jaw: %d vertices checked, %d follow another bone" % [checked, incorrect])

func run() -> void:
	for design in range(4):
		Save.clear()
		var profile := Profile.defaults()
		profile.traveler = design
		Profile.save_profile(profile)
		change_scene_to_file("res://scenes/main.tscn")
		await scene_changed
		for frame in range(5): await physics_frame
		var player: Node3D = current_scene.get_node("Player")
		player.set_physics_process(false)
		player.view_rig.set_physics_process(false)
		var avatar: Node3D = player.view_rig.avatar
		if design == 1: check_ranger_jaw(avatar)
		for item in ["stone_axe", "bow", "stone_spear", ""]:
			if not item.is_empty(): player.inventory.add(item, 1)
			player.equip_item(item)
			avatar.animate_movement(.15, 5 if item.is_empty() else 0, true, 0, item, -1, 0)
			player.view_rig._sync_equipment()
			var stretch := hip_stretch(avatar)
			if stretch > .08:
				failures += 1
				push_error("Traveler %d / %s hip triangle stretched %.3f m" % [design, item, stretch])
	Save.clear()
	DirAccess.remove_absolute(Profile.storage_path)
	print("RODIN DEFORMATION: %s" % ("PASS" if failures == 0 else "FAIL"))
	quit(1 if failures else 0)
