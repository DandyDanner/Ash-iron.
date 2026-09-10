extends Node3D
## The player advances the swing during physics ticks; contact happens once per swing.
const Model = preload("res://scripts/traveler_model.gd")
const CONTACT_TIME := 0.22
const SWING_DURATION := 0.6
var elapsed := -1.0
var contact_sent := false
var rest_position := Vector3(0.36, -0.34, -0.7)
var whoosh: AudioStreamPlayer
var impact: AudioStreamPlayer

func setup(cloth: Color, skin: Color) -> void:
	name = "StarterAxe"
	position = rest_position
	Model.oval(self, Vector3(0.02, -0.13, 0.22), Vector3(0.15, 0.17, 0.43), cloth)
	var hand := Model.oval(self, Vector3.ZERO, Vector3(0.12, 0.13, 0.16), skin)
	hand.name = "RightHand"
	var tool := Node3D.new()
	tool.name = "Tool"
	tool.scale = Vector3.ONE * 0.85
	add_child(tool)
	Model.cylinder(tool, Vector3(0, 0.18, 0), 0.025, 0.66, Color("86603c"), 0.02)
	for i in range(5):
		Model.cylinder(tool, Vector3(0, -0.08 + i * 0.037, 0), 0.029, 0.025, Color("49352b"))
	Model.box(tool, Vector3(0.02, 0.46, 0), Vector3(0.11, 0.16, 0.1), Color("565e60"))
	# A flared blade with a thin cutting edge and a thicker socket at the handle.
	var points := [Vector3(-0.22, -0.12, 0.016), Vector3(-0.22, 0.12, 0.016), Vector3(0, 0.065, 0.05), Vector3(0, -0.065, 0.05), Vector3(-0.22, -0.12, -0.016), Vector3(-0.22, 0.12, -0.016), Vector3(0, 0.065, -0.05), Vector3(0, -0.065, -0.05)]
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for face in [[0, 1, 2, 3], [7, 6, 5, 4], [1, 5, 6, 2], [4, 0, 3, 7], [4, 5, 1, 0], [3, 2, 6, 7]]:
		for vertex in [face[0], face[1], face[2], face[0], face[2], face[3]]:
			surface.add_vertex(points[vertex])
	surface.generate_normals()
	Model.part(tool, surface.commit(), Vector3(0, 0.46, 0), Color("829392"))
	Model.box(tool, Vector3(-0.218, 0.46, 0), Vector3(0.012, 0.235, 0.033), Color("a6b7b2"))
	for mesh in find_children("*", "MeshInstance3D", true, false):
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	rotation_degrees = Vector3(0, -12, -12)
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

func start_swing() -> bool:
	if elapsed >= 0.0:
		return false
	elapsed = 0.0
	contact_sent = false
	whoosh.play()
	return true

func cancel_swing() -> void:
	elapsed = -1.0
	position = rest_position
	rotation_degrees = Vector3(0, -12, -12)

func advance(delta: float) -> bool:
	if elapsed < 0.0:
		return false
	elapsed += delta
	var angle: float
	if elapsed < CONTACT_TIME:
		angle = lerpf(-12.0, 72.0, pow(elapsed / CONTACT_TIME, 2.0))
	else:
		angle = lerpf(72.0, -12.0, smoothstep(CONTACT_TIME, SWING_DURATION, elapsed))
	rotation_degrees = Vector3(-sin(elapsed / SWING_DURATION * PI) * 24.0, -12, angle)
	position = rest_position + Vector3(-sin(elapsed / SWING_DURATION * PI) * 0.18, 0, -0.03)
	var contact := elapsed >= CONTACT_TIME and not contact_sent
	if contact:
		contact_sent = true
	if elapsed >= SWING_DURATION:
		cancel_swing()
	return contact
