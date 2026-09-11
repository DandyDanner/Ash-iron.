extends SceneTree
const Paths = preload("res://tests/test_paths.gd")
const Profile = preload("res://scripts/character_profile.gd")
const GameSave = preload("res://scripts/game_save.gd")
var failures := 0

func _initialize() -> void:
	Profile.storage_path = Paths.path("craft_icons_profile_%d.json" % Time.get_ticks_usec())
	GameSave.storage_path = Paths.path("craft_icons_save_%d.json" % Time.get_ticks_usec())
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func ticks(count: int = 3) -> void:
	for i in range(count):
		await physics_frame
		await process_frame

func run() -> void:
	change_scene_to_file("res://scenes/main.tscn")
	await scene_changed
	await ticks()
	var player: Node3D = current_scene.get_node("Player")
	player.open_inventory()
	var panel: Control = player.inventory_panel
	await ticks()
	check(panel.craftables.size() == 10, "Not all ten craftables appear in the icon grid")
	var before: Array = player.inventory.to_data()
	for id in panel.craftables:
		var row: Dictionary = panel.craftables[id]
		check(not row.tile.disabled and not row.icon.item_id.is_empty(), "Unavailable recipe cannot be browsed: " + id)
		check(row.tile.tooltip_text.contains(row.recipe.description) and row.tile.tooltip_text.contains("Have / need"), "Hover omits use or recipe: " + id)
		row.tile.pressed.emit()
		check(panel.selected_recipe == id and row.card.visible, "Selecting an icon did not show its recipe: " + id)
		check(row.button.disabled, "Unavailable recipe can be crafted: " + id)
		await ticks()
		check(root.get_visible_rect().encloses(row.card.get_global_rect()), "Recipe details extend beyond the viewport: " + id)
	check(player.inventory.to_data() == before and not is_instance_valid(player.workbench), "Browsing spent resources or built a bench")
	var grid: Control = panel.find_child("CraftableGrid", true, false)
	check(root.get_visible_rect().encloses(grid.get_global_rect()), "Icon grid extends beyond the viewport")
	# Keyboard focus exposes the same details without relying on a mouse hover.
	panel.craftables.bench.tile.grab_focus()
	await ticks()
	check(panel.selected_recipe == "bench", "Keyboard focus did not expose the recipe")
	player.global_position = Vector3(12, 1.1, 12)
	player.inventory.add("stick", 9)
	player.inventory.add("stone", 6)
	panel.refresh()
	check(panel.craftables.bench.tile.tooltip_text.contains("Sticks  9 / 6") and not panel.bench_button.disabled, "Available material totals did not refresh")
	panel.bench_button.pressed.emit()
	check(player.inventory.count("bench") == 1 and not is_instance_valid(player.workbench), "Workbench craft did not create an inventory item")
	panel.place_button.pressed.emit()
	await ticks()
	check(is_instance_valid(player.workbench), "Place workbench action failed")
	panel.craftables.stone_axe.tile.pressed.emit()
	panel.axe_button.pressed.emit()
	check(player.inventory.count("stone_axe") == 1 and player.equipped_item == "stone_axe" and panel.craftables.stone_axe.availability.text == "OWNED", "Craft action did not produce/equip one axe")
	var chest := preload("res://scripts/storage_chest.gd").new()
	current_scene.add_child(chest)
	chest.position = player.workbench.position + Vector3(2, 0, 0)
	chest.storage.add("wood", 3)
	chest.storage.add("stick", 2)
	panel.refresh()
	check(panel.craftables.bow.tile.tooltip_text.contains("Wood  3 / 3") and not panel.recipe_rows.bow.button.disabled, "Hover totals omitted connected storage")
	panel.craftables.bow.tile.pressed.emit()
	panel.recipe_rows.bow.button.pressed.emit()
	check(player.inventory.count("bow") == 1 and chest.storage.is_empty(), "Icon crafting failed to use connected materials")
	# Output quantity and current missing ingredients are visible for batch recipes.
	check(panel.craftables.arrows.recipe.amount == 5 and panel.craftables.split_wood.recipe.amount == 4, "Batch output quantities were lost")
	check(panel.craftables.arrows.tile.tooltip_text.contains("Missing:"), "Missing materials are not explained")
	var tooltip: Control = panel.craftables.arrows.tile._make_custom_tooltip(panel.craftables.arrows.tile.tooltip_text)
	root.add_child(tooltip)
	await ticks()
	check(tooltip.size.x < 400 and tooltip.size.y < 600, "Hover card is too large for the game window")
	tooltip.queue_free()
	GameSave.clear()
	print("CRAFTING ICONS: %s" % ("PASS — all recipes, hover details, browsing/focus, exact craft, connected stock, output counts, and bounds" if failures == 0 else "FAIL"))
	quit(1 if failures else 0)
