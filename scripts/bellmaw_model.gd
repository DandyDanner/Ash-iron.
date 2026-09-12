extends Node3D
## Largest creature from the new Bellmaw sculpt, colored and weighted in Blender. Gameplay owns timing and collision.
const Attacks = preload("res://scripts/bellmaw_attacks.gd")
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
var swipe_side := 1.0
var limb_rest: Array[Vector3] = []
var swipe_marker: MeshInstance3D
var dust: Node3D
var dust_puffs: Array[MeshInstance3D] = []
var dust_material: StandardMaterial3D

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
			limb_rest.append(upper.position)
			knees.append(lower)
			feet.append(foot)
			named[key + "Upper"] = upper
			named[key + "Lower"] = lower
			named[key + "Foot"] = foot
	var imported: Node3D = SCENE.instantiate()
	body.add_child(imported)
	# The sculpt uses portable vertex colors; Godot's glTF import leaves this flag off.
	for mesh in imported.find_children("*", "MeshInstance3D", true, false):
		for surface in range(mesh.mesh.get_surface_count()):
			var source = mesh.get_active_material(surface)
			if source is StandardMaterial3D:
				var material: StandardMaterial3D = source.duplicate()
				material.vertex_color_use_as_albedo = true
				material.vertex_color_is_srgb = false
				mesh.set_surface_override_material(surface, material)
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
	_make_attack_effects()
	pose(0, 0, "idle", 0, 0)

func pose(delta: float, speed: float, state: String, state_time: float, hit_flash: float) -> void:
	elapsed += delta
	var walking := state in ["approach", "return"] and speed > .05
	stride = move_toward(stride, minf(speed / 3.3, 1.0) if walking else 0.0, delta * 7.0)
	# Warning plants the feet immediately so the attack remains readable.
	if not walking: stride = 0.0
	gait += delta * maxf(speed, .2) * 2.1
	var inflation := clampf(state_time / 1.2, 0, 1) if state == "warn" else 0.0
	if state == "recover": inflation = exp(-state_time * 8.0)
	throat.scale = Vector3(1 + inflation * .20, 1 + inflation * .22, 1 + inflation * .25)
	spine.rotation = Vector3.ZERO
	spine.position = Vector3(0, .83, -.05)
	head.rotation = Vector3.ZERO
	spine.position.y = .83 + sin(elapsed * PI) * .012 + absf(sin(gait)) * stride * .015
	head.rotation.x = -.045 * inflation + hit_flash * .08
	if state == "recover": head.rotation.x += .08 * sin(clampf(state_time / 1.25, 0, 1) * PI)
	for i in range(limbs.size()):
		var wave := sin(gait + (PI if i in [1, 2] else 0)) * stride
		limbs[i].position = limb_rest[i]
		limbs[i].rotation = Vector3(wave * .16, 0, 0)
		knees[i].rotation.x = -wave * .12
		feet[i].rotation.x = -wave * .04
	_pose_attack(state, state_time)
	_pose_effects(state, state_time)
	for i in range(controls.size()):
		var desired := skeleton.global_transform.affine_inverse() * controls[i].global_transform * inverse_bind[i] * bone_rest[i]
		skeleton.set_bone_global_pose_override(i, desired, 1.0, true)
	pulse.visible = state == "warn" or (state == "recover" and state_time < .45)
	if pulse.visible:
		pulse.scale = Vector3(boom_radius, 1, boom_radius)
		pulse.material_override.albedo_color.a = (.25 + inflation * .4) if state == "warn" else (1 - state_time / .45) * .65

func _plant_limb(index: int) -> void:
	# Counter the torso tilt at the shoulder/hip so supporting paws stay in place.
	var side := -1.0 if index < 2 else 1.0
	var z := .68 if index in [0, 2] else -.87
	limbs[index].position = spine.transform.affine_inverse() * Vector3(side * .64, .83, z)
	limbs[index].quaternion = spine.quaternion.inverse()
	knees[index].rotation = Vector3.ZERO
	feet[index].rotation = Vector3.ZERO

func _pose_attack(state: String, time: float) -> void:
	if state == "warn":
		var lift := Attacks.slam_lift(time)
		spine.rotation.x = -.28 * lift
		var pivot := Vector3(0, .75, -.9)
		spine.position = pivot + Basis(Vector3.RIGHT, spine.rotation.x) * (Vector3(0, .83, -.05) - pivot)
		head.rotation.x -= .10 * lift
		for i in [1, 3]: _plant_limb(i)
		for i in [0, 2]:
			limbs[i].rotation.x = -.55 * lift
			knees[i].rotation.x = .60 * lift
			feet[i].rotation.x = -.05 * lift
	elif state == "recover":
		var dip := sin(clampf(time / 1.25, 0, 1) * PI)
		spine.position.y = .83 - .07 * dip
		spine.rotation.x = .055 * dip
		head.rotation.x += .12 * dip
		for i in range(4): _plant_limb(i)
		# Visible exhausted breaths while the throat is vulnerable.
		var breath := sin(time * 13.0) * .025 * dip
		throat.scale += Vector3.ONE * breath
	elif state in ["swipe_warn", "swipe", "swipe_recover"]:
		var active := 0 if swipe_side < 0 else 2
		var windup := smoothstep(0, .65, time) if state == "swipe_warn" else 1.0
		var sweep := smoothstep(0, Attacks.SWIPE_SWING, time) if state == "swipe" else 0.0
		var release := 1.0 - smoothstep(0, Attacks.SWIPE_RECOVERY, time) if state == "swipe_recover" else 1.0
		if state == "swipe_recover": sweep = 1.0
		spine.rotation.z = -swipe_side * .055 * windup * release
		head.rotation.y = swipe_side * lerpf(-.10, .14, sweep) * windup * release
		for i in range(4):
			if i != active: _plant_limb(i)
		limbs[active].rotation.x = lerpf(-.85, -.25, sweep) * windup * release
		limbs[active].rotation.z = swipe_side * lerpf(.55, -.65, sweep) * windup * release
		limbs[active].position.y += .16 * windup * (1.0 - sweep) * release
		limbs[active].position.z += .20 * sin(sweep * PI) * release
		knees[active].rotation.x = lerpf(.65, .20, sweep) * windup * release
		feet[active].rotation.x = .10 * windup * release

func _make_attack_effects() -> void:
	swipe_marker = MeshInstance3D.new()
	swipe_marker.name = "SwipeWarningSector"
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(32):
		var a := lerpf(Attacks.SWIPE_MIN_ANGLE, Attacks.SWIPE_MAX_ANGLE, float(i) / 32)
		var b := lerpf(Attacks.SWIPE_MIN_ANGLE, Attacks.SWIPE_MAX_ANGLE, float(i + 1) / 32)
		mesh.surface_add_vertex(Vector3.ZERO)
		mesh.surface_add_vertex(Vector3(sin(a), 0, cos(a)) * Attacks.SWIPE_RADIUS)
		mesh.surface_add_vertex(Vector3(sin(b), 0, cos(b)) * Attacks.SWIPE_RADIUS)
	mesh.surface_end()
	swipe_marker.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(.95, .34, .12, .24)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	swipe_marker.material_override = material
	swipe_marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	swipe_marker.position.y = .105
	add_child(swipe_marker)
	dust = Node3D.new()
	dust.name = "PawImpactDust"
	add_child(dust)
	dust_material = StandardMaterial3D.new()
	dust_material.albedo_color = Color(.48, .39, .25, .4)
	dust_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dust_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var puff_mesh := SphereMesh.new()
	puff_mesh.radius = .5
	puff_mesh.height = 1.0
	puff_mesh.radial_segments = 8
	puff_mesh.rings = 4
	for i in range(16):
		var puff := MeshInstance3D.new()
		puff.mesh = puff_mesh
		puff.material_override = dust_material
		puff.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		dust.add_child(puff)
		dust_puffs.append(puff)

func _pose_effects(state: String, time: float) -> void:
	swipe_marker.visible = state == "swipe_warn"
	swipe_marker.scale.x = swipe_side
	if swipe_marker.visible:
		swipe_marker.material_override.albedo_color.a = .16 + .16 * clampf(time / Attacks.SWIPE_WARNING, 0, 1)
	dust.visible = state == "recover" and time < .55
	if not dust.visible: return
	var progress := clampf(time / .55, 0, 1)
	dust_material.albedo_color.a = .42 * (1.0 - progress)
	for i in range(dust_puffs.size()):
		var angle := TAU * float(i % 8) / 8
		var side := -1.0 if i < 8 else 1.0
		var origin := Vector3(side * .84, .025, .81) * body.scale.x
		dust_puffs[i].position = origin + Vector3(cos(angle), 0, sin(angle)) * (.12 + progress * .75)
		dust_puffs[i].position.y += .04 + sin(progress * PI) * .14
		var size := .16 + progress * .38
		dust_puffs[i].scale = Vector3(size, size * .55, size)
