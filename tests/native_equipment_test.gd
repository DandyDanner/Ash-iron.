extends SceneTree
## Native Rodin equipment keeps its mesh/PBR data and established gameplay landmarks.
const Equipment = preload("res://scripts/native_equipment.gd")
const Archery = preload("res://scripts/archery_art.gd")
const Pickup = preload("res://scripts/resource_pickup.gd")
const EXPECTED := {
	"stone_axe": {"triangles": 12000, "material": "Stone Axe Native PBR"},
	"copper_axe": {"triangles": 12000, "material": "Copper Axe Native PBR"},
	"stone_pickaxe": {"triangles": 12000, "material": "Stone Pickaxe Native PBR"},
	"stone_spear": {"triangles": 12000, "material": "Stone Spear Native PBR"},
	"bow": {"triangles": 12000, "material": "Short Bow Native PBR"},
	"arrow": {"triangles": 3477, "material": "Arrow Native PBR"},
}
var failures := 0


func _initialize() -> void:
	call_deferred("run")


func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)


func asset_bounds(art: Node3D) -> AABB:
	var first := true
	var result := AABB()
	for mesh in Equipment.meshes(art):
		for surface in range(mesh.mesh.get_surface_count()):
			var vertices: PackedVector3Array = mesh.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]
			for vertex in vertices:
				var point := art.to_local(mesh.to_global(vertex))
				if first:
					result = AABB(point, Vector3.ZERO)
					first = false
				else:
					result = result.expand(point)
	return result


func skinned_anchor(rig: Dictionary, anchor: Dictionary) -> Vector3:
	var mesh: MeshInstance3D = anchor.mesh
	var arrays := mesh.mesh.surface_get_arrays(anchor.surface)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
	var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
	var result := Vector3.ZERO
	for influence in range(4):
		var bind := bones[anchor.vertex * 4 + influence]
		var bone := mesh.skin.get_bind_bone(bind)
		if bone < 0:
			bone = rig.skeleton.find_bone(mesh.skin.get_bind_name(bind))
		result += ((rig.skeleton.get_bone_global_pose(bone) * mesh.skin.get_bind_pose(bind)) * vertices[anchor.vertex]) * weights[anchor.vertex * 4 + influence]
	return rig.art.to_local(mesh.to_global(result))


func inspect_asset(holder: Node3D, item: String) -> Node3D:
	var art := Equipment.add(holder, item)
	var triangles := 0
	var found_material := false
	var found_fletching := false
	var found_copper_finish := false
	var mesh_count := 0
	var arrow_shaft_radius := 0.0
	var arrow_head_radius := 0.0
	var arrow_feather_radius := 0.0
	for mesh in Equipment.meshes(art):
		mesh_count += 1
		for surface in range(mesh.mesh.get_surface_count()):
			var arrays := mesh.mesh.surface_get_arrays(surface)
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			triangles += indices.size() / 3 if not indices.is_empty() else vertices.size() / 3
			var material := mesh.get_active_material(surface)
			if material != null and material.resource_name == EXPECTED[item].material:
				var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
				found_material = true
				check(uvs.size() == vertices.size(), item + " lost native UV coordinates")
				check(material is StandardMaterial3D, item + " native material changed type")
				if material is StandardMaterial3D:
					check(material.albedo_texture != null and material.albedo_texture.get_width() == 2048, item + " albedo is missing or not 2K")
					check(material.normal_enabled and material.normal_texture != null and material.normal_texture.get_width() == 2048, item + " normal is missing or not 2K")
					check(material.metallic_texture != null and material.roughness_texture != null and material.roughness_texture.get_width() == 2048, item + " metallic/roughness texture is missing or not 2K")
					check(not material.uv1_triplanar and not material.vertex_color_use_as_albedo, item + " replaced native UV/PBR shading")
				if item == "arrow":
					for vertex in vertices:
						var radial := Vector2(vertex.x, vertex.y).length()
						if absf(vertex.z) < .20:
							arrow_shaft_radius = maxf(arrow_shaft_radius, radial)
						if vertex.z < -.415:
							arrow_head_radius = maxf(arrow_head_radius, radial)
			elif item == "copper_axe" and material != null and material.resource_name == "Copper Axe Head Finish":
				found_copper_finish = true
				if material is StandardMaterial3D:
					check(material.albedo_texture != null and material.normal_texture != null and material.roughness_texture != null, "Copper head finish lost native PBR texture detail")
					check("copper_axe_head_albedo" in material.albedo_texture.resource_path, "Copper axe head lost its luminance-preserving warm albedo grade")
			elif item == "arrow" and material != null and material.resource_name == "Compact Brown Feather PBR":
				found_fletching = true
				for vertex in vertices:
					arrow_feather_radius = maxf(arrow_feather_radius, Vector2(vertex.x, vertex.y).length())
	check(mesh_count > 0, item + " asset has no rendered mesh")
	check(triangles == EXPECTED[item].triangles, "%s triangle budget changed: %d" % [item, triangles])
	check(found_material, item + " lost its named native PBR material")
	if item == "arrow":
		check(found_fletching, "Arrow cleanup lost its compact nock fletching")
		check(arrow_shaft_radius <= .005 and arrow_shaft_radius >= .0035, "Arrow shaft is not a credible 7–10 mm diameter")
		check(arrow_head_radius <= .019 and arrow_head_radius >= .014, "Arrow point is not a compact 28–38 mm width")
		check(arrow_feather_radius <= .033 and arrow_feather_radius >= .029, "Arrow fletching is not approximately 6 cm wide")
	if item == "copper_axe":
		check(found_copper_finish, "Copper axe has no visible warm-metal head finish")
	return art


func check_grounded_pickups(holder: Node3D) -> void:
	for item in ["stone_axe", "copper_axe", "stone_pickaxe", "stone_spear", "bow", "arrow", "bench", "furnace"]:
		var pickup := Pickup.new()
		pickup.item_id = item
		holder.add_child(pickup)
		var first := true
		var low := 0.0
		for mesh in pickup.find_children("*", "MeshInstance3D", true, false):
			for surface in range(mesh.mesh.get_surface_count()):
				var vertices: PackedVector3Array = mesh.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]
				for vertex in vertices:
					var height := holder.to_local(mesh.to_global(vertex)).y
					if first or height < low:
						low = height
						first = false
		check(not first, item + " dropped pickup has no visible mesh")
		check(low >= -.012 and low <= .09, "%s dropped pickup is sunk or floating (lowest vertex %.3f m)" % [item, low])
		if item == "furnace":
			check(pickup.find_children("*", "Light3D", true, false).is_empty(), "Packed furnace pickup incorrectly carries a live glow")
		pickup.queue_free()


func run() -> void:
	var holder := Node3D.new()
	root.add_child(holder)
	for item in EXPECTED:
		var art := inspect_asset(holder, item)
		var box := asset_bounds(art)
		match item:
			"stone_axe", "copper_axe", "stone_pickaxe":
				check(absf(box.position.y + .20) < .012 and absf(box.end.y - .52) < .012, item + " no longer uses the axe/pick grip landmark")
			"stone_spear":
				check(absf(box.position.z + 1.28) < .012 and absf(box.end.z - .47) < .012, "Spear point/grip contract changed")
			"bow":
				check(absf(box.position.y + .68) < .012 and absf(box.end.y - .68) < .012, "Bow grip/limb span changed")
				var rig := Equipment.bow_rig(art)
				check(not rig.is_empty() and rig.upper >= 0 and rig.lower >= 0, "Bow bend rig is incomplete")
				var rest_tips := Equipment.pose_bow(rig, 0.0)
				var full_tips := Equipment.pose_bow(rig, 1.0)
				check(absf(rig.skeleton.get_bone_pose_rotation(rig.upper).angle_to(rig.upper_base_pose) - .075) < .005, "Full draw does not compose onto the upper limb rest pose")
				check(absf(rig.skeleton.get_bone_pose_rotation(rig.lower).angle_to(rig.lower_base_pose) - .075) < .005, "Full draw stripped the lower limb's imported PI rest correction")
				check(full_tips.upper.distance_to(rest_tips.upper) > .045 and full_tips.lower.distance_to(rest_tips.lower) > .045, "Full draw does not move both native tip anchors")
				check(full_tips.lower.y < -.55 and full_tips.upper.y > .55, "Full draw folded a native limb across the grip")
				check(full_tips.upper.distance_to(skinned_anchor(rig, rig.upper_anchor)) < .0001 and full_tips.lower.distance_to(skinned_anchor(rig, rig.lower_anchor)) < .0001, "Bow tip anchors do not follow actual weighted native vertices")
			"arrow":
				check(absf(box.position.z + .485) < .012 and absf(box.end.z - .335) < .012, "Arrow point/nock contract changed")
	var bow_parent := Node3D.new()
	holder.add_child(bow_parent)
	var bow_parts := Archery.bow(bow_parent)
	Archery.pose_bow(bow_parts, 0.0)
	check((bow_parts.lower.transform * Vector3(0, -.5, 0)).distance_to(bow_parts.rig.rest_lower) < .001, "Resting lower string floats off the native nock")
	check((bow_parts.upper.transform * Vector3(0, .5, 0)).distance_to(bow_parts.rig.rest_upper) < .001, "Resting upper string floats off the native nock")
	Archery.pose_bow(bow_parts, 1.0)
	var actual_lower := skinned_anchor(bow_parts.rig, bow_parts.rig.lower_anchor)
	var actual_upper := skinned_anchor(bow_parts.rig, bow_parts.rig.upper_anchor)
	check((bow_parts.lower.transform * Vector3(0, -.5, 0)).distance_to(actual_lower) < .001, "Full-draw lower string floats off the actual weighted native nock")
	check((bow_parts.upper.transform * Vector3(0, .5, 0)).distance_to(actual_upper) < .001, "Full-draw upper string floats off the actual weighted native nock")
	check_grounded_pickups(holder)
	print("NATIVE EQUIPMENT: %s" % ("PASS — six native UV/PBR assets, triangle budgets, grip/point landmarks, and bow deformation" if failures == 0 else "FAIL"))
	quit(1 if failures else 0)
