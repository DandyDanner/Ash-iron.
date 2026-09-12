extends RefCounted
## Shared supplied art; gameplay actors still own interaction, collision and persistence.
const PINE = preload("res://assets/props/pine.glb")
const ROCK = preload("res://assets/props/rock_cluster.glb")
const CHEST = preload("res://assets/props/storage_chest.glb")
const ORE_SHADER = preload("res://assets/shaders/ore_palette.gdshader")
static var rock_materials: Dictionary = {}
static var pine_material: StandardMaterial3D

static func pine(parent: Node3D, variation: int = 0) -> Node3D:
	var art: Node3D = PINE.instantiate()
	art.name = "ImportedPine"
	parent.add_child(art)
	art.rotation.y = variation * .83
	art.scale.y = 1.0 + (variation % 3 - 1) * .045
	for mesh in art.find_children("*", "MeshInstance3D", true, false):
		if pine_material == null:
			pine_material = mesh.get_active_material(0).duplicate()
			pine_material.albedo_color = Color(.61, .70, .61)
			pine_material.normal_scale = .35
		mesh.material_override = pine_material
	_lods(art, "Pine", 28.0)
	return art

static func _lods(art: Node3D, prefix: String, distance: float) -> void:
	for mesh in art.find_children("*", "MeshInstance3D", true, false):
		if str(mesh.name).begins_with(prefix + "Near"):
			mesh.visibility_range_end = distance
			mesh.visibility_range_end_margin = 2.0
		elif str(mesh.name).begins_with(prefix + "Far"):
			mesh.visibility_range_begin = distance
			mesh.visibility_range_begin_margin = 2.0

static func rock(parent: Node3D, size: Vector3, kind: String = "stone", centered: bool = false) -> Node3D:
	var art: Node3D = ROCK.instantiate()
	art.name = "ImportedRock_" + kind
	parent.add_child(art)
	art.scale = size
	if centered: art.position.y = -size.y * .5
	_lods(art, "Rock", 22.0)
	for mesh in art.find_children("*", "MeshInstance3D", true, false):
		mesh.material_override = _rock_material(kind, mesh.get_active_material(0))
	return art

static func _rock_material(kind: String, source: StandardMaterial3D) -> ShaderMaterial:
	if rock_materials.has(kind): return rock_materials[kind]
	var material := ShaderMaterial.new()
	material.shader = ORE_SHADER
	material.set_shader_parameter("surface_texture", source.albedo_texture)
	material.set_shader_parameter("normal_texture", source.normal_texture)
	material.set_shader_parameter("stone_color", Color("858990") if kind == "stone" else Color("555b61"))
	material.set_shader_parameter("mineral_amount", 0.0 if kind == "stone" else 1.0)
	material.set_shader_parameter("mineral_color", Color("ca844b") if kind == "copper_ore" else Color("b3bdc6"))
	material.set_shader_parameter("weather_amount", .55 if kind == "copper_ore" else 0.0)
	material.set_shader_parameter("weather_color", Color("548d76"))
	rock_materials[kind] = material
	return material

static func chest(parent: Node3D) -> Node3D:
	var art: Node3D = CHEST.instantiate()
	art.name = "ImportedChest"
	parent.add_child(art)
	return art.find_child("ChestLid", true, false)
