extends Control
## Shared look and slot-grid construction for the backpack and storage panels.
const Inventory = preload("res://scripts/inventory.gd")
const Icon = preload("res://scripts/item_icon.gd")
const GOLD := Color("d4b372")
const INK := Color("eee4cd")
const MUTED := Color("a6b4a6")

func _slot_grid(parent: Node, count: int, columns: int, on_select: Callable, cell: Vector2 = Vector2(138, 115)) -> Dictionary:
	var grid := GridContainer.new()
	grid.columns = columns
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	parent.add_child(grid)
	var result := {"grid": grid, "buttons": [], "icons": [], "names": [], "counts": []}
	for i in range(count):
		var button := Button.new()
		button.custom_minimum_size = cell
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.toggle_mode = true
		button.pressed.connect(on_select.bind(i))
		grid.add_child(button)
		result.buttons.append(button)
		var icon := Icon.new()
		icon.position = Vector2(cell.x / 2.0 - 30.0, 10)
		icon.size = Vector2(60, 56)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(icon)
		result.icons.append(icon)
		var title := _label(button, "", 14)
		title.position = Vector2(6, cell.y - 41.0)
		title.size = Vector2(cell.x - 12.0, 22)
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		result.names.append(title)
		var amount := _label(button, "", 13, GOLD)
		amount.position = Vector2(cell.x - 53.0, 7)
		amount.size.x = 45
		amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		result.counts.append(amount)
	return result

func _refresh_grid(grid: Dictionary, inventory: RefCounted, selected: int, held_item: String = "") -> void:
	for i in range(grid.buttons.size()):
		grid.buttons[i].visible = i < inventory.slots.size()
		if i >= inventory.slots.size():
			continue
		var slot: Dictionary = inventory.slots[i]
		var item: String = slot.get("item", "")
		grid.buttons[i].set_pressed_no_signal(i == selected)
		grid.icons[i].item_id = item
		grid.icons[i].queue_redraw()
		grid.names[i].text = Inventory.ITEMS[item].name if not item.is_empty() else "Empty"
		grid.counts[i].text = str(slot.amount) if not slot.is_empty() else ""
		if not held_item.is_empty() and item == held_item:
			grid.counts[i].text = "Held"

func _label(parent: Node, text: String, font_size: int, color: Color = INK) -> Label:
	var result := Label.new()
	result.text = text
	result.add_theme_font_size_override("font_size", font_size)
	result.add_theme_color_override("font_color", color)
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(result)
	return result

func _button(parent: Node, text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 40
	parent.add_child(button)
	return button

func _style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style

func _build_theme() -> void:
	theme = Theme.new()
	theme.default_font_size = 15
	theme.set_color("font_color", "Label", INK)
	theme.set_stylebox("normal", "Button", _style(Color("23362b"), Color("465d47")))
	theme.set_stylebox("hover", "Button", _style(Color("34493a"), GOLD))
	theme.set_stylebox("pressed", "Button", _style(Color("3a4c37"), GOLD))
	theme.set_stylebox("focus", "Button", _style(Color(0, 0, 0, 0), GOLD.lightened(0.25)))
	theme.set_stylebox("disabled", "Button", _style(Color("1d2a22"), Color("344335")))
	theme.set_color("font_color", "Button", INK)
	theme.set_color("font_hover_color", "Button", INK)
	theme.set_color("font_pressed_color", "Button", GOLD)
	theme.set_color("font_disabled_color", "Button", Color("7e897b"))

func _shell(width: float, height: float) -> VBoxContainer:
	## Dim overlay plus a centered framed card; returns the card's content column.
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_theme()
	var dim := ColorRect.new()
	dim.color = Color(0.025, 0.055, 0.045, 0.82)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var shell := PanelContainer.new()
	shell.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	shell.offset_left = -width / 2.0
	shell.offset_right = width / 2.0
	shell.offset_top = -height / 2.0
	shell.offset_bottom = height / 2.0
	shell.add_theme_stylebox_override("panel", _style(Color("17251f"), Color("53654d")))
	add_child(shell)
	var margin := MarginContainer.new()
	for edge in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 20)
	shell.add_child(margin)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 14)
	margin.add_child(layout)
	return layout
