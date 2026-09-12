extends "res://scripts/panel_base.gd"
## Shortcuts point to item types in the backpack. They never create extra storage.
const CELL := 46
var player: Node3D
var cells: Array[Button] = []
var icons: Array[Control] = []
var captions: Array[Label] = []

func setup(owner_player: Node3D) -> void:
	player = owner_player
	name = "Hotbar"
	set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	offset_left = -257
	offset_right = 257
	offset_top = -74
	offset_bottom = -6
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	add_child(row)
	var idle := _cell_style(Color(0.02, 0.05, 0.04, 0.6), Color(1, 1, 1, 0.10), 1)
	var active := _cell_style(Color(0.16, 0.24, 0.17, 0.92), GOLD, 2)
	var none := StyleBoxEmpty.new()
	for i in range(10):
		var button := Button.new()
		button.custom_minimum_size = Vector2(CELL, CELL)
		button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.focus_mode = Control.FOCUS_NONE
		button.toggle_mode = true
		for state in ["normal", "hover", "disabled"]:
			button.add_theme_stylebox_override(state, idle)
		button.add_theme_stylebox_override("pressed", active)
		button.add_theme_stylebox_override("focus", none)
		row.add_child(button)
		cells.append(button)
		var icon := Icon.new()
		icon.position = Vector2(3, 7)
		icon.size = Vector2(60, 56)
		icon.scale = Vector2(0.66, 0.66)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(icon)
		icons.append(icon)
		var caption := _label(button, str((i + 1) % 10), 10, GOLD)
		caption.position = Vector2(4, 2)
		captions.append(caption)
	var hint := _label(self, "1–9, 0  Equip / holster    •    Tab  Backpack    •    V  View    •    F11  Full screen", 11, MUTED)
	hint.position = Vector2(0, 50)
	hint.size.x = 514
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	refresh()

func _cell_style(fill: Color, edge: Color, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = edge
	style.set_border_width_all(width)
	style.set_corner_radius_all(9)
	return style

func refresh() -> void:
	for i in range(cells.size()):
		var item: String = player.hotbar[i]
		var available: bool = not item.is_empty() and player.inventory.count(item) > 0
		icons[i].item_id = item
		icons[i].modulate.a = 1.0 if available else 0.25
		icons[i].queue_redraw()
		cells[i].set_pressed_no_signal(available and player.equipped_item == item)
