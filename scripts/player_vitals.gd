extends Control
## Persistent, non-interactive health and stamina readout in either camera view.
var health_bar: ProgressBar
var stamina_bar: ProgressBar
var health_title: Label
var stamina_title: Label
var health_value: Label
var stamina_value: Label
const INK := Color("f4ead5")
const MUTED := Color("b9c4b3")
const HEALTH := Color("e2604f")
const STAMINA := Color("9ed26b")

func _ready() -> void:
	name = "PlayerVitals"
	position = Vector2(24, 108)
	size = Vector2(264, 78)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var plate := Panel.new()
	plate.size = size
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.add_theme_stylebox_override("panel", _rounded(Color(0.02, 0.05, 0.04, 0.55), 10, Color(1, 1, 1, 0.06), 1))
	add_child(plate)
	health_title = _label(Vector2(14, 8), Vector2(150, 16))
	health_value = _label(Vector2(150, 8), Vector2(100, 16), true, MUTED)
	health_bar = _bar(27, HEALTH)
	stamina_title = _label(Vector2(14, 43), Vector2(150, 16))
	stamina_value = _label(Vector2(150, 43), Vector2(100, 16), true, MUTED)
	stamina_bar = _bar(62, STAMINA)

func _label(at: Vector2, dimensions: Vector2, right: bool = false, color: Color = INK) -> Label:
	var label := Label.new()
	label.position = at
	label.size = dimensions
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if right else HORIZONTAL_ALIGNMENT_LEFT
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	return label

func _bar(y: float, color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.position = Vector2(14, y)
	# A hidden percentage still contributes the theme font minimum unless overridden.
	bar.add_theme_font_size_override("font_size", 1)
	bar.max_value = 100
	bar.step = 0.0
	bar.show_percentage = false
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_theme_stylebox_override("background", _rounded(Color(0, 0, 0, 0.42), 4))
	bar.add_theme_stylebox_override("fill", _rounded(color, 4, color.lightened(0.35), 1))
	add_child(bar)
	bar.set_deferred("size", Vector2(236, 8))
	return bar

func _rounded(fill: Color, radius: int, edge: Color = Color(0, 0, 0, 0), width: int = 0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = edge
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
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
