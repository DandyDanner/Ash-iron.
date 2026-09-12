extends Node3D
## Uploaded largest creature, weighted in Blender. Gameplay owns timing and collision.
const M = preload("res://scripts/traveler_model.gd")
const SCENE = preload("res://assets/creatures/bellmaw.glb")
var boom_radius := 6.0
var body: Node3D
var spine: Node3D
var head: Node3D
var throat: Node3D
var limbs: Array[Node3D] = []
var knees: Array[Node3D] = []
var feet: Array[Node3D] = []
var pulse: MeshInstance3D
var skeleton: Skeleton3D
var controls: Array[Node3D] = []
var inverse_bind: Array[Transform3D] = []
var bone_rest: Array[Transform3D] = []
var elapsed := 0.0
var gait := 0.0
var stride := 0.0

func _ready() -> void:
	body = M.joint(self, "Body", Vector3.ZERO)
	spine = M.joint(body, "Spine", Vector3(0, .83, -.05))
	head = M.joint(spine, "Head", Vector3(0, .21, .78))
	throat = M.joint(head, "ResonantThroat", Vector3(0, -.44, .25))
	var named := {"Root":body, "Spine":spine, "Head":head, "Throat":throat}
	for side in [-1.0, 1.0]:
		for front in [true, false]:
			var key := ("Front" if front else "Rear") + ("L" if side < 0 else "R")
			var z := .68 if front else -.87
			var upper := M.joint(spine, key + "Upper", Vector3(side * .64, 0, z + .05))
			var lower := M.joint(upper, key + "Lower", Vector3(side * .20, -.46, .03))
			var foot := M.joint(lower, key + "Foot", Vector3(0, -.285, .10))
			limbs.append(upper)
			knees.append(lower)
			feet.append(foot)
			named[key + "Upper"] = upper
			named[key + "Lower"] = lower
			named[key + "Foot"] = foot
	var imported: Node3D = SCENE.instantiate()
	body.add_child(imported)
	# The source contains editable clips; runtime drives the same rig from combat state.
	for animation in imported.find_children("*", "AnimationPlayer", true, false):
		animation.stop()
		animation.active = false
	skeleton = imported.find_children("*", "Skeleton3D", true, false)[0]
	for i in range(skeleton.get_bone_count()):
		var control: Node3D = named[skeleton.get_bone_name(i)]
		controls.append(control)
		inverse_bind.append((skeleton.global_transform.affine_inverse() * control.global_transform).affine_inverse())
		bone_rest.append(skeleton.get_bone_global_rest(i))
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
	pose(0, 0, "idle", 0, 0)

func pose(delta: float, speed: float, state: String, state_time: float, hit_flash: float) -> void:
	elapsed += delta
	var walking := state in ["approach", "return"] and speed > .05
	stride = move_toward(stride, minf(speed / 3.3, 1.0) if walking else 0.0, delta * 7.0)
	# Warning plants the feet immediately so the attack remains readable.
	if state in ["warn", "recover", "idle"]: stride = 0.0
	gait += delta * maxf(speed, .2) * 2.1
	var inflation := clampf(state_time / 1.2, 0, 1) if state == "warn" else 0.0
	if state == "recover": inflation = exp(-state_time * 8.0)
	throat.scale = Vector3(1 + inflation * .20, 1 + inflation * .22, 1 + inflation * .25)
	spine.position.y = .83 + sin(elapsed * PI) * .012 + absf(sin(gait)) * stride * .015
	head.rotation.x = -.045 * inflation + hit_flash * .08
	if state == "recover": head.rotation.x += .08 * sin(clampf(state_time / 1.25, 0, 1) * PI)
	for i in range(limbs.size()):
		var wave := sin(gait + (PI if i in [1, 2] else 0)) * stride
		limbs[i].rotation.x = wave * .16
		knees[i].rotation.x = -wave * .12
		feet[i].rotation.x = -wave * .04
	for i in range(controls.size()):
		var desired := skeleton.global_transform.affine_inverse() * controls[i].global_transform * inverse_bind[i] * bone_rest[i]
		skeleton.set_bone_global_pose_override(i, desired, 1.0, true)
	pulse.visible = state == "warn" or (state == "recover" and state_time < .45)
	if pulse.visible:
		pulse.scale = Vector3(boom_radius, 1, boom_radius)
		pulse.material_override.albedo_color.a = (.25 + inflation * .4) if state == "warn" else (1 - state_time / .45) * .65
