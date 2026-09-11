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
