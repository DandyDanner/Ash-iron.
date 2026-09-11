extends Node3D
## Replaceable gameplay sculpt. Broad silhouette, folded throat and planted four-foot gait.
const M = preload("res://scripts/traveler_model.gd")
const D = preload("res://scripts/character_mesh.gd")
const SKIN := Color("606953")
var boom_radius := 6.0
var body: Node3D
var throat: Node3D
var limbs: Array[Node3D] = []
var pulse: MeshInstance3D
var elapsed := 0.0
var upper_lip: Node3D

func _ready() -> void:
	body = M.joint(self, "Body", Vector3.ZERO)
	var torso := D.loft(body, [Vector4(-1.08,0.10,0.10,-0.62),Vector4(-0.85,0.57,0.43,-0.76),Vector4(-0.35,0.85,0.57,-0.82),Vector4(0.25,0.76,0.49,-0.85),Vector4(0.60,0.54,0.36,-0.88),Vector4(0.81,0.15,0.12,-0.90)], SKIN, 40, 0.022)
	torso.rotation.x = PI / 2
	D.oval(body, Vector3(0, 0.66, 0.5), Vector3(1.35, 0.93, 1.02), SKIN.darkened(0.12))
	D.oval(body, Vector3(0, 1.12, 0.58), Vector3(1.35, 0.53, 0.98), SKIN)
	# Strong upper lip and a recessed, wide dark mouth.
	D.oval(body, Vector3(0, 0.97, 0.99), Vector3(1.08, 0.13, 0.19), Color("302b20"))
	upper_lip = D.oval(body, Vector3(0, 1.05, 1.0), Vector3(1.15, 0.13, 0.25), SKIN.lightened(0.1))
	throat = M.joint(body, "ResonantThroat", Vector3(0, 0.68, 0.84))
	D.loft(throat, [Vector4(-0.375,0.015,0.015,0), Vector4(-0.30,0.28,0.20,0), Vector4(-0.15,0.46,0.31,0), Vector4(0,0.51,0.34,0), Vector4(0.15,0.47,0.30,0), Vector4(0.30,0.32,0.19,0), Vector4(0.375,0.08,0.04,0)], Color("bb8a40"), 48, 0.045)
	for side in [-1, 1]:
		D.oval(body, Vector3(side * 0.43, 1.28, 0.7), Vector3(0.32, 0.17, 0.34), SKIN.darkened(0.2))
		D.oval(body, Vector3(side * 0.46, 1.28, 0.84), Vector3(0.115, 0.105, 0.10), Color("161a13"))
		D.strand(body, [Vector3(side*0.31,1.29,0.81),Vector3(side*0.44,1.35,0.84),Vector3(side*0.57,1.29,0.78)], [0.01,0.035,0.008], SKIN.darkened(0.10), 0.65)
		D.oval(body, Vector3(side * 0.44, 1.315, 0.89), Vector3(0.025, 0.025, 0.014), Color("ead9ae"))
		D.oval(body, Vector3(side * 0.19, 1.16, 1.05), Vector3(0.07, 0.045, 0.018), Color("373c2c"))
		for front in [true, false]:
			var limb := M.joint(body, "Foot_%s_%s" % [side, front], Vector3(side * 0.67, 0.68, 0.52 if front else -0.76))
			limbs.append(limb)
			D.oval(limb, Vector3(side * 0.12, -0.1, -0.03), Vector3(0.57, 0.72, 0.63), SKIN)
			D.oval(limb, Vector3(side * 0.22, -0.4, 0.12), Vector3(0.4, 0.5, 0.44), SKIN.darkened(0.08))
			D.oval(limb, Vector3(side * 0.23, -0.56, 0.24), Vector3(0.49, 0.22, 0.56), SKIN)
			for toe in range(3):
				var x: float = side * 0.23 + (toe - 1) * 0.12
				D.oval(limb, Vector3(x, -0.57, 0.46), Vector3(0.14, 0.15, 0.28), SKIN.lightened(0.03))
				D.strand(limb, [Vector3(x, -0.56, 0.52), Vector3(x, -0.60, 0.64), Vector3(x, -0.63, 0.68)], [0.052, 0.035, 0.001], Color("4b4431"))
	# Irregular small dorsal scales, placed on the actual ellipsoid surface.
	var rng := RandomNumberGenerator.new()
	rng.seed = 6412
	for i in range(68):
		var a := rng.randf_range(-1.05, 1.05)
		var b := rng.randf_range(-1.1, 0.85)
		var pos := Vector3(sin(a) * cos(b) * 0.87, 0.82 + cos(a) * cos(b) * 0.56, -0.15 + sin(b) * 0.96)
		var size := rng.randf_range(0.065, 0.15)
		D.oval(body, pos, Vector3(size, size * 0.48, size * 1.5), SKIN.lightened(rng.randf_range(-0.04, 0.14)))
	# Subtle original procedural skin variation; the gameplay mesh stays replaceable.
	for mesh in body.find_children("*", "MeshInstance3D", true, false):
		var base: StandardMaterial3D = mesh.material_override
		if base.albedo_color.r < 0.15: continue # Keep eyes and mouth crisp.
		var material := ShaderMaterial.new()
		material.shader = preload("res://assets/shaders/bellmaw_skin.gdshader")
		material.set_shader_parameter("skin_color", base.albedo_color)
		mesh.material_override = material
	pulse = MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = 0.95
	ring.outer_radius = 1.0
	ring.rings = 48
	ring.ring_segments = 8
	pulse.mesh = ring
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.96, 0.68, 0.28, 0.8)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	pulse.material_override = material
	pulse.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	pulse.position.y = 0.1
	add_child(pulse)
	pulse.hide()

func pose(delta: float, speed: float, state: String, state_time: float, hit_flash: float) -> void:
	elapsed += delta
	var inflation := clampf(state_time / 1.2, 0, 1) if state == "warn" else 0.0
	upper_lip.position.y = 1.05 + inflation * 0.035
	throat.scale = Vector3(1 + inflation * 0.30, 1 + inflation * 0.43, 1 + inflation * 0.38)
	body.position.y = sin(elapsed * 1.8) * 0.014 - (0.04 if state == "recover" else 0.0)
	body.rotation.x = -0.05 * inflation + (hit_flash * 0.2)
	for i in range(limbs.size()):
		limbs[i].rotation.x = sin(elapsed * 6 + (PI if i in [1, 2] else 0)) * minf(speed, 2) * 0.10
	# The ring shows the complete danger boundary during the warning; the burst then fades.
	pulse.visible = state == "warn" or (state == "recover" and state_time < 0.45)
	if pulse.visible:
		pulse.scale = Vector3(boom_radius, 1, boom_radius)
		pulse.material_override.albedo_color.a = (0.25 + inflation * 0.4) if state == "warn" else (1 - state_time / 0.45) * 0.65
