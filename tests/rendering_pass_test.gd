extends SceneTree
## Guards the Forward+ rendering pass: renderer setting, clearing lighting, creator stage
## lighting, and the runtime treatment of the Rodin traveler materials, including each
## traveler's dedicated face maps.
const Profile = preload("res://scripts/character_profile.gd")
const GameSave = preload("res://scripts/game_save.gd")
const SurfaceDetail = preload("res://scripts/surface_detail.gd")
var failures := 0

func _initialize() -> void:
	Profile.storage_path = preload("res://tests/test_paths.gd").path("rendering_pass_profile.json")
	GameSave.storage_path = preload("res://tests/test_paths.gd").path("rendering_pass_save_%d.json" % Time.get_ticks_usec())
	GameSave.clear()
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func ticks(count: int = 3) -> void:
	for i in range(count):
		await physics_frame
		await process_frame

func run() -> void:
	check(ProjectSettings.get_setting("rendering/renderer/rendering_method") == "forward_plus", "Desktop renderer is not Forward+")
	check(ProjectSettings.get_setting("rendering/renderer/rendering_method.mobile") == "gl_compatibility", "Mobile renderer should stay on compatibility")
	# Clearing lighting.
	change_scene_to_file("res://scenes/main.tscn")
	await scene_changed
	await ticks(4)
	var env: Environment = current_scene.get_node("WorldEnvironment").environment
	var sun: DirectionalLight3D = current_scene.get_node("Sun")
	check(env.background_mode == Environment.BG_SKY and env.sky != null, "Clearing lost its procedural sky")
	check(env.ambient_light_source == Environment.AMBIENT_SOURCE_COLOR and env.ambient_light_energy < 0.5, "Clearing ambient should be the low cool tint (a bright sky ambient washes Forward+ out)")
	check(env.reflected_light_source == Environment.REFLECTION_SOURCE_SKY, "Clearing should reflect the sky on glossy surfaces")
	check(env.tonemap_mode != Environment.TONE_MAPPER_LINEAR, "Clearing is not tonemapped")
	check(env.ssao_enabled and env.glow_enabled and env.fog_enabled, "Clearing SSAO, glow or fog is off")
	check(not env.sdfgi_enabled and not env.volumetric_fog_enabled and not env.ssil_enabled, "Global illumination or volumetric fog would break the retina frame budget")
	check(env.fog_density < 0.004, "Fog density washes out Forward+ (measured: 0.006 reads pale)")
	check(sun.shadow_enabled and sun.light_angular_distance > 0.0, "Sun shadows should be soft")
	check(sun.directional_shadow_max_distance <= 55.0, "Shadow distance exceeds the measured budget")
	# Traveler materials as the game dresses them.
	var player := current_scene.get_node("Player")
	var avatar: Node3D = player.view_rig.avatar
	check(avatar.body.get_meta("traveler_design", -1) >= 0, "Default traveler is not a Rodin export")
	var names := {}
	for mesh in avatar.body.find_children("*", "MeshInstance3D", true, false):
		for surface in range(mesh.mesh.get_surface_count()):
			var material: StandardMaterial3D = mesh.get_active_material(surface)
			names[material.resource_name.get_slice(".", 0)] = material
	check(names.has("Rodin Face"), "Traveler has no dedicated face material")
	if names.has("Rodin Face"):
		var face: StandardMaterial3D = names["Rodin Face"]
		check(face.albedo_texture != null and face.albedo_texture.get_width() == 1024, "Face albedo is missing or not 1024")
		check(face.normal_enabled and face.normal_texture != null, "Face normal map was not imported")
		check(face.roughness_texture != null, "Face roughness map was not imported")
		check(face.subsurf_scatter_enabled and face.vertex_color_use_as_albedo, "Face material was not dressed for skin")
		check(not face.detail_enabled, "Face must keep its own normal map instead of the grain overlay")
	if names.has("Rodin Skin"):
		var skin: StandardMaterial3D = names["Rodin Skin"]
		check(skin.subsurf_scatter_enabled and skin.detail_enabled and skin.uv2_triplanar, "Body skin lost subsurface scattering or grain")
		check(skin.albedo_texture != null and not skin.uv1_triplanar, "Body skin atlas mapping was disturbed")
	if names.has("Rodin Fabric"):
		var fabric: StandardMaterial3D = names["Rodin Fabric"]
		check(fabric.detail_enabled and fabric.detail_uv_layer == BaseMaterial3D.DETAIL_UV_2 and fabric.detail_blend_mode == BaseMaterial3D.BLEND_MODE_MUL, "Fabric grain should ride the multiplied UV2 detail layer")
		check(fabric.albedo_texture != null and not fabric.uv1_triplanar, "Fabric atlas mapping was disturbed")
	# Every traveler export carries face maps.
	for slug in ["willow_scout", "hearthland_ranger", "ridge_wayfarer", "ember_forager"]:
		var scene: PackedScene = load("res://assets/characters/%s.glb" % slug)
		check(scene != null, "Missing traveler export %s" % slug)
		if scene == null: continue
		var instance := scene.instantiate()
		var found := false
		for mesh in instance.find_children("*", "MeshInstance3D", true, false):
			for surface in range(mesh.mesh.get_surface_count()):
				var material: StandardMaterial3D = mesh.mesh.surface_get_material(surface)
				if material and material.resource_name.begins_with("Rodin Face"):
					found = true
					check(material.normal_texture != null and material.roughness_texture != null, "%s face maps are incomplete" % slug)
		check(found, "%s has no face material" % slug)
		instance.free()
	# Creator stage lighting.
	change_scene_to_file("res://scenes/character_creator.tscn")
	await scene_changed
	await ticks(4)
	var stages := current_scene.find_children("*", "SubViewport", true, false)
	check(stages.size() == 1, "Creator stage viewport not found")
	if stages.size() == 1:
		var stage_env: WorldEnvironment = stages[0].find_children("*", "WorldEnvironment", true, false)[0]
		check(stage_env.environment.ssao_enabled and stage_env.environment.tonemap_mode != Environment.TONE_MAPPER_LINEAR, "Creator stage lacks SSAO or tonemapping")
		var stage_sun: DirectionalLight3D = stages[0].find_children("*", "DirectionalLight3D", true, false)[0]
		check(stage_sun.light_angular_distance > 0.0, "Creator sun shadows should be soft")
	GameSave.clear()
	print("RENDERING PASS: %s" % ("PASS — Forward+ setting, clearing and creator lighting, dressed Rodin materials and face maps for all four travelers" if failures == 0 else "FAIL"))
	quit(1 if failures else 0)
