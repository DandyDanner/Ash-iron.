extends Node3D
## Shared runtime driver for the native Rodin boar, deer and wolf skins.
## The GLBs keep their authored UV/PBR data; this node only drives prototype bones.

const ASSETS := {
	"boar": "res://assets/creatures/bristleback.glb",
	"deer": "res://assets/creatures/meadow_buck.glb",
	"wolf": "res://assets/creatures/hollow_wolf.glb",
}
const DISPLAY_NAMES := {"boar": "Bristleback", "deer": "Meadow Buck", "wolf": "Hollow Wolf"}
const MOVEMENT_STATES := {
	"boar": ["idle", "approach", "warn", "charge", "recover"],
	"deer": ["idle", "walk", "trot", "alert", "flee"],
	"wolf": ["idle", "walk", "trot", "alert", "flee"],
}

@export_enum("boar", "deer", "wolf") var species := "boar"
var body: Node3D
var head: Node3D
var legs: Array[Node3D] = []
var skeleton: Skeleton3D
var meshes: Array[MeshInstance3D] = []
var bone_indices := {}
var bone_rests: Array[Transform3D] = []
var elapsed := 0.0
var state_elapsed := 0.0
var previous_state := ""


func _ready() -> void:
	if not ASSETS.has(species):
		push_error("Unknown native wildlife species: " + species)
		return
	body = load(ASSETS[species]).instantiate()
	body.name = DISPLAY_NAMES[species] + "NativeAsset"
	add_child(body)
	var skeletons := body.find_children("*", "Skeleton3D", true, false)
	if skeletons.is_empty():
		push_error("Native wildlife asset has no Skeleton3D: " + species)
		return
	skeleton = skeletons[0]
	for i in range(skeleton.get_bone_count()):
		bone_indices[String(skeleton.get_bone_name(i))] = i
		bone_rests.append(skeleton.get_bone_rest(i))
	for node in body.find_children("*", "MeshInstance3D", true, false):
		meshes.append(node)
	head = _attachment("Head", "HeadPivot")
	for name in ["FrontLUpper", "HindLUpper", "FrontRUpper", "HindRUpper"]:
		legs.append(_attachment(name, name + "Pivot"))
	pose(0.0, 0.0, "idle", 0.0)


func _attachment(bone_name: String, node_name: String) -> BoneAttachment3D:
	var attachment := BoneAttachment3D.new()
	attachment.name = node_name
	attachment.bone_name = bone_name
	skeleton.add_child(attachment)
	return attachment


func _bone_rotation(name: String, rotation: Vector3) -> void:
	var index: int = int(bone_indices.get(name, -1))
	if index >= 0:
		var rest_rotation := bone_rests[index].basis.get_rotation_quaternion()
		skeleton.set_bone_pose_rotation(index, rest_rotation * Quaternion.from_euler(rotation))


func _bone_position(name: String, offset: Vector3) -> void:
	var index: int = int(bone_indices.get(name, -1))
	if index >= 0:
		skeleton.set_bone_pose_position(index, bone_rests[index].origin + offset)


func _leg_pose(name: String, wave: float, upper_amount: float, lower_amount: float, paw_amount: float) -> void:
	_bone_rotation(name + "Upper", Vector3(wave * upper_amount, 0, 0))
	_bone_rotation(name + "Lower", Vector3(-wave * lower_amount + absf(wave) * lower_amount * .20, 0, 0))
	_bone_rotation(name + "Paw", Vector3(-wave * paw_amount, 0, 0))


func pose(delta: float, speed: float, state: String, hit_flash: float) -> void:
	if not is_instance_valid(skeleton):
		return
	elapsed += delta
	if state != previous_state:
		previous_state = state
		state_elapsed = 0.0
	else:
		state_elapsed += delta
	skeleton.reset_bone_poses()
	body.position = Vector3.ZERO
	body.rotation = Vector3.ZERO
	var movement := clampf(speed / (7.5 if species == "boar" else 6.0), 0.0, 1.0)
	var pace := 5.2
	var upper_amount := .23
	var lower_amount := .18
	var paw_amount := .10
	if species == "boar":
		pace = 11.5 if state == "charge" else 6.2
		movement = maxf(movement, .82 if state == "charge" else 0.0)
		upper_amount = .22 if state == "charge" else .16
		lower_amount = .19
	elif species == "deer":
		pace = 9.2 if state in ["trot", "flee"] else 5.4
		movement = maxf(movement, .65 if state == "trot" else (.95 if state == "flee" else 0.0))
		upper_amount = .30
		lower_amount = .30
		paw_amount = .16
	else:
		pace = 10.0 if state in ["trot", "flee"] else 5.8
		movement = maxf(movement, .62 if state == "trot" else (.92 if state == "flee" else 0.0))
		upper_amount = .28
		lower_amount = .25
		paw_amount = .14
	var phase := elapsed * pace
	var stride := sin(phase) * movement
	_leg_pose("FrontL", stride, upper_amount, lower_amount, paw_amount)
	_leg_pose("HindR", stride, upper_amount, lower_amount, paw_amount)
	_leg_pose("FrontR", -stride, upper_amount, lower_amount, paw_amount)
	_leg_pose("HindL", -stride, upper_amount, lower_amount, paw_amount)
	var bob := absf(sin(phase * 2.0)) * movement * (.018 if species == "deer" else .012)
	_bone_position("Root", Vector3(0, bob, 0))
	_bone_rotation("Spine", Vector3(sin(phase * 2.0) * movement * .012, 0, 0))
	_bone_rotation("Neck", Vector3(sin(elapsed * 1.7) * .018, 0, 0))
	_bone_rotation("Head", Vector3(sin(elapsed * 1.35) * .018, sin(elapsed * .73) * .016, 0))
	_bone_rotation("TailBase", Vector3(0, sin(elapsed * 2.1) * .08, 0))
	_bone_rotation("TailTip", Vector3(0, sin(elapsed * 2.1 + .7) * .11, 0))
	if species == "boar":
		_pose_boar_state(state)
	else:
		_pose_flight_state(state)
	body.rotation.z = sin(elapsed * 38.0) * hit_flash * .045


func _pose_boar_state(state: String) -> void:
	if state == "warn":
		_bone_rotation("Neck", Vector3(.10, 0, 0))
		_bone_rotation("Head", Vector3(.19, 0, 0))
		_bone_rotation("FrontRUpper", Vector3(sin(state_elapsed * 17.0) * .16, 0, 0))
		_bone_rotation("FrontRLower", Vector3(-.10, 0, 0))
	elif state == "charge":
		_bone_rotation("Chest", Vector3(.05, 0, 0))
		_bone_rotation("Neck", Vector3(.17, 0, 0))
		_bone_rotation("Head", Vector3(.14, 0, 0))
	elif state == "recover":
		var settle := exp(-state_elapsed * 2.0)
		_bone_position("Root", Vector3(0, -.035 * settle, 0))
		_bone_rotation("Spine", Vector3(-.055 * settle, 0, 0))
		_bone_rotation("Neck", Vector3(.16 * settle, 0, 0))
		_bone_rotation("Head", Vector3(.20 * settle, 0, 0))


func _pose_flight_state(state: String) -> void:
	if state == "alert":
		_bone_rotation("Neck", Vector3(-.12, 0, 0))
		_bone_rotation("Head", Vector3(-.10, sin(state_elapsed * 1.6) * .10, 0))
		_bone_rotation("TailBase", Vector3(-.08 if species == "deer" else .05, 0, 0))
	elif state == "flee":
		_bone_rotation("Spine", Vector3(sin(elapsed * 10.0) * .025, 0, 0))
		_bone_rotation("Neck", Vector3(.05, 0, 0))
		_bone_rotation("Head", Vector3(.04, 0, 0))
