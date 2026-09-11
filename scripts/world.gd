extends Node3D
## Owns world progress: gathers the clearing's state, saves it, and restores it on entry.
const GameSave = preload("res://scripts/game_save.gd")
const Inventory = preload("res://scripts/inventory.gd")
const Pickup = preload("res://scripts/resource_pickup.gd")
const Bundle = preload("res://scripts/wood_bundle.gd")
const Arrow = preload("res://scripts/arrow_projectile.gd")
const Chest = preload("res://scripts/storage_chest.gd")
const Bellmaw = preload("res://scripts/bellmaw.gd")
const Trail = preload("res://scripts/echo_trail.gd")
const Boar = preload("res://scripts/bristleback.gd")
const Bench = preload("res://scripts/workbench.gd")
const Furnace = preload("res://scripts/furnace.gd")
const AUTOSAVE_INTERVAL := 15.0
const DIRTY_DELAY := 1.0
var bellmaw: Node3D
var boar: Node3D
var player: Node3D
var dirty := false
var since_save := 0.0
var loaded_from_save := false
var last_save_error: Error = OK
signal quit_requested


func _ready() -> void:
	get_tree().auto_accept_quit = false
	player = get_node_or_null("Player")
	boar = Boar.new()
	boar.name = "Bristleback"
	boar.position = Boar.HOME
	add_child(boar)
	var trail := Trail.new()
	trail.name = "EchoTrail"
	add_child(trail)
	bellmaw = Bellmaw.new()
	bellmaw.name = "Bellmaw"
	bellmaw.position = Bellmaw.HOME
	add_child(bellmaw)
	for i in range(3):
		var spot: Vector2 = [Vector2(-12, -8), Vector2(8, -18), Vector2(-15, 8)][i]
		var vein := preload("res://scripts/iron_vein.gd").new()
		vein.ore_id = "copper_ore"
		vein.name = "CopperVein%d" % (i + 1)
		vein.position = Vector3(spot.x, preload("res://scripts/visual_clearing.gd").terrain_height(spot.x, spot.y), spot.y)
		add_child(vein)
	var data := GameSave.load_state()
	if not data.is_empty():
		_apply(data)
		loaded_from_save = true

func _exit_tree() -> void:
	get_tree().auto_accept_quit = true

func _process(delta: float) -> void:
	since_save += delta
	if (dirty and since_save >= DIRTY_DELAY) or since_save >= AUTOSAVE_INTERVAL:
		save_game()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and is_inside_tree():
		request_quit()

func request_quit() -> Error:
	var result := save_game()
	if result == OK:
		quit_requested.emit()
		get_tree().quit()
	elif is_instance_valid(player):
		player.show_quit_error()
	return result

func mark_dirty() -> void:
	dirty = true

func save_game() -> Error:
	if not is_instance_valid(player):
		return ERR_UNAVAILABLE
	last_save_error = GameSave.save_state(to_data())
	dirty = last_save_error != OK
	since_save = 0.0
	if player.has_method("note_saved"):
		player.note_saved(last_save_error)
	return last_save_error

func to_data() -> Dictionary:
	var workbenches := []
	for bench in get_tree().get_nodes_in_group("workbenches"):
		if not bench.is_queued_for_deletion():
			workbenches.append(bench.to_data())
	var trees := []
	for tree in get_tree().get_nodes_in_group("harvest_trees"):
		trees.append({"name": tree.name, "hits_left": tree.hits_left})
	var pickups := []
	for pickup in get_tree().get_nodes_in_group("pickups"):
		if pickup.is_queued_for_deletion() or pickup.collected:
			continue
		pickups.append({"item": pickup.item_id, "amount": pickup.amount, "x": pickup.global_position.x, "y": pickup.global_position.y, "z": pickup.global_position.z, "yaw": pickup.rotation.y})
	var bundles := []
	for bundle in get_tree().get_nodes_in_group("wood_bundles"):
		if bundle.is_queued_for_deletion() or bundle.collected:
			continue
		bundles.append({"amount": bundle.amount, "x": bundle.global_position.x, "y": bundle.global_position.y, "z": bundle.global_position.z})
	var chests := []
	for chest in get_tree().get_nodes_in_group("chests"):
		if not chest.is_queued_for_deletion():
			chests.append(chest.to_data())
	var boulders := []
	for rock in get_tree().get_nodes_in_group("mineable_rocks"):
		boulders.append({"name": rock.name, "hits_left": rock.hits_left})
	var veins := []
	for vein in get_tree().get_nodes_in_group("iron_veins") + get_tree().get_nodes_in_group("copper_veins"):
		veins.append({"name": vein.name, "hits_left": vein.hits_left})
	var furnaces := []
	for furnace in get_tree().get_nodes_in_group("furnaces"):
		if not furnace.is_queued_for_deletion():
			furnaces.append(furnace.to_data())
	var arrows := []
	for arrow in get_tree().get_nodes_in_group("flying_arrows"):
		if not arrow.is_queued_for_deletion() and not arrow.landed:
			arrows.append(arrow.to_data())
	return {
		"boar": boar.to_data(),
		"bellmaw": bellmaw.to_data(),
		"arrows": arrows,
		"boulders": boulders,
		"veins": veins,
		"furnaces": furnaces,
		"player": {
			"x": player.global_position.x, "y": player.global_position.y, "z": player.global_position.z,
			"yaw": player.rotation.y, "pitch": player.camera.rotation.x,
			"explorer_pack": player.inventory.slots.size() == Inventory.EXPLORER_CAPACITY,
			"slots": player.inventory.to_data(), "axe_equipped": player.axe_equipped,
			"equipped_item": player.equipped_item, "hotbar": player.hotbar.duplicate(),
			"crafting": player.crafting.to_data(), "third_person": player.view_rig.third_person, "health": player.health, "stamina": player.stamina.to_data()
		},
		"workbenches": workbenches,
		"trees": trees, "pickups": pickups, "bundles": bundles, "chests": chests
	}

func _apply(data: Dictionary) -> void:
	# The fresh clearing is already built; replace its loose resources with the saved snapshot.
	var resources: Node = get_node_or_null("ClearingResources")
	if resources == null:
		resources = self
	for node in get_tree().get_nodes_in_group("pickups") + get_tree().get_nodes_in_group("wood_bundles"):
		node.collected = true
		node.get_parent().remove_child(node)
		node.queue_free()
	var index := 0
	for entry in _list(data.get("pickups")):
		var item := str(_dict(entry).get("item", ""))
		var amount := int(_num(_dict(entry).get("amount"), 0.0))
		if not Inventory.ITEMS.has(item) or amount <= 0:
			continue
		var pickup := Pickup.new()
		pickup.item_id = item
		pickup.amount = mini(amount, int(Inventory.ITEMS[item].stack) * Inventory.CAPACITY)
		pickup.name = "%s_%d" % [item, index]
		index += 1
		resources.add_child(pickup)
		pickup.global_position = _vec(_dict(entry), Vector3(0, 0.22, 0))
		pickup.rotation.y = _num(_dict(entry).get("yaw"), 0.0)
	for entry in _list(data.get("bundles")):
		var amount := int(_num(_dict(entry).get("amount"), 0.0))
		if amount <= 0:
			continue
		var bundle := Bundle.new()
		bundle.amount = mini(amount, Bundle.AMOUNT)
		add_child(bundle)
		bundle.global_position = _vec(_dict(entry), Vector3.ZERO)
	var trees := {}
	for tree in get_tree().get_nodes_in_group("harvest_trees"):
		trees[tree.name] = tree
	for entry in _list(data.get("trees")):
		var tree: Node3D = trees.get(str(_dict(entry).get("name", "")))
		if tree:
			tree.restore(int(_num(_dict(entry).get("hits_left"), float(tree.MAX_HITS))))
	var saved_benches := _list(data.get("workbenches"))
	# Formats 1–4 recorded only the fixed camp bench's built flag.
	if not data.has("workbenches") and _dict(data.get("workbench")).get("built", false) == true:
		saved_benches = [{"x": -3.5, "y": 0.2, "z": 0.3, "yaw": 0.0}]
	for entry in saved_benches:
		if not entry is Dictionary:
			continue
		var bench := Bench.new()
		add_child(bench)
		bench.global_position = _vec(entry, Vector3(-3.5, 0.2, 0.3))
		bench.rotation.y = _num(entry.get("yaw"), 0.0)
	for entry in _list(data.get("chests")):
		var chest := Chest.new()
		add_child(chest)
		chest.global_position = _vec(_dict(entry), Vector3.ZERO)
		chest.rotation.y = _num(_dict(entry).get("yaw"), 0.0)
		chest.restore(_dict(entry))
	for rock in get_tree().get_nodes_in_group("mineable_rocks"):
		for entry in _list(data.get("boulders")):
			if str(_dict(entry).get("name", "")) == str(rock.name):
				rock.restore(int(_num(_dict(entry).get("hits_left"), 4.0)))
	for vein in get_tree().get_nodes_in_group("iron_veins") + get_tree().get_nodes_in_group("copper_veins"):
		for entry in _list(data.get("veins")):
			if str(_dict(entry).get("name", "")) == str(vein.name):
				vein.restore(int(_num(_dict(entry).get("hits_left"), float(vein.MAX_HITS))))
	for entry in _list(data.get("furnaces")):
		var furnace := Furnace.new()
		add_child(furnace)
		furnace.global_position = _vec(_dict(entry), Vector3.ZERO)
		furnace.rotation.y = _num(_dict(entry).get("yaw"), 0.0)
		furnace.restore(_dict(entry))
	var saved := _dict(data.get("player"))
	boar.restore(_dict(data.get("boar")))
	var bell_data := _dict(data.get("bellmaw")).duplicate()
	if int(_num(data.get("version"), GameSave.VERSION)) <= 8 and bell_data.has("health"):
		bell_data.health = clampf(_num(bell_data.health, 80), 0, 80) * 2
	bellmaw.restore(bell_data)
	if player:
		player.health = clampi(int(_num(saved.get("health"), 100)), 1, 100)
		player.stamina.restore(saved.get("stamina"))
		# Only an explicit saved upgrade unlocks the extra slots; versions 1–7 stay at eight.
		if saved.get("explorer_pack", false) == true:
			player.inventory.expand_backpack()
		player.inventory.restore(saved.get("slots", []))
		player.restore_equipment(saved)
		var legacy := int(_num(data.get("version"), GameSave.VERSION)) < 11
		player.crafting.restore(saved.get("crafting"), legacy)
		if legacy:
			if not get_tree().get_nodes_in_group("workbenches").is_empty(): player.crafting.earn("bench_placed")
			if not get_tree().get_nodes_in_group("furnaces").is_empty(): player.crafting.earn("furnace_placed")
		if player.crafting.has("copperworking"):
			for bench in get_tree().get_nodes_in_group("workbenches"): bench.show_copperworking()
		var spot := _vec(saved, player.global_position)
		if spot.y > -10.0:
			player.global_position = spot
		player.rotation.y = _num(saved.get("yaw"), 0.0)
		player.camera.rotation.x = clampf(_num(saved.get("pitch"), 0.0), deg_to_rad(-85.0), deg_to_rad(85.0))
		player.velocity = Vector3.ZERO
		player.set_third_person(saved.get("third_person", true) != false)
		player.view_rig.facing = player.rotation.y + PI
	for entry in _list(data.get("arrows")):
		var saved_arrow := _dict(entry)
		var arrow := Arrow.new()
		arrow.velocity = Vector3(_num(saved_arrow.get("vx"), 0), _num(saved_arrow.get("vy"), 0), _num(saved_arrow.get("vz"), 0)).limit_length(50.0)
		arrow.age = clampf(_num(saved_arrow.get("age"), 0), 0.0, Arrow.MAX_AGE)
		if player:
			arrow.shooter_rid = player.get_rid()
		add_child(arrow)
		arrow.global_position = _vec(saved_arrow, Vector3(0, 1, 0))

func _list(value: Variant) -> Array:
	return value if value is Array else []

func _dict(value: Variant) -> Dictionary:
	return value if value is Dictionary else {}

func _num(value: Variant, fallback: float) -> float:
	return float(value) if (value is float or value is int) else fallback

func _vec(entry: Dictionary, fallback: Vector3) -> Vector3:
	return Vector3(_num(entry.get("x"), fallback.x), _num(entry.get("y"), fallback.y), _num(entry.get("z"), fallback.z))
