extends RefCounted
## Runtime skin driver for the four Blender traveler exports.
const Profile = preload("res://scripts/character_profile.gd")
const PATHS := ["willow_scout", "hearthland_ranger", "ridge_wayfarer", "ember_forager"]
const SCALES := [Vector3(1, 1, 1), Vector3(1.10, 1.045, 1.07), Vector3(1.13, 1.055, 1.06), Vector3(.97, .99, .99)]
static var scenes: Dictionary = {}
var skeleton: Skeleton3D
var host: Node3D
var joints: Array[Node3D] = []
var inverse_bind: Array[Transform3D] = []
var bone_rest: Array[Transform3D] = []
var finger_meshes: Array[MeshInstance3D] = []

func build(owner_model: Node3D, design: int) -> void:
	host = owner_model
	var size: Vector3 = SCALES[design] * 1.14
	host.body = host.joint(host, "AuthoredTraveler", Vector3.ZERO)
	host.body.set_meta("traveler_design", design)
	if not scenes.has(design):
		scenes[design] = load("res://assets/characters/" + PATHS[design] + ".glb")
	var imported: Node3D = scenes[design].instantiate()
	imported.name = "TravelerMesh"
	host.body.add_child(imported)
	skeleton = imported.find_children("*", "Skeleton3D", true, false)[0]
	# Each export's bone rests say where its joints pivot, so a scanned figure keeps its own proportions.
	# The four Blender travelers rest exactly on the shared reference points used as fallbacks below.
	var pivots := {}
	for i in range(skeleton.get_bone_count()):
		pivots[skeleton.get_bone_name(i)] = skeleton.get_bone_global_rest(i).origin
	host.torso = host.joint(host.body, "Torso", pivots.get("Torso", Vector3(0, 1.0, 0) * size))
	host.head = host.joint(host.body, "Head", pivots.get("Head", Vector3(0, 1.53, 0) * size))
	host.cape = host.joint(host.body, "Cape", pivots.get("Cape", Vector3(0, 1.50, 0) * size))
	var named := {"Body": host.body, "Torso": host.torso, "Head": host.head, "Cape": host.cape}
	for side in [-1.0, 1.0]:
		var prefix := "Left" if side < 0 else "Right"
		var hip: Vector3 = pivots.get(prefix + "Leg", Vector3(side * .10, .96, 0) * size)
		var knee_at: Vector3 = pivots.get(prefix + "Knee", Vector3(side * .10, .54, .007) * size)
		var leg: Node3D = host.joint(host.body, prefix + "Leg", hip)
		var knee: Node3D = host.joint(leg, "Knee", knee_at - hip)
		host.legs.append(leg)
		host.knees.append(knee)
		named[prefix + "Leg"] = leg
		named[prefix + "Knee"] = knee
		var shoulder: Vector3 = pivots.get(prefix + "Arm", Vector3(side * .151, 1.442, 0) * size)
		var elbow_at: Vector3 = pivots.get(prefix + "Elbow", Vector3(side * .267, 1.188, .005) * size)
		var hand_at: Vector3 = pivots.get(prefix + "Hand", Vector3(side * .310, .931, .018) * size)
		var upper: Node3D = host.joint(host.body, prefix + "Arm", shoulder)
		upper.quaternion = Quaternion(Vector3.DOWN, (elbow_at - shoulder).normalized())
		var elbow: Node3D = host.joint(upper, "Elbow", Vector3.DOWN * shoulder.distance_to(elbow_at))
		elbow.quaternion = upper.quaternion.inverse() * Quaternion(Vector3.DOWN, (hand_at - elbow_at).normalized())
		var hand: Node3D = host.joint(elbow, "Hand", Vector3.DOWN * elbow_at.distance_to(hand_at))
		host.arms.append(upper)
		host.forearms.append(elbow)
		host.arm_rest.append(upper.quaternion)
		host.forearm_rest.append(elbow.quaternion)
		named[prefix + "Arm"] = upper
		named[prefix + "Elbow"] = elbow
		named[prefix + "Hand"] = hand
		var fingers: Node3D = host.joint(hand, "OpenFingers", Vector3.ZERO)
		if side < 0:
			host.left_hand = hand
		else:
			host.right_hand = hand
			host.open_right_fingers = fingers
			host.tool_grip = host.joint(hand, "ToolGrip", Vector3(0, -.02, .045))
			host.tool_grip.rotation.x = 1.35
			host.closed_right_fingers = host.gripping_fingers(host.tool_grip, host.skin_color)
			host.closed_right_fingers.hide()
	for mesh in imported.find_children("*", "MeshInstance3D", true, false):
		# Godot's importer retains COLOR_0 but does not always enable it on the material.
		for surface in range(mesh.mesh.get_surface_count()):
			var material: StandardMaterial3D = mesh.get_active_material(surface)
			if material.resource_name in ["Game Skin", "Game Fabric"]:
				material = preload("res://scripts/surface_detail.gd").refine(material, "skin" if material.resource_name == "Game Skin" else "fabric")
			material.vertex_color_use_as_albedo = true
			material.vertex_color_is_srgb = false
			mesh.set_surface_override_material(surface, material)
		if "Fingers" in mesh.name:
			finger_meshes.append(mesh)
	for i in range(skeleton.get_bone_count()):
		var bone := skeleton.get_bone_name(i)
		var node: Node3D = named.get(bone, host.body)
		joints.append(node)
		inverse_bind.append((skeleton.global_transform.affine_inverse() * node.global_transform).affine_inverse())
		bone_rest.append(skeleton.get_bone_global_rest(i))
	sync()

func sync() -> void:
	if not is_instance_valid(skeleton): return
	for i in range(joints.size()):
		var desired := skeleton.global_transform.affine_inverse() * joints[i].global_transform * inverse_bind[i] * bone_rest[i]
		skeleton.set_bone_global_pose_override(i, desired, 1.0, true)
	for mesh in finger_meshes:
		mesh.visible = host.open_right_fingers.visible if "Right" in mesh.name else host.left_hand.get_node("OpenFingers").visible
