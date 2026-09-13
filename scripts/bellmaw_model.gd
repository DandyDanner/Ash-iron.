extends Node3D
## Native-textured Rodin Bellmaw, weighted in Blender. Gameplay owns timing and collision.
const Attacks = preload("res://scripts/bellmaw_attacks.gd")
const M = preload("res://scripts/traveler_model.gd")
const SCENE = preload("res://assets/creatures/bellmaw.glb")
var boom_radius := Attacks.SLAM_RADIUS
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
var blink_meshes: Array[MeshInstance3D] = []
var blink_indices: Array[int] = []
var blink_amount := 0.0
var blink_clock := 0.0
var next_blink := 3.4
var blink_number := 0
var previous_pose: Array[Transform3D] = []
var transition_pose: Array[Transform3D] = []
var previous_walking := false
var transition_time := .18

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
	# Preserve the new native PBR maps. Legacy sculpt colors remain supported for offline comparisons.
	for mesh in imported.find_children("*", "MeshInstance3D", true, false):
		for surface in range(mesh.mesh.get_surface_count()):
			var source = mesh.get_active_material(surface)
			if source is StandardMaterial3D and source.resource_name != "Bellmaw Native PBR":
				var material: StandardMaterial3D = source.duplicate()
				material.vertex_color_use_as_albedo = true
				material.vertex_color_is_srgb = false
				mesh.set_surface_override_material(surface, material)
	for mesh: MeshInstance3D in imported.find_children("*", "MeshInstance3D", true, false):
		var index := mesh.find_blend_shape_by_name("Blink")
		if index >= 0:
			blink_meshes.append(mesh)
			blink_indices.append(index)
	# Combat state drives the rig; stop optional source clips to avoid competing poses.
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
	var walking := state in ["approach", "return", "roam"] and speed > .05
	stride = move_toward(stride, minf(speed / 3.3, 1.0) if walking else 0.0, delta * 7.0)
	# Warning plants the feet immediately so the attack remains readable.
	if not walking: stride = 0.0
	# Advance by distance: slow patrol steps stay slow, blocked movement stops the gait.
	gait += delta * speed / 2.25 * TAU
	var inflation := clampf(state_time / 1.2, 0, 1) if state == "warn" else 0.0
	if state == "recover": inflation = exp(-state_time * 8.0)
	throat.scale = Vector3(1 + inflation * .20, 1 + inflation * .22, 1 + inflation * .25)
	spine.rotation = Vector3.ZERO
	spine.position = Vector3(0, .83, -.05)
	head.rotation = Vector3.ZERO
	spine.position.y = .83 + sin(elapsed * PI) * .012 + absf(sin(gait)) * stride * .015
	head.rotation.x = -.045 * inflation + hit_flash * .08
	if state == "idle":
		head.rotation.y = sin(elapsed * .47) * .04
	if state == "recover": head.rotation.x += .08 * sin(clampf(state_time / 1.25, 0, 1) * PI)
	for i in range(limbs.size()):
		limbs[i].position = limb_rest[i]
		limbs[i].rotation = Vector3.ZERO
		knees[i].rotation = Vector3.ZERO
		feet[i].rotation = Vector3.ZERO
	if walking:
		_pose_walk()
	else:
		for i in range(4): _plant_limb(i)
	_pose_blink(delta, state)
	_pose_attack(state, state_time)
	_blend_locomotion_transition(delta, walking)
	_pose_effects(state, state_time)
	for i in range(controls.size()):
		var desired := skeleton.global_transform.affine_inverse() * controls[i].global_transform * inverse_bind[i] * bone_rest[i]
		skeleton.set_bone_global_pose_override(i, desired, 1.0, true)
	pulse.visible = state == "warn" or (state == "recover" and state_time < .45)
	if pulse.visible:
		pulse.scale = Vector3(boom_radius, 1, boom_radius)
		pulse.material_override.albedo_color.a = (.25 + inflation * .4) if state == "warn" else (1 - state_time / .45) * .65

func _blend_locomotion_transition(delta: float, walking: bool) -> void:
	# Blend the solved joint pose when starting/stopping, including walking into
	# a warning. This also eases the torso height instead of snapping it down.
	# Zero-delta poses are explicit preview/test seeks to the requested pose.
	if delta <= 0:
		transition_time = .18
	elif walking != previous_walking and not previous_pose.is_empty():
		transition_pose = previous_pose.duplicate()
		transition_time = 0
	transition_time = minf(.18, transition_time + delta)
	if transition_time < .18 and not transition_pose.is_empty():
		var blend := smoothstep(0, .18, transition_time)
		for i in range(controls.size()):
			if controls[i] == body: continue # Runtime owns creature scale and placement.
			controls[i].transform = transition_pose[i].interpolate_with(controls[i].transform, blend)
	previous_walking = walking
	previous_pose.clear()
	for control in controls: previous_pose.append(control.transform)

func _foot_rest(index: int) -> Vector3:
	return Vector3(-.84 if index < 2 else .84, .085, .81 if index in [0, 2] else -.74)

func _solve_limb(index: int, target: Vector3) -> void:
	# Analytic two-bone solve in body space. Keep the shoulder attached to the
	# torso and bend the elbow instead of translating the entire leg to its goal.
	var upper := limbs[index]
	var lower := knees[index]
	var foot := feet[index]
	upper.position = limb_rest[index]
	upper.quaternion = Quaternion.IDENTITY
	lower.quaternion = Quaternion.IDENTITY
	foot.quaternion = Quaternion.IDENTITY
	var shoulder := body.to_local(upper.global_position)
	var rest_elbow := body.to_local(lower.global_position)
	var reach := target - shoulder
	var first_length := lower.position.length()
	var second_length := foot.position.length()
	var distance := clampf(reach.length(), absf(first_length - second_length) + .0001, first_length + second_length - .0001)
	var direction := reach.normalized() if reach.length() > .0001 else Vector3.DOWN
	var along := (first_length * first_length - second_length * second_length + distance * distance) / (2 * distance)
	var height := sqrt(maxf(0, first_length * first_length - along * along))
	# Keep the elbow bending in the source model's anatomical plane, using
	# its rest elbow offset as a stable bend direction throughout the paw arc.
	var rest_direction := (body.to_local(foot.global_position) - shoulder).normalized()
	var pole := (rest_elbow - shoulder).slide(rest_direction).normalized()
	var perpendicular := pole - direction * pole.dot(direction)
	if perpendicular.length_squared() < .00001:
		perpendicular = (rest_elbow - shoulder).slide(direction)
	var elbow := shoulder + direction * along + perpendicular.normalized() * height
	var desired_upper: Vector3 = upper.get_parent().to_local(body.to_global(elbow)) - upper.position
	upper.quaternion = Quaternion(lower.position.normalized(), desired_upper.normalized())
	var reached := shoulder + direction * distance
	var desired_lower := upper.to_local(body.to_global(reached)) - lower.position
	lower.quaternion = Quaternion(foot.position.normalized(), desired_lower.normalized())
	# Paws stay level instead of rolling sideways with the shoulder swing.
	foot.quaternion = (body.global_basis.orthonormalized().inverse() * lower.global_basis.orthonormalized()).get_rotation_quaternion().inverse()

func _plant_limb(index: int, _knee_bend: float = 0.0) -> void:
	_solve_limb(index, _foot_rest(index))

func _pose_walk() -> void:
	# Four-beat walk: each paw swings for one quarter of a cycle, leaving three
	# supporting paws. The stance moves back at the creature's forward speed.
	var offsets := [0.0, .75, .5, .25]
	spine.position.y = .745 + sin(gait * 2) * .008
	var length := 2.25 / maxf(body.scale.x, 1.0)
	var travel := length * .75
	for i in range(4):
		var phase := fposmod(gait / TAU + offsets[i], 1.0)
		var target := _foot_rest(i)
		if phase < .75:
			target.z += lerpf(travel * .5, -travel * .5, phase / .75)
		else:
			var swing := (phase - .75) / .25
			target.z += lerpf(-travel * .5, travel * .5, smoothstep(0, 1, swing))
			target.y += sin(swing * PI) * .11
		# Approach/return use the same planted cadence as a calm patrol.
		_solve_limb(i, target)
	head.rotation.y += sin(gait * .5) * .025
	head.rotation.x += sin(gait) * .018

func _pose_blink(delta: float, state: String) -> void:
	blink_clock += delta
	# Avoid closing the eyes during a warning or hit; blinks resume naturally later.
	if state in ["warn", "swipe_warn", "swipe", "dead"]:
		blink_clock = minf(blink_clock, next_blink - .01)
		blink_amount = 0.0
	else:
		var time := blink_clock - next_blink
		blink_amount = smoothstep(0, .07, time) * (1.0 - smoothstep(.10, .23, time))
		if time >= .23:
			blink_number += 1
			blink_clock = 0.0
			next_blink = 3.2 + fposmod(float(blink_number) * 1.618, 2.8)
	for i in range(blink_meshes.size()):
		blink_meshes[i].set_blend_shape_value(blink_indices[i], blink_amount)

func _pose_attack(state: String, time: float) -> void:
	if state == "warn":
		var lift := Attacks.slam_lift(time)
		var brace := Attacks.slam_brace(time)
		spine.rotation.x = -.31 * lift + .045 * brace
		var pivot := Vector3(0, .75, -.9)
		spine.position = pivot + Basis(Vector3.RIGHT, spine.rotation.x) * (Vector3(0, .83, -.05) - pivot)
		spine.position.y -= .055 * brace
		spine.position.z -= .075 * brace
		head.rotation.x += .075 * brace - .13 * lift
		for i in [1, 3]: _plant_limb(i, .13 * brace + .035 * lift)
		for i in [0, 2]:
			_plant_limb(i, .08 * brace)
			var release := smoothstep(.18, .38, time)
			var lifted_rotation := Quaternion.from_euler(Vector3(-.62 * lift, 0, (-.045 if i == 0 else .045) * lift))
			limbs[i].position = limbs[i].position.lerp(limb_rest[i], release)
			limbs[i].quaternion = limbs[i].quaternion.slerp(lifted_rotation, release)
			knees[i].rotation.x = lerpf(knees[i].rotation.x, .68 * lift, release)
			feet[i].rotation.x = lerpf(feet[i].rotation.x, -.11 * lift, release)
	elif state == "recover":
		var impact := 1.0 - smoothstep(0, .18, time)
		var dip := sin(clampf(time / 1.25, 0, 1) * PI)
		spine.position.y = .83 - .095 * impact - .06 * dip
		spine.position.z = -.05 + .035 * impact
		spine.rotation.x = .095 * impact + .06 * dip
		head.rotation.x += .16 * impact + .13 * dip
		for i in range(4):
			var bend := (.16 if i in [0, 2] else .08) * impact + .04 * dip
			_plant_limb(i, bend)
		# Visible exhausted breaths while the throat is vulnerable.
		var breath := sin(time * 13.0) * .025 * dip
		throat.scale += Vector3.ONE * breath
	elif state in ["swipe_warn", "swipe", "swipe_recover"]:
		var active := 0 if swipe_side < 0 else 2
		var windup := smoothstep(0, .68, time) if state == "swipe_warn" else 1.0
		var sweep := Attacks.swipe_sweep(time) if state == "swipe" else 0.0
		var release := 1.0 - smoothstep(.10, .92, time) if state == "swipe_recover" else 1.0
		if state == "swipe_recover": sweep = 1.0
		var weight := windup * release
		spine.position.x = -swipe_side * .045 * weight
		spine.position.y -= .085 * weight
		spine.rotation.z = swipe_side * .035 * weight
		spine.rotation.y = swipe_side * lerpf(-.04, .07, sweep) * weight
		head.rotation.y = swipe_side * lerpf(-.10, .12, sweep) * weight
		for i in range(4):
			if i != active: _plant_limb(i)
		# Lift beside the chest, sweep forwards/inwards, then settle the paw back.
		# The shoulder never leaves its socket; the elbow solves the whole arc.
		var raised := Vector3(swipe_side * 1.10, .43, .69)
		var follow := Vector3(swipe_side * .34, .23, 1.11)
		var target := raised.lerp(follow, sweep)
		target.z += sin(sweep * PI) * .17
		target.y += sin(sweep * PI) * .045
		target = _foot_rest(active).lerp(target, weight)
		_solve_limb(active, target)
		# An airborne paw follows the forearm; forcing a flat planted wrist here
		# over-flexes the carpal joint and collapses the generated skin.
		feet[active].quaternion = feet[active].quaternion.slerp(Quaternion.IDENTITY, .65 * weight)

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
		var foot_index := 0 if i < 8 else 2
		var origin := dust.to_local(feet[foot_index].global_position)
		origin.y = .025
		dust_puffs[i].position = origin + Vector3(cos(angle), 0, sin(angle)) * (.12 + progress * .75)
		dust_puffs[i].position.y += .04 + sin(progress * PI) * .14
		var size := .16 + progress * .38
		dust_puffs[i].scale = Vector3(size, size * .55, size)
