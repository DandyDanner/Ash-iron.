extends Node3D
## A collision-aware chase camera and one shared articulated Willow Scout body.
const Traveler = preload("res://scripts/traveler_model.gd")
const Profile = preload("res://scripts/character_profile.gd")
const Archery = preload("res://scripts/archery_art.gd")
var player: CharacterBody3D
var avatar: Node3D
var arm: SpringArm3D
var third_camera: Camera3D
var third_person := true
var facing := PI
var held := {}
var held_bow: Node3D
var bow_strings: Dictionary
var drawn_arrow: Node3D
var back_bow: Node3D
var quiver: Node3D
var arrow_feathers: Node3D
var first_torch_light: OmniLight3D
var third_torch_light: OmniLight3D

func _ready() -> void:
	player = get_parent()
	name = "ViewRig"
	avatar = Traveler.new()
	avatar.name = "ScoutAvatar"
	avatar.position.y = -0.9
	avatar.scale = Vector3.ONE * 0.87
	add_child(avatar)
	avatar.rebuild(Profile.load_profile())
	facing = player.rotation.y + PI
	avatar.rotation.y = PI
	arm = SpringArm3D.new()
	arm.name = "CameraArm"
	arm.position = Vector3(0, 0.95, 0)
	arm.spring_length = 3.8
	arm.margin = 0.2
	arm.collision_mask = 1
	var sphere := SphereShape3D.new()
	sphere.radius = 0.25
	arm.shape = sphere
	arm.add_excluded_object(player.get_rid())
	add_child(arm)
	third_camera = Camera3D.new()
	third_camera.name = "ThirdPersonCamera"
	third_camera.fov = 65
	third_camera.near = 0.08
	third_camera.cull_mask = 1 | 4
	arm.add_child(third_camera)
	player.camera.cull_mask = 1 | 2
	for mesh in player.camera.find_children("*", "MeshInstance3D", true, false):
		mesh.layers = 2
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for pair in [["stone_axe", "Tool"], ["stone_pickaxe", "Pickaxe"], ["torch", "Torch"]]:
		var tool: Node3D = player.axe.get_node(pair[1]).duplicate()
		tool.name = pair[0]
		avatar.tool_grip.add_child(tool)
		tool.scale = Vector3.ONE * 0.72
		tool.position = Vector3.ZERO
		tool.rotation = Vector3(0, PI / 2, 0) # The cutting edge leads forward in the vertical chopping plane.
		tool.hide()
		held[pair[0]] = tool
	first_torch_light = player.axe.get_node("Torch/WarmLight")
	third_torch_light = held.torch.get_node("WarmLight")
	held_bow = Traveler.joint(avatar.left_hand, "HeldBow", Vector3.ZERO)
	held_bow.scale = Vector3.ONE * 0.82
	bow_strings = Archery.bow(held_bow)
	var bow_fingers := Traveler.gripping_fingers(held_bow, avatar.left_hand.get_child(0).material_override.albedo_color)
	bow_fingers.scale = Vector3.ONE * 1.12
	drawn_arrow = Archery.arrow(held_bow)
	back_bow = Traveler.joint(avatar.body, "StowedBow", Vector3(-0.12, 1.30, -0.24))
	back_bow.rotation.z = -0.25
	back_bow.scale = Vector3.ONE * 0.78
	Archery.bow(back_bow)
	quiver = Traveler.joint(avatar.body, "Quiver", Vector3(0.14, 1.25, -0.25))
	quiver.rotation.z = -0.25
	Traveler.cylinder(quiver, Vector3.ZERO, 0.073, 0.43, Color("815d3e"), 0.085)
	Traveler.cylinder(quiver, Vector3(0, 0.205, 0), 0.091, 0.05, Color("bd9862"))
	arrow_feathers = Traveler.joint(quiver, "Arrows", Vector3.ZERO)
	for i in range(4):
		Traveler.cylinder(arrow_feathers, Vector3((i % 2 - 0.5) * 0.05, 0.27, (i / 2.0 - 0.5) * 0.035), 0.007, 0.32, Color("c9b482"))
		Traveler.oval(arrow_feathers, Vector3((i % 2 - 0.5) * 0.05, 0.40, (i / 2.0 - 0.5) * 0.035), Vector3(0.027, 0.08, 0.02), Color("e5ddc0"))
	for mesh in avatar.find_children("*", "MeshInstance3D", true, false):
		mesh.layers = 4
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	set_mode(true)

func set_mode(enabled: bool) -> void:
	third_person = enabled
	if enabled:
		third_camera.make_current()
	else:
		player.camera.make_current()
	_sync_equipment()

func _sync_equipment() -> void:
	avatar.set_tool_grip(player.equipped_item in held)
	for item in held:
		held[item].visible = player.equipped_item == item
	held_bow.visible = player.equipped_item == "bow"
	avatar.left_hand.get_node("OpenFingers").visible = not held_bow.visible
	back_bow.visible = player.inventory.count("bow") > 0 and not held_bow.visible
	quiver.visible = player.inventory.count("bow") > 0 or player.inventory.count("arrow") > 0
	arrow_feathers.visible = player.inventory.count("arrow") > 0
	first_torch_light.visible = not third_person
	third_torch_light.visible = third_person
	var pull: float = player.bow.charge()
	var center := Archery.pose_bow(bow_strings, pull)
	if held_bow.visible:
		avatar.reach_hand(0, avatar.body.to_global(Vector3(-0.13, 1.38, 0.46)), Vector3(-1, -0.4, 0))
		# Cancel the arm's rotation: limbs stay upright and the arrow points ahead.
		held_bow.global_basis = avatar.global_basis.orthonormalized() * Basis(Vector3.UP, PI) * Basis.from_scale(Vector3.ONE * 0.82 * avatar.scale.x)
		if player.bow.drawing:
			avatar.reach_hand(1, held_bow.to_global(center), Vector3(1, 0.1, -0.3))
	drawn_arrow.visible = player.bow.drawing
	drawn_arrow.position = center + Vector3(0, 0, -0.39)

func _physics_process(delta: float) -> void:
	arm.rotation.x = player.camera.rotation.x
	arm.spring_length = lerpf(arm.spring_length, 2.25 if player.bow.drawing else 3.8, minf(1, delta * 8))
	var horizontal := Vector3(player.velocity.x, 0, player.velocity.z) if player.controls_active else Vector3.ZERO
	if player.bow.drawing or player.axe.elapsed >= 0:
		facing = lerp_angle(facing, player.rotation.y + PI, minf(1, delta * 16))
	elif horizontal.length() > 0.2:
		facing = lerp_angle(facing, atan2(horizontal.x, horizontal.z), minf(1, delta * 12))
	avatar.global_rotation.y = facing
	avatar.animate_movement(delta, horizontal.length(), player.is_on_floor(), player.velocity.y, player.equipped_item, player.axe.elapsed, player.bow.charge())
	# If a wall brings the chase camera into the body, fade the body by excluding its render layer.
	third_camera.cull_mask = 1 | 4 if arm.get_hit_length() > 0.65 else 1
	_sync_equipment()

func aim_point(mask: int = 3) -> Vector3:
	var source: Camera3D = third_camera if third_person else player.camera
	var origin := source.global_position
	var end := origin - source.global_basis.z * 80
	var query := PhysicsRayQueryParameters3D.create(origin, end, mask, [player.get_rid()])
	query.collide_with_areas = (mask & 2) != 0
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return hit.position if not hit.is_empty() else end

func shot_direction(mask: int = 1) -> Vector3:
	var forward: Vector3 = -player.camera.global_basis.z
	if not third_person:
		return forward
	var offset: Vector3 = aim_point(mask) - player.camera.global_position
	return offset.normalized() if offset.dot(forward) > 0.1 else forward
