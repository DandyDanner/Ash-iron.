extends RefCounted
## Small, reusable surface treatments that preserve the authored vertex colors and skinning.
static var textures: Dictionary = {}
# Share by our surface palette rather than per-instance IDs, including across world reloads.
static var materials: Dictionary = {}

static func grain(kind: String) -> ImageTexture:
	if textures.has(kind): return textures[kind]
	var noise := FastNoiseLite.new()
	noise.seed = 4531
	noise.frequency = 0.08 if kind == "fabric" else 0.035
	noise.fractal_octaves = 3
	# Bake shared grain once, without asynchronous texture-change callbacks.
	var image := noise.get_seamless_image(256, 256)
	image.bump_map_to_normal_map(0.4 if kind == "skin" else 1.2)
	image.generate_mipmaps()
	var texture := ImageTexture.create_from_image(image)
	textures[kind] = texture
	return texture

static func refine(source: StandardMaterial3D, kind: String) -> StandardMaterial3D:
	var key := "%s:%s:%s" % [kind, source.resource_name, source.albedo_color.to_html()]
	if materials.has(key): return materials[key]
	var material: StandardMaterial3D = source.duplicate()
	material.normal_enabled = true
	material.normal_texture = grain(kind)
	material.normal_scale = 0.18 if kind == "skin" else 0.35
	material.uv1_triplanar = true
	material.uv1_scale = Vector3.ONE * (7.0 if kind == "skin" else 4.0)
	material.roughness = 0.76 if kind == "skin" else 0.92
	material.metallic_specular = 0.22
	materials[key] = material
	return material

## Rodin travelers arrive with painted UV1 maps. Treatments stay on the detail layer and
## triplanar UV2 so the albedo, face normal and roughness maps survive untouched.
static func dress(source: StandardMaterial3D) -> StandardMaterial3D:
	# Willow's replacement arrives with its final authored PBR response. Returning the
	# shared resource also keeps all three skinned meshes on the same material identity.
	if source.resource_name == "Willow Native PBR":
		return source
	# Blender numbers repeated names across the four figures ("Rodin Skin.001").
	var name := source.resource_name.get_slice(".", 0)
	var key := "dress:%s:%s" % [name, source.albedo_texture.get_rid() if source.albedo_texture else source.albedo_color.to_html()]
	if materials.has(key): return materials[key]
	var material: StandardMaterial3D
	if name in ["Game Skin", "Game Fabric"]:
		material = refine(source, "skin" if name == "Game Skin" else "fabric")
	else:
		material = source.duplicate()
	# Godot's importer retains COLOR_0 but does not always enable it on the material.
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = false
	match name:
		"Rodin Face", "Rodin Skin":
			material.subsurf_scatter_enabled = true
			material.subsurf_scatter_strength = 0.3 if name == "Rodin Face" else 0.22
			material.subsurf_scatter_skin_mode = true
			material.metallic_specular = 0.4
			if name == "Rodin Skin":
				overlay(material, "skin", 7.0)
		"Rodin Hair":
			material.roughness = 0.55
			material.metallic_specular = 0.45
		"Rodin Fabric":
			material.roughness = 0.9
			overlay(material, "fabric", 4.0)
		"Rodin Leather":
			material.roughness = 0.72
			material.metallic_specular = 0.35
			overlay(material, "skin", 5.0)
		"Rodin Metal":
			material.metallic = 0.6
			material.roughness = 0.45
	materials[key] = material
	return material

## A normal grain on the detail layer, projected triplanar through UV2, leaves UV1 textures alone.
static func overlay(material: StandardMaterial3D, kind: String, scale: float) -> void:
	material.detail_enabled = true
	material.detail_blend_mode = BaseMaterial3D.BLEND_MODE_MUL
	material.detail_uv_layer = BaseMaterial3D.DETAIL_UV_2
	material.detail_normal = grain(kind)
	material.uv2_triplanar = true
	material.uv2_triplanar_sharpness = 2.0
	material.uv2_scale = Vector3.ONE * scale
