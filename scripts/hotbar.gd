extends "res://scripts/panel_base.gd"
## Shortcuts point to item types in the backpack. They never create extra storage.
var player: Node3D
var cells: Array[Button] = []
var icons: Array[Control] = []
var captions: Array[Label] = []

func setup(owner_player: Node3D) -> void:
	player = owner_player
	name = "Hotbar"
	_build_theme()
	set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	offset_left = -355
	offset_right = 355
	offset_top = -103
	offset_bottom = -19
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 7)
	add_child(row)
	for i in range(10):
		var button := Button.new()
		button.custom_minimum_size = Vector2(64, 70)
		button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.focus_mode = Control.FOCUS_NONE
		button.toggle_mode = true
		row.add_child(button)
		cells.append(button)
		var icon := Icon.new()
		icon.position = Vector2(5, 15)
		icon.size = Vector2(54, 48)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(icon)
		icons.append(icon)
		var caption := _label(button, str((i + 1) % 10), 13, GOLD)
		caption.position = Vector2(8, 3)
		captions.append(caption)
	var hint := _label(self, "1–9, 0  Equip / holster    •    I  Backpack    •    V  View    •    F11  Full screen", 13, INK)
	hint.position = Vector2(0, 72)
	hint.size.x = 703
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	refresh()

func refresh() -> void:
	for i in range(cells.size()):
		var item: String = player.hotbar[i]
		var available: bool = not item.is_empty() and player.inventory.count(item) > 0
		icons[i].item_id = item
		icons[i].modulate.a = 1.0 if available else 0.25
		icons[i].queue_redraw()
		cells[i].set_pressed_no_signal(available and player.equipped_item == item)
