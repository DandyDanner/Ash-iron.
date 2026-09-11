extends Control
const Inventory = preload("res://scripts/inventory.gd")
const Icon = preload("res://scripts/item_icon.gd")
const GOLD := Color("d4b372")
const INK := Color("eee4cd")
const MUTED := Color("a6b4a6")
var player: Node3D
var selected := -1
var slot_buttons: Array[Button] = []
var slot_icons: Array[Control] = []
var slot_names: Array[Label] = []
var slot_counts: Array[Label] = []
var capacity_label: Label
var detail: Label
var equip_button: Button
var drop_button: Button
var bench_button: Button
var axe_button: Button
var bench_cost: Label
var axe_cost: Label
var bench_status: Label
var axe_status: Label
var message_label: Label

func setup(owner_player: Node3D) -> void:
	player = owner_player
	name = "InventoryPanel"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_theme()
	var dim := ColorRect.new()
	dim.color = Color(0.025, 0.055, 0.045, 0.82)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var shell := PanelContainer.new()
	shell.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	shell.offset_left = -555
	shell.offset_right = 555
	shell.offset_top = -350
	shell.offset_bottom = 350
	shell.add_theme_stylebox_override("panel", _style(Color("17251f"), Color("53654d")))
	add_child(shell)
	var margin := MarginContainer.new()
	for edge in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 20)
	shell.add_child(margin)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 14)
	margin.add_child(layout)
	var header := HBoxContainer.new()
	layout.add_child(header)
	var heading := VBoxContainer.new()
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(heading)
	_label(heading, "ASH & IRON  /  FIRST DAYS", 13, GOLD)
	_label(heading, "A little room. A place to begin.", 27)
	var close_button := _button(header, "Close  [I / Esc]")
	close_button.pressed.connect(player.close_inventory)
	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 24)
	layout.add_child(columns)
	var left := VBoxContainer.new()
	left.custom_minimum_size.x = 590
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 10)
	columns.add_child(left)
	capacity_label = _label(left, "", 16, GOLD)
	_label(left, "Resources stack to 10. Each tool takes one slot.", 14, MUTED)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	left.add_child(grid)
	for i in range(Inventory.CAPACITY):
		var button := Button.new()
		button.custom_minimum_size = Vector2(138, 115)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.toggle_mode = true
		button.pressed.connect(func(): selected = i; refresh())
		grid.add_child(button)
		slot_buttons.append(button)
		var icon := Icon.new()
		icon.position = Vector2(40, 10)
		icon.size = Vector2(60, 56)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(icon)
		slot_icons.append(icon)
		var title := _label(button, "", 14)
		title.position = Vector2(6, 74)
		title.size = Vector2(126, 22)
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot_names.append(title)
		var amount := _label(button, "", 13, GOLD)
		amount.position = Vector2(85, 7)
		amount.size.x = 45
		amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		slot_counts.append(amount)
	detail = _label(left, "", 16)
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.custom_minimum_size.y = 80
	var actions := HBoxContainer.new()
	left.add_child(actions)
	equip_button = _button(actions, "Equip axe")
	equip_button.pressed.connect(func(): player.toggle_axe(); refresh())
	drop_button = _button(actions, "Drop selected stack")
	drop_button.pressed.connect(func():
		var result: String = player.drop_slot(selected)
		message_label.text = result
		refresh())
	var right := VBoxContainer.new()
	right.custom_minimum_size.x = 380
	right.add_theme_constant_override("separation", 7)
	columns.add_child(right)
	_label(right, "MAKE YOUR FIRST TOOLS", 14, GOLD)
	_label(right, "01  Simple workbench", 21)
	var bench_note := _label(right, "Gather supplies by hand, then build at the marked camp worksite.", 15, MUTED)
	bench_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bench_cost = _label(right, "", 16)
	bench_status = _label(right, "", 14, MUTED)
	bench_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bench_button = _button(right, "Build simple bench")
	bench_button.pressed.connect(func(): message_label.text = player.build_bench(); refresh())
	right.add_child(HSeparator.new())
	_label(right, "02  Stone axe", 21)
	var axe_note := _label(right, "Craft at your bench. Chop trees to unlock a supply of wood.", 15, MUTED)
	axe_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	axe_cost = _label(right, "", 16)
	axe_status = _label(right, "", 14, MUTED)
	axe_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	axe_button = _button(right, "Craft & equip stone axe")
	axe_button.pressed.connect(func():
		message_label.text = player.craft_axe()
		for i in range(Inventory.CAPACITY):
			if player.inventory.slots[i].get("item", "") == "stone_axe":
				selected = i
		refresh())
	message_label = _label(layout, "", 15, GOLD)
	message_label.custom_minimum_size.y = 22
	_label(layout, "E  Gather / use bench     •     I  Backpack     •     This clearing resets when restarted.", 13, MUTED)
	visible = false

func _input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and not event.echo and (event.physical_keycode == KEY_I or event.keycode == KEY_ESCAPE):
		player.close_inventory()
		get_viewport().set_input_as_handled()

func show_pack() -> void:
	visible = true
	message_label.text = ""
	refresh()
	slot_buttons[0].grab_focus()

func refresh() -> void:
	var inventory: RefCounted = player.inventory
	capacity_label.text = "YOUR BACKPACK    %d / %d slots" % [inventory.used_slots(), Inventory.CAPACITY]
	for i in range(Inventory.CAPACITY):
		var slot: Dictionary = inventory.slots[i]
		var item: String = slot.get("item", "")
		slot_buttons[i].set_pressed_no_signal(i == selected)
		slot_icons[i].item_id = item
		slot_icons[i].queue_redraw()
		slot_names[i].text = Inventory.ITEMS[item].name if not item.is_empty() else "Empty"
		slot_counts[i].text = str(slot.amount) if not slot.is_empty() else ""
		if item == "stone_axe" and player.axe_equipped:
			slot_counts[i].text = "Held"
	var chosen: Dictionary = inventory.slots[selected] if selected >= 0 else {}
	drop_button.disabled = chosen.is_empty()
	equip_button.disabled = chosen.get("item", "") != "stone_axe"
	equip_button.text = "Put axe away" if player.axe_equipped else "Equip axe"
	detail.text = Inventory.ITEMS[chosen.item].description if not chosen.is_empty() else "Choose a slot to inspect an item. If your pack fills up, drop a stack on the ground to make room."
	bench_cost.text = "Sticks  %d / 6     Stones  %d / 4" % [inventory.count("stick"), inventory.count("stone")]
	axe_cost.text = "Sticks  %d / 3     Stones  %d / 2" % [inventory.count("stick"), inventory.count("stone")]
	bench_status.text = player.bench_requirement()
	axe_status.text = player.axe_requirement()
	bench_button.disabled = not player.bench_requirement().is_empty()
	axe_button.disabled = not player.axe_requirement().is_empty()
	bench_button.text = "Bench built" if player.workbench.built else "Build simple bench"
	if bench_status.text.is_empty():
		bench_status.text = "Ready to build here."
	if axe_status.text.is_empty():
		axe_status.text = "Ready to craft. Takes one slot."

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
	style.set_corner_radius_all(5)
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
