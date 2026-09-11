extends Control
## Persistent, non-interactive health and stamina readout in either camera view.
var health_bar: ProgressBar
var stamina_bar: ProgressBar
var health_title: Label
var stamina_title: Label
var health_value: Label
var stamina_value: Label
const INK := Color("f4ead5")
const HEALTH := Color("c66957")
const STAMINA := Color("91b66f")

func _ready() -> void:
	name = "PlayerVitals"
	position = Vector2(24, 112)
	size = Vector2(300, 110)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var plate := Panel.new()
	plate.size = size
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.add_theme_stylebox_override("panel", _style(Color(0.055,0.09,0.07,0.90), Color("63705a")))
	add_child(plate)
	health_title = _label(Vector2(12,8), Vector2(180,22))
	health_value = _label(Vector2(195,8), Vector2(93,22), true)
	health_bar = _bar(34, HEALTH)
	stamina_title = _label(Vector2(12,57), Vector2(180,22))
	stamina_value = _label(Vector2(195,57), Vector2(93,22), true)
	stamina_bar = _bar(83, STAMINA)

func _label(at: Vector2, dimensions: Vector2, right: bool = false) -> Label:
	var label := Label.new()
	label.position = at
	label.size = dimensions
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", INK)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if right else HORIZONTAL_ALIGNMENT_LEFT
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	return label

func _bar(y: float, color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.position = Vector2(12,y)
	# A hidden percentage still contributes the theme font minimum unless overridden.
	bar.add_theme_font_size_override("font_size", 1)
	bar.max_value = 100
	bar.step = 0.0
	bar.show_percentage = false
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_theme_stylebox_override("background", _style(Color("26352c"), Color("3a4a3b")))
	bar.add_theme_stylebox_override("fill", _style(color, color.lightened(0.15)))
	add_child(bar)
	bar.set_deferred("size", Vector2(276,16))
	return bar

func _style(fill: Color, edge: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = edge
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	return style

func refresh(health: int, stamina: RefCounted) -> void:
	health_bar.value = health
	stamina_bar.value = stamina.value
	health_title.text = "HEALTH  •  LOW" if health <= 25 else "HEALTH"
	health_title.modulate = Color("ffac92") if health <= 25 else Color.WHITE
	health_value.text = "%d / 100" % health
	stamina_title.text = "CATCH YOUR BREATH" if stamina.exhausted else "STAMINA"
	stamina_title.modulate = Color("f0cf86") if stamina.exhausted else Color.WHITE
	stamina_value.text = "%d / 100" % ceili(stamina.value)
