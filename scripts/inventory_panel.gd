extends "res://scripts/panel_base.gd"
var player: Node3D
var selected := -1
var pack: Dictionary
var capacity_label: Label
var detail: Label
var equip_button: Button
var place_button: Button
var drop_button: Button
var bench_button: Button
var axe_button: Button
var chest_button: Button
var save_button: Button
var bench_cost: Label
var axe_cost: Label
var chest_cost: Label
var bench_status: Label
var axe_status: Label
var chest_status: Label
var message_label: Label
var storage_note: Label

func setup(owner_player: Node3D) -> void:
	player = owner_player
	name = "InventoryPanel"
	var layout := _shell(1110, 720)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	layout.add_child(header)
	var heading := VBoxContainer.new()
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(heading)
	_label(heading, "ASH & IRON  /  FIRST DAYS", 13, GOLD)
	_label(heading, "A little room. A place to begin.", 27)
	save_button = _button(header, "Save game")
	save_button.pressed.connect(func(): message_label.text = player.save_game_now())
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
	pack = _slot_grid(left, Inventory.CAPACITY, 4, func(i: int): selected = i; refresh())
	detail = _label(left, "", 16)
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.custom_minimum_size.y = 80
	var actions := HBoxContainer.new()
	left.add_child(actions)
	equip_button = _button(actions, "Equip axe")
	equip_button.pressed.connect(func(): player.toggle_axe(); refresh())
	place_button = _button(actions, "Place chest here")
	place_button.pressed.connect(func():
		message_label.text = player.place_chest(selected)
		refresh())
	drop_button = _button(actions, "Drop selected stack")
	drop_button.pressed.connect(func():
		var result: String = player.drop_slot(selected)
		message_label.text = result
		refresh())
	storage_note = _label(left, "", 14, MUTED)
	storage_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var right := VBoxContainer.new()
	right.custom_minimum_size.x = 380
	right.add_theme_constant_override("separation", 6)
	columns.add_child(right)
	_label(right, "MAKE YOUR FIRST TOOLS", 14, GOLD)
	_label(right, "01  Simple workbench", 20)
	var bench_note := _label(right, "Gather supplies by hand, then build at the marked camp worksite.", 14, MUTED)
	bench_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bench_cost = _label(right, "", 15)
	bench_status = _label(right, "", 13, MUTED)
	bench_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bench_button = _button(right, "Build simple bench")
	bench_button.pressed.connect(func(): message_label.text = player.build_bench(); refresh())
	right.add_child(HSeparator.new())
	_label(right, "02  Stone axe", 20)
	var axe_note := _label(right, "Craft at your bench. Chop trees to unlock a supply of wood.", 14, MUTED)
	axe_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	axe_cost = _label(right, "", 15)
	axe_status = _label(right, "", 13, MUTED)
	axe_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	axe_button = _button(right, "Craft & equip stone axe")
	axe_button.pressed.connect(func():
		message_label.text = player.craft_axe()
		selected = _find("stone_axe", selected)
		refresh())
	right.add_child(HSeparator.new())
	_label(right, "03  Storage chest", 20)
	var chest_note := _label(right, "Craft from felled timber, then place it near camp to keep supplies between trips.", 14, MUTED)
	chest_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	chest_cost = _label(right, "", 15)
	chest_status = _label(right, "", 13, MUTED)
	chest_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	chest_button = _button(right, "Craft storage chest")
	chest_button.pressed.connect(func():
		message_label.text = player.craft_chest()
		selected = _find("chest", selected)
		refresh())
	message_label = _label(layout, "", 15, GOLD)
	message_label.custom_minimum_size.y = 22
	_label(layout, "E  Gather / bench / chest     •     I  Backpack     •     Your progress in the clearing is saved as you play.", 13, MUTED)
	visible = false

func _input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and not event.echo and (event.physical_keycode == KEY_I or event.keycode == KEY_ESCAPE):
		player.close_inventory()
		get_viewport().set_input_as_handled()

func show_pack() -> void:
	visible = true
	message_label.text = ""
	refresh()
	pack.buttons[0].grab_focus()

func _find(item: String, fallback: int) -> int:
	for i in range(Inventory.CAPACITY):
		if player.inventory.slots[i].get("item", "") == item:
			return i
	return fallback

func refresh() -> void:
	var inventory: RefCounted = player.inventory
	capacity_label.text = "YOUR BACKPACK    %d / %d slots" % [inventory.used_slots(), Inventory.CAPACITY]
	_refresh_grid(pack, inventory, selected, "stone_axe" if player.axe_equipped else "")
	var chosen: Dictionary = inventory.slots[selected] if selected >= 0 else {}
	drop_button.disabled = chosen.is_empty()
	equip_button.disabled = chosen.get("item", "") != "stone_axe"
	equip_button.text = "Put axe away" if player.axe_equipped else "Equip axe"
	place_button.disabled = chosen.get("item", "") != "chest"
	detail.text = Inventory.ITEMS[chosen.item].description if not chosen.is_empty() else "Choose a slot to inspect an item. If your pack fills up, drop a stack on the ground to make room."
	var connected: int = player.workbench.linked_chests().size()
	if connected == 0:
		storage_note.text = "Recipes use your backpack. A chest placed within a few steps of the bench is connected and supplies materials too."
	else:
		storage_note.text = "Connected storage: %d chest%s near the bench. Recipes take from your backpack first, then from the chest%s." % [connected, "" if connected == 1 else "s", "" if connected == 1 else "s"]
	bench_cost.text = "Sticks  %d / 6     Stones  %d / 4" % [player.stock("stick"), player.stock("stone")]
	axe_cost.text = "Sticks  %d / 3     Stones  %d / 2" % [player.stock("stick"), player.stock("stone")]
	chest_cost.text = "Wood  %d / 5     Sticks  %d / 2" % [player.stock("wood"), player.stock("stick")]
	bench_status.text = player.bench_requirement()
	axe_status.text = player.axe_requirement()
	chest_status.text = player.chest_requirement()
	bench_button.disabled = not player.bench_requirement().is_empty()
	axe_button.disabled = not player.axe_requirement().is_empty()
	chest_button.disabled = not player.chest_requirement().is_empty()
	bench_button.text = "Bench built" if player.workbench.built else "Build simple bench"
	if bench_status.text.is_empty():
		bench_status.text = "Ready to build here."
	if axe_status.text.is_empty():
		axe_status.text = "Ready to craft. Takes one slot."
	if chest_status.text.is_empty():
		chest_status.text = "Ready to craft. Carry it, then place it where you like."
