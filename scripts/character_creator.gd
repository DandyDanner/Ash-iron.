extends Control
const Profile = preload("res://scripts/character_profile.gd")
const Traveler = preload("res://scripts/traveler_model.gd")
const GameSave = preload("res://scripts/game_save.gd")
const INK := Color("eee4cd")
const MUTED := Color("a6b4a6")
const GOLD := Color("d4b372")
var profile: Dictionary
var traveler: Node3D
var appearance_controls: VBoxContainer
var traveler_note: Label
var camera: Camera3D
var name_input: LineEdit
var story: Label
var memory: Label
var error_label: Label
var background_buttons: Array[Button] = []
var keepsake_buttons: Array[Button] = []
var choices: Dictionary = {}
var swatches: Dictionary = {}
var stage: SubViewport
var begin_button: Button
var start_over_button: Button
var confirm_start_over := false

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	profile = Profile.load_profile()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_theme()
	var backdrop := ColorRect.new()
	backdrop.color = Color("141f1c")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 24)
	add_child(margin)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 10)
	margin.add_child(layout)
	var header := HBoxContainer.new()
	layout.add_child(header)
	var title := VBoxContainer.new()
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	label(title, "ASH & IRON   /   A NEW BEGINNING", 13, GOLD)
	label(title, "Your story starts in the wild.", 30)
	var subtitle := label(header, "Choose your traveler. Make a life here.", 16, MUTED)
	subtitle.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 22)
	layout.add_child(columns)
	var left := VBoxContainer.new()
	left.custom_minimum_size.x = 245
	left.add_theme_constant_override("separation", 9)
	columns.add_child(left)
	label(left, "01  /  YOUR STORY", 13, GOLD)
	label(left, "What brought you here?", 20)
	for i in range(4):
		var button := Button.new()
		button.text = Profile.BACKGROUNDS[i] + "   /   " + ["The woods", "A new craft", "The open road", "The mountains"][i]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size.y = 42
		button.toggle_mode = true
		button.pressed.connect(_select_background.bind(i))
		left.add_child(button)
		background_buttons.append(button)
	story = label(left, "", 16, INK)
	story.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	story.custom_minimum_size.y = 80
	var note := label(left, "A little history to carry with you.\nEvery background plays the same.", 13, MUTED)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var center := VBoxContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.add_theme_constant_override("separation", 6)
	columns.add_child(center)
	_build_stage(center)
	var turn := HBoxContainer.new()
	center.add_child(turn)
	label(turn, "TURN", 12, MUTED)
	var rotation_slider := HSlider.new()
	rotation_slider.min_value = -180
	rotation_slider.max_value = 180
	rotation_slider.value = -12
	rotation_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rotation_slider.custom_minimum_size.x = 100
	rotation_slider.value_changed.connect(func(value: float): traveler.rotation.y = deg_to_rad(value))
	rotation_slider.tooltip_text = "Turn your traveler to see the outfit and pack."
	turn.add_child(rotation_slider)
	var zoom := Button.new()
	zoom.text = "Face / outfit"
	zoom.toggle_mode = true
	zoom.toggled.connect(func(close: bool):
		camera.position = Vector3(0, 1.92, 3.3) if close else Vector3(0, 1.55, 5.5)
		camera.size = 0.85 if close else 2.65
		camera.look_at(Vector3(0, 1.85, 0) if close else Vector3(0, 1.1, 0)))
	turn.add_child(zoom)
	var right := VBoxContainer.new()
	right.custom_minimum_size.x = 278
	right.add_theme_constant_override("separation", 7)
	columns.add_child(right)
	label(right, "02  /  MAKE IT YOURS", 13, GOLD)
	name_input = LineEdit.new()
	name_input.placeholder_text = "Your name"
	name_input.max_length = 24
	name_input.text = profile.name
	name_input.custom_minimum_size.y = 39
	name_input.text_changed.connect(func(value: String): profile.name = value)
	right.add_child(name_input)
	_option(right, "Traveler", "traveler", Profile.TRAVELERS)
	traveler_note = label(right, "", 15, MUTED)
	traveler_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	appearance_controls = VBoxContainer.new()
	appearance_controls.add_theme_constant_override("separation", 7)
	right.add_child(appearance_controls)
	_option(appearance_controls, "Build", "build", Profile.BUILDS)
	_option(appearance_controls, "Face", "face", Profile.FACES)
	_option(appearance_controls, "Hair", "hair", Profile.HAIR_STYLES)
	_palette(appearance_controls, "Skin tone", "skin", Profile.SKINS)
	_palette(appearance_controls, "Hair color", "hair_color", Profile.HAIR_COLORS)
	_palette(appearance_controls, "Clothing color", "clothes", Profile.CLOTHES)
	label(layout, "03  /  SOMETHING FROM HOME", 13, GOLD)
	var keepsakes := HBoxContainer.new()
	keepsakes.add_theme_constant_override("separation", 10)
	layout.add_child(keepsakes)
	for i in range(4):
		var button := Button.new()
		button.text = Profile.KEEPSAKES[i]
		button.custom_minimum_size.y = 40
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.toggle_mode = true
		button.pressed.connect(_choose.bind("keepsake", i))
		keepsakes.add_child(button)
		keepsake_buttons.append(button)
	memory = label(layout, "", 15, MUTED)
	memory.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	memory.custom_minimum_size.y = 24
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 16)
	layout.add_child(footer)
	var hint := label(footer, "Your appearance is yours to change.\nPress C in the clearing to return here. Your progress out there is kept.", 13, MUTED)
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	error_label = label(footer, "", 13, Color("f0a18c"))
	error_label.custom_minimum_size.x = 150
	error_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	start_over_button = Button.new()
	start_over_button.name = "StartOver"
	start_over_button.custom_minimum_size = Vector2(190, 48)
	start_over_button.tooltip_text = "Erase your saved clearing and begin again with empty hands. Your traveler is kept."
	start_over_button.pressed.connect(_start_over)
	footer.add_child(start_over_button)
	begin_button = Button.new()
	begin_button.name = "BeginJourney"
	begin_button.custom_minimum_size = Vector2(285, 48)
	begin_button.add_theme_stylebox_override("normal", _style(GOLD, GOLD))
	begin_button.add_theme_stylebox_override("hover", _style(GOLD.lightened(0.12), GOLD))
	begin_button.add_theme_color_override("font_color", Color("18251f"))
	begin_button.add_theme_color_override("font_hover_color", Color("18251f"))
	begin_button.pressed.connect(_begin)
	footer.add_child(begin_button)
	_refresh()
	_refresh_journey()

func _style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 7
	style.content_margin_bottom = 7
	return style

func _build_theme() -> void:
	theme = Theme.new()
	theme.default_font_size = 15
	theme.set_color("font_color", "Label", INK)
	for type in ["Button", "OptionButton", "LineEdit"]:
		theme.set_stylebox("normal", type, _style(Color("202f29"), Color("435348")))
		theme.set_stylebox("hover", type, _style(Color("34463a"), GOLD))
		theme.set_stylebox("pressed", type, _style(Color("3c4d3d"), GOLD))
		theme.set_stylebox("focus", type, _style(Color(0, 0, 0, 0), GOLD.lightened(0.25)))
		theme.set_color("font_color", type, INK)
		theme.set_color("font_pressed_color", type, GOLD.lightened(0.15))
		theme.set_color("font_hover_color", type, INK)
		theme.set_color("font_focus_color", type, INK)

func label(parent: Node, text: String, font_size: int, color: Color = INK) -> Label:
	var node := Label.new()
	node.text = text
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", color)
	parent.add_child(node)
	return node

func _option(parent: Node, title: String, key: String, values: Array) -> void:
	var row := HBoxContainer.new()
	parent.add_child(row)
	var caption := label(row, title, 15, MUTED)
	caption.custom_minimum_size.x = 66
	var option := OptionButton.new()
	option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for value in values:
		option.add_item(value)
	option.item_selected.connect(func(index: int): _choose(key, index))
	row.add_child(option)
	choices[key] = option

func _palette(parent: Node, title: String, key: String, colors: Array) -> void:
	label(parent, title, 13, MUTED)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	parent.add_child(row)
	swatches[key] = []
	for i in range(colors.size()):
		var button := Button.new()
		button.custom_minimum_size = Vector2(38, 30)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.toggle_mode = true
		button.tooltip_text = title + " " + str(i + 1)
		button.add_theme_stylebox_override("normal", _style(colors[i], colors[i].lightened(0.18)))
		button.add_theme_stylebox_override("pressed", _style(colors[i], INK))
		button.add_theme_stylebox_override("hover", _style(colors[i].lightened(0.12), GOLD))
		button.add_theme_color_override("font_pressed_color", Color.WHITE if colors[i].get_luminance() < 0.4 else Color("18251f"))
		button.pressed.connect(_choose.bind(key, i))
		row.add_child(button)
		swatches[key].append(button)

func _select_background(index: int) -> void:
	# Outfit changes preserve the player's face, body, colors, name, and keepsake.
	_choose("background", index)

func _choose(key: String, value: int) -> void:
	profile[key] = value
	_refresh()

func _refresh() -> void:
	for i in range(4):
		background_buttons[i].set_pressed_no_signal(i == profile.background)
		keepsake_buttons[i].set_pressed_no_signal(i == profile.keepsake)
	appearance_controls.visible = profile.traveler == 4
	traveler_note.text = Profile.TRAVELER_NOTES[profile.traveler]
	story.text = Profile.STORIES[profile.background]
	memory.text = Profile.MEMORIES[profile.keepsake]
	for key in choices:
		choices[key].select(profile[key])
	for key in swatches:
		for i in range(swatches[key].size()):
			swatches[key][i].set_pressed_no_signal(i == profile[key])
			swatches[key][i].text = "✓" if i == profile[key] else ""
	traveler.rebuild(profile)

func _refresh_journey() -> void:
	var saved := GameSave.exists()
	start_over_button.visible = saved
	start_over_button.text = "Really start over?" if confirm_start_over else "Start over"
	if saved:
		begin_button.text = "Continue your journey   →"
	else:
		begin_button.text = "Begin your journey   →" if profile.name.is_empty() else "Save & enter the clearing   →"

func _start_over() -> void:
	# Two clicks: the first asks, the second erases world progress. The traveler is kept.
	if confirm_start_over:
		GameSave.clear()
	confirm_start_over = not confirm_start_over and GameSave.exists()
	_refresh_journey()

func _begin() -> void:
	profile = Profile.clean(profile)
	if profile.name.is_empty():
		profile.name = "Traveler"
	var result := Profile.save_profile(profile)
	if result != OK:
		error_label.text = "Couldn't save your traveler.\nPlease try again."
		return
	var scene_error := get_tree().change_scene_to_file("res://scenes/main.tscn")
	if scene_error != OK:
		error_label.text = "Couldn't open the clearing."

func _build_stage(parent: Control) -> void:
	var container := SubViewportContainer.new()
	container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.custom_minimum_size = Vector2(330, 330)
	container.stretch = true
	parent.add_child(container)
	stage = SubViewport.new()
	stage.own_world_3d = true
	stage.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	stage.msaa_3d = Viewport.MSAA_4X
	stage.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
	container.add_child(stage)
	var world := Node3D.new()
	stage.add_child(world)
	var environment := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color("b6c0a5")
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color("ced9c3")
	settings.ambient_light_energy = 0.65
	settings.tonemap_mode = Environment.TONE_MAPPER_ACES
	settings.tonemap_exposure = 1.0
	# Contact shadows and a softer sun help the face read; ignored on the compatibility renderer.
	settings.ssao_enabled = true
	settings.ssao_radius = 0.5
	settings.ssao_intensity = 2.0
	settings.ssao_light_affect = 0.1
	settings.glow_enabled = true
	settings.glow_intensity = 0.25
	settings.glow_bloom = 0.02
	settings.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	settings.glow_hdr_threshold = 1.0
	environment.environment = settings
	world.add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35, -35, 0)
	sun.light_color = Color("ffdeae")
	sun.light_energy = 1.1
	sun.light_angular_distance = 0.8
	sun.shadow_enabled = true
	sun.shadow_bias = 0.03
	sun.shadow_normal_bias = 1.2
	sun.shadow_blur = 1.5
	sun.directional_shadow_max_distance = 12
	world.add_child(sun)
	var rim := OmniLight3D.new()
	rim.position = Vector3(-2, 3, -1)
	rim.light_color = Color("c5ddb8")
	rim.light_energy = 0.7
	world.add_child(rim)
	Traveler.cylinder(world, Vector3(0, -0.13, 0), 1.35, 0.22, Color("52664d"), 1.25)
	Traveler.cylinder(world, Vector3(0, -0.3, 0), 1.36, 0.18, Color("3b4636"))
	for i in range(5):
		var pine := Node3D.new()
		pine.position = Vector3(-3.0 + i * 1.5, -0.2, -3.0 - i % 2)
		world.add_child(pine)
		preload("res://scripts/forest_art.gd").pine(pine, i)
	for i in range(8):
		var angle := i * 0.8
		Traveler.oval(world, Vector3(sin(angle) * 1.0, 0.03, cos(angle) * 0.9), Vector3(0.16, 0.13, 0.24), Color("89917b"))
	traveler = Traveler.new()
	traveler.rotation_degrees.y = -12
	world.add_child(traveler)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 2.65
	camera.position = Vector3(0, 1.65, 5.5)
	world.add_child(camera)
	camera.look_at(Vector3(0, 1.1, 0))
	camera.current = true
