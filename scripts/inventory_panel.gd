extends "res://scripts/panel_base.gd"
var player: Node3D
var selected := -1
var pack: Dictionary
var capacity_label: Label
var pack_help: Label
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
var shortcut_buttons: Array[Button] = []
var recipe_rows := {}
var quit_button: Button
var pickup_bench_button: Button
var craftables := {}
var selected_recipe := "bench"
const CraftableTile = preload("res://scripts/craftable_tile.gd")

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
	_label(heading, "Backpack & workbench", 27)
	save_button = _button(header, "Save game")
	save_button.pressed.connect(func(): message_label.text = player.save_game_now())
	quit_button = _button(header, "Save & Quit")
	quit_button.pressed.connect(player.save_and_quit)
	var close_button := _button(header, "Close  [Tab / Esc]")
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
	pack_help = _label(left, "Resources stack to 10. Each tool takes one slot.", 14, MUTED)
	var pack_scroll := ScrollContainer.new()
	pack_scroll.custom_minimum_size.y = 210
	pack_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left.add_child(pack_scroll)
	pack = _slot_grid(pack_scroll, Inventory.EXPLORER_CAPACITY, 4, func(i: int): selected = i; refresh(), Vector2(138, 96))
	detail = _label(left, "", 16)
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.custom_minimum_size.y = 54
	var actions := HBoxContainer.new()
	left.add_child(actions)
	equip_button = _button(actions, "Equip axe")
	equip_button.pressed.connect(func():
		var item: String = player.inventory.slots[selected].get("item", "") if selected >= 0 else ""
		player.equip_item("" if player.equipped_item == item else item)
		refresh())
	place_button = _button(actions, "Place chest here")
	place_button.pressed.connect(func():
		message_label.text = player.place_selected(selected)
		refresh())
	drop_button = _button(actions, "Drop selected stack")
	drop_button.pressed.connect(func():
		var result: String = player.drop_slot(selected)
		message_label.text = result
		refresh())
	_label(left, "HOTBAR  •  Select a tool, then click a number or press its key.", 13, GOLD)
	var shortcuts := HBoxContainer.new()
	shortcuts.add_theme_constant_override("separation", 5)
	left.add_child(shortcuts)
	for i in range(10):
		var button := _button(shortcuts, str((i + 1) % 10))
		button.custom_minimum_size = Vector2(48, 34)
		button.pressed.connect(_assign_shortcut.bind(i))
		shortcut_buttons.append(button)
	_label(left, "Select an empty backpack slot to clear a shortcut. Tools still use pack space.", 13, MUTED)
	storage_note = _label(left, "", 14, MUTED)
	storage_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var scroll := ScrollContainer.new()
	scroll.name = "Recipes"
	scroll.custom_minimum_size.x = 390
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	columns.add_child(scroll)
	var right := VBoxContainer.new()
	right.custom_minimum_size.x = 370
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 6)
	scroll.add_child(right)
	_label(right, "CRAFTABLES", 16, GOLD)
	var help := _label(right, "Hover for recipe & use. Select an icon, then craft below.", 14, MUTED)
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var grid := GridContainer.new()
	grid.name = "CraftableGrid"
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	right.add_child(grid)
	var cards := VBoxContainer.new()
	cards.name = "RecipeDetails"
	var catalog := {
		"bench": {"name": "Simple workbench", "short": "Workbench", "output": "bench", "amount": 1, "cost": Inventory.BENCH_COST, "description": Inventory.ITEMS.bench.description},
		"stone_axe": {"name": "Stone axe", "short": "Stone axe", "output": "stone_axe", "amount": 1, "cost": Inventory.AXE_COST, "description": Inventory.ITEMS.stone_axe.description},
		"chest": {"name": "Storage chest", "short": "Chest", "output": "chest", "amount": 1, "cost": Inventory.CHEST_COST, "description": "Place a chest to store supplies in twelve slots. Chests near the bench supply crafting materials."}
	}
	var short_names := {"stone_spear": "Spear","bow": "Bow", "arrows": "Arrows", "stone_pickaxe": "Pickaxe", "torch": "Torch", "split_wood": "Sticks", "furnace": "Furnace", "explorer_pack": "Pack +4"}
	for id in Inventory.RECIPES:
		catalog[id] = Inventory.RECIPES[id].duplicate(true)
		catalog[id].short = short_names.get(id, catalog[id].name)
	for id in catalog:
		var recipe: Dictionary = catalog[id]
		var tile := CraftableTile.new()
		tile.name = "Recipe_" + id
		tile.custom_minimum_size = Vector2(86, 94)
		tile.toggle_mode = true
		tile.pressed.connect(_select_recipe.bind(id))
		tile.focus_entered.connect(_select_recipe.bind(id))
		grid.add_child(tile)
		var icon := Icon.new()
		icon.item_id = recipe.output
		icon.position = Vector2(13, 3)
		icon.size = Vector2(60, 56)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tile.add_child(icon)
		var title := _label(tile, recipe.short, 12)
		title.position = Vector2(2, 60)
		title.size.x = 82
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var availability := _label(tile, "", 10, MUTED)
		availability.position = Vector2(2, 77)
		availability.size.x = 82
		availability.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if int(recipe.amount) > 1:
			var amount := _label(tile, "×%d" % recipe.amount, 13, GOLD)
			amount.position = Vector2(63, 4)
		var card := VBoxContainer.new()
		card.add_theme_constant_override("separation", 8)
		cards.add_child(card)
		var card_title := _label(card, recipe.name, 20)
		card_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var note := _label(card, recipe.description, 14, MUTED)
		note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var cost := _label(card, "", 15)
		cost.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var status := _label(card, "", 14, MUTED)
		status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var button := _button(card, "Craft " + recipe.short.to_lower())
		craftables[id] = {"tile": tile, "icon": icon, "availability": availability, "card": card, "recipe": recipe, "cost": cost, "status": status, "button": button}
		match id:
			"bench":
				bench_button = button
				bench_cost = cost
				bench_status = status
				button.pressed.connect(func():
					message_label.text = player.craft_bench()
					selected = _find("bench", selected)
					refresh())
			"stone_axe":
				axe_button = button
				axe_cost = cost
				axe_status = status
				button.text = "Craft & equip stone axe"
				button.pressed.connect(func():
					message_label.text = player.craft_axe()
					selected = _find("stone_axe", selected)
					refresh())
			"chest":
				chest_button = button
				chest_cost = cost
				chest_status = status
				button.pressed.connect(func():
					message_label.text = player.craft_chest()
					selected = _find("chest", selected)
					refresh())
			_:
				button.pressed.connect(_craft_recipe.bind(id))
				recipe_rows[id] = craftables[id]
	right.add_child(HSeparator.new())
	right.add_child(cards)
	pickup_bench_button = _button(right, "Pick up this workbench")
	pickup_bench_button.pressed.connect(func():
		message_label.text = player.pickup_workbench(player.workbench)
		selected = _find("bench", selected)
		refresh())
	_select_recipe(selected_recipe)
	message_label = _label(layout, "", 15, GOLD)
	message_label.custom_minimum_size.y = 22
	_label(layout, "E  Gather / bench / chest / furnace     •     Tab  Backpack     •     Your progress in the clearing is saved as you play.", 13, MUTED)
	visible = false

func _input(event: InputEvent) -> void:
	if not visible or not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.physical_keycode in [KEY_TAB, KEY_I] or event.keycode == KEY_ESCAPE:
		player.close_inventory()
		get_viewport().set_input_as_handled()
	else:
		var index: int = player.hotbar_key(event)
		if index >= 0:
			_assign_shortcut(index)
			get_viewport().set_input_as_handled()

func _assign_shortcut(index: int) -> void:
	if selected < 0:
		message_label.text = "Select a tool first, or an empty backpack slot to clear a shortcut."
		return
	message_label.text = player.assign_hotbar(index, player.inventory.slots[selected].get("item", ""))
	refresh()

func _craft_recipe(id: String) -> void:
	message_label.text = player.craft_recipe(id)
	selected = _find(Inventory.RECIPES[id].output, selected)
	refresh()

func show_pack() -> void:
	visible = true
	message_label.text = ""
	refresh()
	pack.buttons[0].grab_focus()

func _find(item: String, fallback: int) -> int:
	for i in range(player.inventory.slots.size()):
		if player.inventory.slots[i].get("item", "") == item:
			return i
	return fallback

func refresh() -> void:
	var inventory: RefCounted = player.inventory
	capacity_label.text = "YOUR BACKPACK    %d / %d slots" % [inventory.used_slots(), inventory.slots.size()]
	pack_help.text = "Explorer Pack fitted • Scroll down for slots 9–12." if inventory.slots.size() > Inventory.CAPACITY else "Resources stack to 10. Each tool takes one slot."
	_refresh_grid(pack, inventory, selected, player.equipped_item)
	var chosen: Dictionary = inventory.slots[selected] if selected >= 0 else {}
	drop_button.disabled = chosen.is_empty()
	equip_button.disabled = not chosen.get("item", "") in Inventory.EQUIPPABLE
	equip_button.text = "Put away" if not chosen.is_empty() and player.equipped_item == chosen.item else "Equip tool"
	place_button.disabled = not chosen.get("item", "") in ["chest", "bench", "furnace"]
	match chosen.get("item", ""):
		"bench":
			place_button.text = "Place workbench here"
		"furnace":
			place_button.text = "Place furnace here"
		_:
			place_button.text = "Place chest here"
	detail.text = Inventory.ITEMS[chosen.item].description if not chosen.is_empty() else "Choose a slot to inspect an item. If your pack fills up, drop a stack on the ground to make room."
	var connected: int = player.linked_chests().size()
	pickup_bench_button.visible = is_instance_valid(player.workbench) and player.workbench.within_reach(player)
	if connected == 0:
		storage_note.text = "Recipes use your backpack. A chest placed within a few steps of the bench is connected and supplies materials too."
	else:
		storage_note.text = "Connected storage: %d chest%s near the bench. Recipes take from your backpack first, then from the chest%s." % [connected, "" if connected == 1 else "s", "" if connected == 1 else "s"]
	for i in range(shortcut_buttons.size()):
		var item: String = player.hotbar[i]
		shortcut_buttons[i].text = str((i + 1) % 10) + (" •" if not item.is_empty() else "")
		shortcut_buttons[i].tooltip_text = Inventory.ITEMS[item].name if not item.is_empty() else "Empty shortcut"
	for id in craftables:
		var row: Dictionary = craftables[id]
		var recipe: Dictionary = row.recipe
		var amounts := PackedStringArray()
		var missing := PackedStringArray()
		for item in recipe.cost:
			var have: int = player.stock(item)
			var need: int = recipe.cost[item]
			amounts.append("%s  %d / %d" % [Inventory.ITEMS[item].name, have, need])
			if have < need:
				var missing_name: String = Inventory.ITEMS[item].name.to_lower()
				if need - have == 1:
					missing_name = missing_name.trim_suffix("s")
				missing.append("%d %s" % [need - have, missing_name])
		row.cost.text = "MATERIALS  •  Have / need\n" + "    ".join(amounts)
		var reason := ""
		match id:
			"bench": reason = player.bench_requirement()
			"stone_axe": reason = player.axe_requirement()
			"chest": reason = player.chest_requirement()
			_: reason = player.recipe_requirement(id)
		var ready := reason.is_empty()
		var status := reason if not ready else "Ready to craft here."
		row.status.text = status
		row.status.add_theme_color_override("font_color", GOLD if ready else MUTED)
		row.button.disabled = not ready
		row.availability.text = "READY" if ready else "UNAVAILABLE"
		if recipe.output in Inventory.EQUIPPABLE and inventory.count(recipe.output) > 0:
			row.availability.text = "OWNED"
		if id == "explorer_pack" and inventory.slots.size() >= Inventory.EXPLORER_CAPACITY:
			row.availability.text = "FITTED"
		row.icon.modulate.a = 1.0 if ready else 0.60
		row.tile.tooltip_text = recipe.name + "\n\n" + recipe.description + "\n\nMATERIALS • Have / need\n" + "\n".join(amounts)
		if not missing.is_empty():
			row.tile.tooltip_text += "\nMissing: " + ", ".join(missing)
		row.tile.tooltip_text += "\n\n" + status
		row.tile.tooltip_text += "\nMaterials include connected storage.\nSelect this icon, then use the craft button."
	bench_button.text = "Craft workbench"

func _select_recipe(id: String) -> void:
	if not craftables.has(id):
		return
	selected_recipe = id
	for key in craftables:
		craftables[key].card.visible = key == id
		craftables[key].tile.set_pressed_no_signal(key == id)
