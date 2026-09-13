extends Node3D
## Standalone native wildlife viewer: 1–3 select, arrows change pose, Space pauses.

const Wildlife = preload("res://scripts/native_wildlife_model.gd")
const SPECIES := ["boar", "deer", "wolf"]
const LABELS := ["BRISTLEBACK", "MEADOW BUCK", "HOLLOW WOLF"]
const REVIEW_STATES := {
	"boar": ["idle", "approach", "warn", "charge", "recover"],
	"deer": ["idle", "walk", "trot", "alert", "flee"],
	"wolf": ["idle", "walk", "trot", "alert", "flee"],
}
const SPEEDS := {"idle": 0.0, "approach": 2.2, "walk": 2.0, "trot": 4.0, "warn": 0.0, "alert": 0.0, "charge": 7.5, "recover": 0.0, "flee": 6.0}

var animals: Array[Node3D] = []
var selected := 0
var state_index := 0
var playing := true
var camera: Camera3D
var title: Label
var help: Label
var orbiting := false
var orbit_yaw := .52
var orbit_pitch := .18
var camera_distance := 3.0
var camera_target := Vector3(0, .65, 0)


func _ready() -> void:
	_build_stage()
	for kind in SPECIES:
		var animal := Wildlife.new()
		animal.species = kind
		animal.visible = false
		add_child(animal)
		animals.append(animal)
	select_species(0)


func _process(delta: float) -> void:
	if animals.is_empty():
		return
	var state: String = current_state()
	animals[selected].pose(delta if playing else 0.0, float(SPEEDS.get(state, 0.0)), state, 0.0)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
			orbiting = event.pressed
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera_distance = maxf(camera_distance * .88, 1.3)
			_update_camera()
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera_distance = minf(camera_distance / .88, 8.0)
			_update_camera()
	elif event is InputEventMouseMotion and orbiting:
		orbit_yaw -= event.relative.x * .008
		orbit_pitch = clampf(orbit_pitch - event.relative.y * .006, -.08, .72)
		_update_camera()
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1: select_species(0)
			KEY_2: select_species(1)
			KEY_3: select_species(2)
			KEY_LEFT: set_pose_index(state_index - 1)
			KEY_RIGHT: set_pose_index(state_index + 1)
			KEY_SPACE:
				playing = not playing
				_refresh_label()


func select_species(index: int) -> void:
	selected = wrapi(index, 0, SPECIES.size())
	state_index = 0
	for i in range(animals.size()):
		animals[i].visible = i == selected
	var height := 2.0 if SPECIES[selected] == "deer" else 1.25
	camera_target = Vector3(0, height * .48, 0)
	camera_distance = height * 2.45
	_update_camera()
	_refresh_label()


func set_pose_index(index: int) -> void:
	state_index = wrapi(index, 0, REVIEW_STATES[SPECIES[selected]].size())
	animals[selected].previous_state = ""
	_refresh_label()


func set_pose_state(state: String) -> void:
	var states: Array = REVIEW_STATES[SPECIES[selected]]
	state_index = maxi(0, states.find(state))
	animals[selected].previous_state = ""
	_refresh_label()


func current_state() -> String:
	return REVIEW_STATES[SPECIES[selected]][state_index]


func _refresh_label() -> void:
	if not is_instance_valid(title):
		return
	title.text = "%s  •  %s" % [LABELS[selected], current_state().to_upper()]
	help.text = "1 / 2 / 3  select species     ← / →  change pose     Drag  orbit     Wheel  zoom     Space  %s" % ("pause" if playing else "play")


func _update_camera() -> void:
	var horizontal := cos(orbit_pitch) * camera_distance
	camera.position = camera_target + Vector3(sin(orbit_yaw) * horizontal, sin(orbit_pitch) * camera_distance, cos(orbit_yaw) * horizontal)
	camera.look_at(camera_target)


func _build_stage() -> void:
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color("182128")
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color("a9bdc6")
	world.environment.ambient_light_energy = .36
	world.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	add_child(world)
	var ground := MeshInstance3D.new()
	var ground_mesh := BoxMesh.new()
	ground_mesh.size = Vector3(12, .08, 12)
	ground.mesh = ground_mesh
	ground.position.y = -.045
	var ground_material := StandardMaterial3D.new()
	ground_material.albedo_color = Color("3a4944")
	ground_material.roughness = .96
	ground.material_override = ground_material
	add_child(ground)
	for config in [Vector3(-48, -35, 1.35), Vector3(-28, 140, .72)]:
		var light := DirectionalLight3D.new()
		light.rotation_degrees = Vector3(config.x, config.y, 0)
		light.light_energy = config.z
		light.shadow_enabled = true
		add_child(light)
	camera = Camera3D.new()
	camera.fov = 40
	add_child(camera)
	camera.make_current()
	var ui := CanvasLayer.new()
	add_child(ui)
	var shade := ColorRect.new()
	shade.color = Color(0.025, .035, .045, .80)
	shade.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	shade.custom_minimum_size.y = 92
	ui.add_child(shade)
	title = Label.new()
	title.position = Vector2(28, 16)
	title.add_theme_font_size_override("font_size", 22)
	ui.add_child(title)
	help = Label.new()
	help.position = Vector2(28, 48)
	help.add_theme_color_override("font_color", Color("c8d3d0"))
	help.add_theme_font_size_override("font_size", 13)
	ui.add_child(help)
