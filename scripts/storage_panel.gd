extends "res://scripts/panel_base.gd"
## Move stacks between the backpack and an opened storage chest.
var player: Node3D
var chest: Node3D
var pack: Dictionary
var store: Dictionary
var selected_pack := -1
var selected_chest := -1
var pack_label: Label
var chest_label: Label
var detail: Label
var store_button: Button
var take_button: Button
var pickup_button: Button
var message_label: Label

func setup(owner_player: Node3D) -> void:
	player = owner_player
	name = "StoragePanel"
	var layout := _shell(1200, 630)
	var header := HBoxContainer.new()
	layout.add_child(header)
	var heading := VBoxContainer.new()
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(heading)
	_label(heading, "ASH & IRON  /  CAMP STORAGE", 13, GOLD)
	_label(heading, "Somewhere to keep what you carry home.", 27)
	var close_button := _button(header, "Close  [E / Esc]")
	close_button.pressed.connect(func(): player.close_storage())
	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 18)
	layout.add_child(columns)
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 10)
	columns.add_child(left)
	pack_label = _label(left, "", 16, GOLD)
	pack = _slot_grid(left, Inventory.CAPACITY, 4, func(i: int): selected_pack = i; selected_chest = -1; refresh(), Vector2(118, 100))
	var middle := VBoxContainer.new()
	middle.alignment = BoxContainer.ALIGNMENT_CENTER
	middle.add_theme_constant_override("separation", 12)
	columns.add_child(middle)
	store_button = _button(middle, "Store  →")
	store_button.pressed.connect(func():
		message_label.text = _move(player.inventory, selected_pack, chest.storage, "Stored")
		refresh())
	take_button = _button(middle, "←  Take")
	take_button.pressed.connect(func():
		message_label.text = _move(chest.storage, selected_chest, player.inventory, "Took")
		refresh())
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 10)
	columns.add_child(right)
	chest_label = _label(right, "", 16, GOLD)
	store = _slot_grid(right, Inventory.CHEST_CAPACITY, 4, func(i: int): selected_chest = i; selected_pack = -1; refresh(), Vector2(118, 100))
	detail = _label(layout, "", 16)
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.custom_minimum_size.y = 44
	var footer := HBoxContainer.new()
	layout.add_child(footer)
	message_label = _label(footer, "", 15, GOLD)
	message_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pickup_button = _button(footer, "Pick up empty chest")
	pickup_button.pressed.connect(func():
		var result: String = player.pickup_chest(chest)
		if visible:
			message_label.text = result
			refresh())
	visible = false

func _input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and not event.echo and (event.physical_keycode == KEY_E or event.physical_keycode == KEY_I or event.keycode == KEY_ESCAPE):
		player.close_storage()
		get_viewport().set_input_as_handled()

func open(target_chest: Node3D) -> void:
	chest = target_chest
	selected_pack = -1
	selected_chest = -1
	message_label.text = ""
	visible = true
	refresh()
	pack.buttons[0].grab_focus()

func _move(source: RefCounted, index: int, target: RefCounted, verb: String) -> String:
	if index < 0 or index >= source.slots.size() or source.slots[index].is_empty():
		return "Select a stack first."
	var item: String = source.slots[index].item
	var moved: int = source.move_slot(index, target)
	if moved == 0:
		return "No room on that side. Take something out first."
	return "%s %d %s." % [verb, moved, Inventory.ITEMS[item].name.to_lower()]

func refresh() -> void:
	if not is_instance_valid(chest):
		return
	pack_label.text = "YOUR BACKPACK    %d / %d slots" % [player.inventory.used_slots(), Inventory.CAPACITY]
	chest_label.text = "STORAGE CHEST    %d / %d slots" % [chest.storage.used_slots(), Inventory.CHEST_CAPACITY]
	_refresh_grid(pack, player.inventory, selected_pack, "stone_axe" if player.axe_equipped else "")
	_refresh_grid(store, chest.storage, selected_chest)
	var chosen: Dictionary = {}
	if selected_pack >= 0:
		chosen = player.inventory.slots[selected_pack]
	elif selected_chest >= 0:
		chosen = chest.storage.slots[selected_chest]
	store_button.disabled = selected_pack < 0 or player.inventory.slots[selected_pack].is_empty()
	take_button.disabled = selected_chest < 0 or chest.storage.slots[selected_chest].is_empty()
	pickup_button.disabled = not chest.storage.is_empty()
	pickup_button.text = "Pick up empty chest" if chest.storage.is_empty() else "Empty the chest to pick it up"
	detail.text = Inventory.ITEMS[chosen.item].description if not chosen.is_empty() else "Select a stack, then Store or Take. Resources stack to 10 per slot on either side. Everything here is kept when you leave and come back."
