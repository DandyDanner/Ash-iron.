extends Node3D
## The player advances the swing during physics ticks; contact happens once per swing.
const Model = preload("res://scripts/traveler_model.gd")
const CONTACT_TIME := 0.22
const SWING_DURATION := 0.6
const SPEAR_REACH := 2.8
const SPEAR_DAMAGE := 20
const AXE_DAMAGE := 10
var elapsed := -1.0
var contact_sent := false
var selected_item := ""
var rest_position := Vector3(0.36, -0.34, -0.7)
var hand: Node3D
var whoosh: AudioStreamPlayer
var impact: AudioStreamPlayer

func setup(cloth: Color, skin: Color) -> void:
	name = "StarterAxe"
	position = rest_position
	hand = preload("res://scripts/first_person_hand.gd").new()
	hand.name = "RightHand"
	add_child(hand)
	hand.build(skin, cloth)
	var tool := Node3D.new()
	tool.name = "Tool"
	tool.rotation.y = -PI / 2 # Cutting edge faces camera-forward (-Z).
	tool.scale = Vector3.ONE * 0.85
	add_child(tool)
	Model.cylinder(tool, Vector3(0, 0.18, 0), 0.025, 0.66, Color("86603c"), 0.02)
	for i in range(5):
		Model.cylinder(tool, Vector3(0, -0.08 + i * 0.037, 0), 0.029, 0.025, Color("49352b"))
	Model.box(tool, Vector3(0.02, 0.46, 0), Vector3(0.11, 0.16, 0.1), Color("65705f"))
	# A flared blade with a thin cutting edge and a thicker socket at the handle.
	var points := [Vector3(-0.22, -0.12, 0.016), Vector3(-0.22, 0.12, 0.016), Vector3(0, 0.065, 0.05), Vector3(0, -0.065, 0.05), Vector3(-0.22, -0.12, -0.016), Vector3(-0.22, 0.12, -0.016), Vector3(0, 0.065, -0.05), Vector3(0, -0.065, -0.05)]
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for face in [[0, 1, 2, 3], [7, 6, 5, 4], [1, 5, 6, 2], [4, 0, 3, 7], [4, 5, 1, 0], [3, 2, 6, 7]]:
		for vertex in [face[0], face[1], face[2], face[0], face[2], face[3]]:
			surface.add_vertex(points[vertex])
	surface.generate_normals()
	Model.part(tool, surface.commit(), Vector3(0, 0.46, 0), Color("788374"))
	Model.box(tool, Vector3(-0.218, 0.46, 0), Vector3(0.012, 0.235, 0.033), Color("98a38f"))
	for i in range(3):
		Model.box(tool, Vector3(0, 0.415 + i * 0.035, 0.06), Vector3(0.135, 0.021, 0.035), Color("c2ac7c"))
	var copper := tool.duplicate()
	copper.name = "CopperTool"
	add_child(copper)
	for mesh in copper.find_children("*", "MeshInstance3D", true, false):
		if mesh.position.y >= 0.4:
			var finish := StandardMaterial3D.new()
			finish.albedo_color = Color("c98752")
			finish.metallic = 0.65
			finish.roughness = 0.42
			mesh.material_override = finish
	copper.hide()
	var pick := Node3D.new()
	pick.name = "Pickaxe"
	pick.rotation.y = -PI / 2
	add_child(pick)
	preload("res://scripts/pickaxe_art.gd").build(pick)
	var spear := Node3D.new()
	spear.name = "Spear"
	add_child(spear)
	preload("res://scripts/spear_art.gd").build(spear)
	spear.hide()
	var torch := Node3D.new()
	torch.name = "Torch"
	add_child(torch)
	Model.cylinder(torch, Vector3(0, 0.17, 0), 0.033, 0.6, Color("926744"), 0.026)
	Model.cylinder(torch, Vector3(0, 0.42, 0), 0.075, 0.16, Color("674a31"), 0.045)
	var flame := Model.oval(torch, Vector3(0, 0.55, 0), Vector3(0.13, 0.25, 0.13), Color("ff9a36"))
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("ffb04c")
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	flame.material_override = material
	Model.oval(torch, Vector3(0, 0.50, -0.06), Vector3(0.07, 0.13, 0.07), Color("ffe6a3"))
	var light := OmniLight3D.new()
	light.name = "WarmLight"
	light.position = Vector3(0, 0.55, -0.1)
	light.light_color = Color("ffb76a")
	light.light_energy = 2.4
	light.omni_range = 8.0
	torch.add_child(light)
	pick.hide()
	torch.hide()
	for mesh in find_children("*", "MeshInstance3D", true, false):
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	rotation = Vector3.ZERO
	whoosh = _sound(false)
	impact = _sound(true)

func _sound(wood: bool) -> AudioStreamPlayer:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	var data := PackedByteArray()
	var samples := 3307
	data.resize(samples * 2)
	var noise_state := 193
	for i in range(samples):
		var time := float(i) / stream.mix_rate
		var progress := float(i) / samples
		noise_state = (noise_state * 16807) % 2147483647
		var noise := float(noise_state) / 2147483647.0 * 2.0 - 1.0
		var value := (sin(TAU * 150.0 * time) * 0.55 + noise * 0.45) * exp(-progress * 9.0) if wood else noise * sin(progress * PI) * 0.17
		data.encode_s16(i * 2, int(value * 19000))
	stream.data = data
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = -10
	add_child(player)
	return player

func set_equipped(equipped: bool) -> void:
	set_item("stone_axe" if equipped else "")

func set_item(item: String) -> void:
	selected_item = item
	hand.set_grip(not item.is_empty())
	$Tool.visible = item == "stone_axe"
	$CopperTool.visible = item == "copper_axe"
	$Pickaxe.visible = item == "stone_pickaxe"
	$Torch.visible = item == "torch"
	$Spear.visible = item == "stone_spear"
	if not item in ["stone_axe", "copper_axe", "stone_pickaxe", "stone_spear"]:
		cancel_swing()

func start_swing() -> bool:
	if not selected_item in ["stone_axe", "copper_axe", "stone_pickaxe", "stone_spear"] or elapsed >= 0.0:
		return false
	elapsed = 0.0
	contact_sent = false
	whoosh.play()
	return true

func cancel_swing() -> void:
	elapsed = -1.0
	position = rest_position
	rotation = Vector3.ZERO

func advance(delta: float) -> bool:
	if elapsed < 0.0:
		return false
	elapsed += delta
	pose_swing(elapsed)
	var contact := elapsed >= CONTACT_TIME and not contact_sent
	if contact:
		contact_sent = true
	if elapsed >= SWING_DURATION:
		cancel_swing()
	return contact

func pose_swing(time: float) -> void:
	if selected_item == "stone_spear":
		rotation = Vector3.ZERO
		position = rest_position + Vector3(0, 0, -thrust_distance(time))
		return
	# Pitch only: keep the head in a vertical plane beside the crosshair.
	var pitch: float
	var hand_offset: Vector3
	var raised := Vector3(0, 0.14, 0.12)
	var contact := Vector3(0, -0.02, -0.16)
	var follow_through := Vector3(0, -0.10, -0.20)
	if time < 0:
		pitch = 0
		hand_offset = Vector3.ZERO
	elif time < 0.08:
		var t := smoothstep(0, 0.08, time)
		pitch = lerpf(0, 0.9, t)
		hand_offset = Vector3.ZERO.lerp(raised, t)
	elif time < CONTACT_TIME:
		var t := smoothstep(0.08, CONTACT_TIME, time)
		pitch = lerpf(0.9, -0.55, t)
		hand_offset = raised.lerp(contact, t)
	elif time < 0.32:
		var t := smoothstep(CONTACT_TIME, 0.32, time)
		pitch = lerpf(-0.55, -1.0, t)
		hand_offset = contact.lerp(follow_through, t)
	else:
		var t := smoothstep(0.32, SWING_DURATION, time)
		pitch = lerpf(-1.0, 0, t)
		hand_offset = follow_through.lerp(Vector3.ZERO, t)
	rotation = Vector3(pitch, 0, 0)
	position = rest_position + hand_offset

static func thrust_distance(time: float) -> float:
	if time < 0: return 0.0
	if time < 0.08: return lerpf(0.0, -0.12, smoothstep(0, 0.08, time))
	if time < CONTACT_TIME: return lerpf(-0.12, 0.38, smoothstep(0.08, CONTACT_TIME, time))
	return lerpf(0.38, 0.0, smoothstep(CONTACT_TIME, SWING_DURATION, time))
