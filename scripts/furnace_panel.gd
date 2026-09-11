extends "res://scripts/panel_base.gd"
## Load ore and wood into a furnace, watch it smelt, and take the ingots.
const Furnace = preload("res://scripts/furnace.gd")
var player: Node3D
var furnace: Node3D
var state_label: Label
var progress_bar: ProgressBar
var ore_label: Label
var fuel_label: Label
var ingot_label: Label
var ore_button: Button
var fuel_button: Button
var take_button: Button
var pickup_button: Button
var message_label: Label
var supply_label: Label
var auto_button: CheckButton
var metal_picker: OptionButton
var return_button: Button
var ore_heading: Label
var ingot_heading: Label

func setup(owner_player: Node3D) -> void:
	player = owner_player
	name = "FurnacePanel"
	var layout := _shell(880, 610)
	var header := HBoxContainer.new()
	layout.add_child(header)
	var heading := VBoxContainer.new()
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(heading)
	_label(heading, "ASH & IRON  /  SMELTING", 13, GOLD)
	_label(heading, "Stone furnace", 27)
	var close_button := _button(header, "Close  [Tab / Esc]")
	close_button.pressed.connect(func(): player.close_furnace())
	var modes := HBoxContainer.new()
	layout.add_child(modes)
	_label(modes, "METAL", 14, GOLD)
	metal_picker = OptionButton.new()
	metal_picker.add_item("Copper • first metal")
	metal_picker.add_item("Iron • existing supplies")
	modes.add_child(metal_picker)
	metal_picker.item_selected.connect(func(index: int):
		if not furnace.select_metal("copper" if index == 0 else "iron"):
			message_label.text = "Return loaded ore and take ingots before switching metals."
		refresh())
	return_button = _button(modes, "Return loaded ore")
	return_button.pressed.connect(func():
		# Prevent auto-feed immediately reloading the ore being returned.
		furnace.set_auto_feed(false)
		var returned: int = furnace.return_ore(player.inventory)
		message_label.text = "Returned %d ore. Auto-feed paused; take any ingots before changing metal." % returned
		refresh())
	state_label = _label(layout, "", 20, GOLD)
	progress_bar = ProgressBar.new()
	progress_bar.min_value = 0.0
	progress_bar.max_value = 1.0
	progress_bar.show_percentage = false
	progress_bar.custom_minimum_size.y = 16
	progress_bar.add_theme_stylebox_override("background", _style(Color("1d2a22"), Color("344335")))
	progress_bar.add_theme_stylebox_override("fill", _style(Color("c9702c"), Color("f0a24c")))
	layout.add_child(progress_bar)
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 16)
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(columns)
	var ore_bay := _bay(columns, "ORE", "Raw ore from marked outcrops.")
	ore_label = ore_bay.count
	ore_heading = ore_bay.heading
	ore_button = ore_bay.button
	ore_button.pressed.connect(func():
		var moved: int = furnace.load_from_sources(player.inventory, furnace.ore_item())
		message_label.text = "Loaded %d %s ore." % [moved, furnace.metal] if moved > 0 else "No room in the furnace, or no ore in your backpack or connected chests."
		refresh())
	var fuel_bay := _bay(columns, "WOOD", "One piece of timber fires each ingot.")
	fuel_label = fuel_bay.count
	fuel_button = fuel_bay.button
	fuel_button.pressed.connect(func():
		var moved: int = furnace.load_from_sources(player.inventory, "wood")
		message_label.text = "Loaded %d wood." % moved if moved > 0 else "No room in the furnace, or no wood in your backpack or connected chests."
		refresh())
	var ingot_bay := _bay(columns, "INGOTS", "Copper supplies fittings and the copper axe.")
	ingot_label = ingot_bay.count
	ingot_heading = ingot_bay.heading
	take_button = ingot_bay.button
	take_button.pressed.connect(func():
		var taken: int = furnace.take_ingots(player.inventory)
		message_label.text = "Took %d %s ingot%s." % [taken, furnace.metal, "" if taken == 1 else "s"] if taken > 0 else "Your backpack is full. Make room first."
		refresh())
	auto_button = CheckButton.new()
	auto_button.text = "Automatically feed from chests within 8 meters"
	auto_button.toggled.connect(func(enabled: bool):
		if is_instance_valid(furnace): furnace.set_auto_feed(enabled))
	layout.add_child(auto_button)
	supply_label = _label(layout, "", 14, GOLD)
	var note := _label(layout, "Two ore + one wood → one ingot in 12 seconds. Auto-feed reserves one batch at a time from nearby chests and stops when ingredients run out or ingots fill up.", 14, MUTED)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var footer := HBoxContainer.new()
	layout.add_child(footer)
	message_label = _label(footer, "", 15, GOLD)
	message_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pickup_button = _button(footer, "Pick up empty furnace")
	pickup_button.pressed.connect(func():
		var result: String = player.pickup_furnace(furnace)
		if visible:
			message_label.text = result
			refresh())
	visible = false

func _bay(parent: Node, title: String, caption: String) -> Dictionary:
	var bay := VBoxContainer.new()
	bay.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bay.add_theme_constant_override("separation", 6)
	parent.add_child(bay)
	var heading := _label(bay, title, 14, GOLD)
	var count := _label(bay, "", 30)
	var note := _label(bay, caption, 13, MUTED)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var button := _button(bay, "")
	return {"count": count, "button": button, "heading": heading}

func _input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and not event.echo and (event.physical_keycode in [KEY_E, KEY_TAB, KEY_I] or event.keycode == KEY_ESCAPE):
		player.close_furnace()
		get_viewport().set_input_as_handled()

func _process(_delta: float) -> void:
	if visible:
		refresh()

func open(target: Node3D) -> void:
	furnace = target
	message_label.text = ""
	visible = true
	refresh()
	ore_button.grab_focus()

func refresh() -> void:
	if not is_instance_valid(furnace):
		return
	metal_picker.select(0 if furnace.metal == "copper" else 1)
	metal_picker.disabled = furnace.ore > 0 or furnace.ingots > 0
	metal_picker.tooltip_text = "Return ore and take ingots before changing metal. Fuel stays in the furnace."
	return_button.disabled = furnace.ore == 0
	ore_heading.text = furnace.metal.to_upper() + " ORE"
	ingot_heading.text = furnace.metal.to_upper() + " INGOTS"
	if furnace.is_burning():
		state_label.text = "SMELTING  •  next ingot %d%%" % roundi(furnace.progress * 100)
	elif furnace.ingots > 0:
		state_label.text = "COLD  •  %d ingot%s ready to take" % [furnace.ingots, "" if furnace.ingots == 1 else "s"]
	else:
		state_label.text = "COLD  •  load %s ore and wood to light it" % furnace.metal
	progress_bar.value = furnace.progress
	ore_label.text = "%d / %d" % [furnace.ore, Furnace.CAPACITY]
	fuel_label.text = "%d / %d" % [furnace.fuel, Furnace.CAPACITY]
	ingot_label.text = "%d / %d" % [furnace.ingots, Furnace.CAPACITY]
	auto_button.set_pressed_no_signal(furnace.auto_feed)
	supply_label.text = "CONNECTED STORAGE  •  %d chest(s) within 8 m of this furnace" % furnace.linked_chests().size()
	var pack_ore: int = Inventory.count_across(furnace.sources(player.inventory), furnace.ore_item())
	var pack_wood: int = Inventory.count_across(furnace.sources(player.inventory), "wood")
	ore_button.text = "Load ore (%d available)" % pack_ore
	fuel_button.text = "Load wood (%d available)" % pack_wood
	ore_button.disabled = pack_ore == 0 or furnace.ore >= Furnace.CAPACITY
	fuel_button.disabled = pack_wood == 0 or furnace.fuel >= Furnace.CAPACITY
	take_button.text = "Take ingots"
	take_button.disabled = furnace.ingots == 0
	pickup_button.disabled = not furnace.is_empty()
	pickup_button.text = "Pick up empty furnace" if furnace.is_empty() else "Empty the furnace to pick it up"
