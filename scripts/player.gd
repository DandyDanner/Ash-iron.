extends CharacterBody3D

const Profile = preload("res://scripts/character_profile.gd")
const Traveler = preload("res://scripts/traveler_model.gd")
const Axe = preload("res://scripts/starter_axe.gd")
const Inventory = preload("res://scripts/inventory.gd")
const InventoryPanel = preload("res://scripts/inventory_panel.gd")
const Pickup = preload("res://scripts/resource_pickup.gd")
const StoragePanel = preload("res://scripts/storage_panel.gd")
const Chest = preload("res://scripts/storage_chest.gd")
const Bench = preload("res://scripts/workbench.gd")
const ViewRig = preload("res://scripts/view_rig.gd")
const Bow = preload("res://scripts/starter_bow.gd")
const Arrow = preload("res://scripts/arrow_projectile.gd")
const Hotbar = preload("res://scripts/hotbar.gd")
const Furnace = preload("res://scripts/furnace.gd")
const FurnacePanel = preload("res://scripts/furnace_panel.gd")
const REACH := 2.6
@export var pickup_radius: float = 3.0
@export_range(10.0, 90.0) var pickup_half_angle: float = 70.0
const JUMP_GRACE := 0.1
const JUMP_BUFFER := 0.12

@export var walk_speed: float = 5.0
@export var sprint_speed: float = 8.0
@export var mouse_sensitivity: float = 0.0025
@export var jump_speed: float = 5.4
@onready var camera: Camera3D = $Camera3D

var health := 100
var stamina := preload("res://scripts/stamina.gd").new()
var vitals: Control
var damage_grace := 0.0
var heal_delay := 0.0
var heal_clock := 0.0
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var identity_label: Label
var resource_label: Label
var prompt_label: Label
var first_left_hand: Node3D
var axe: Node3D
var bow: Node3D
var view_rig: Node3D
var controls_active := true
var inventory := Inventory.new()
var inventory_panel: Control
var active_bench: Node3D
var workbench: Node3D:
	get: return _nearest_workbench()
var equipped_item := ""
var axe_equipped: bool:
	get: return equipped_item == "stone_axe"
var hotbar: Array[String] = ["", "", "", "", "", "", "", "", "", ""]
var hotbar_view: Control
var wood: int:
	get: return inventory.count("wood")
var jump_buffer := 0.0
var grounded_grace := 0.0
var collect_requested := false
var feedback_time := 0.0
var feedback := ""
var spawn_position: Vector3
var storage_panel: Control
var open_chest: Node3D
var furnace_panel: Control
var open_furnace_node: Node3D
var save_label: Label
var world: Node

func _ready() -> void:
	spawn_position = global_position
	_capture_controls(true)
	var profile := Profile.load_profile()
	var display_name: String = profile.name if not profile.name.is_empty() else "Traveler"
	var hud := CanvasLayer.new()
	add_child(hud)
	identity_label = _label(hud, Vector2(24, 20), 17)
	identity_label.text = "%s  ·  %s\nKeepsake: %s" % [display_name, Profile.BACKGROUNDS[profile.background], Profile.KEEPSAKES[profile.keepsake]]
	resource_label = _label(hud, Vector2(24, 79), 18)
	resource_label.add_theme_color_override("font_color", Color("f4d79a"))
	vitals = preload("res://scripts/player_vitals.gd").new()
	hud.add_child(vitals)
	prompt_label = _label(hud, Vector2.ZERO, 21)
	prompt_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	prompt_label.offset_left = -450
	prompt_label.offset_right = 450
	prompt_label.offset_top = -151
	prompt_label.offset_bottom = -110
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.add_theme_color_override("font_color", Color("fff1cb"))
	first_left_hand = preload("res://scripts/first_person_hand.gd").new()
	first_left_hand.name = "LeftHand"
	camera.add_child(first_left_hand)
	first_left_hand.build(Profile.skin_color(profile), Profile.clothing_color(profile), true)
	first_left_hand.position = Vector3(-0.32,-0.32,-0.65)
	axe = Axe.new()
	camera.add_child(axe)
	axe.setup(Profile.clothing_color(profile), Profile.skin_color(profile))
	axe.set_equipped(false)
	bow = Bow.new()
	camera.add_child(bow)
	view_rig = ViewRig.new()
	add_child(view_rig)
	hotbar_view = Hotbar.new()
	hud.add_child(hotbar_view)
	hotbar_view.setup(self)
	inventory_panel = InventoryPanel.new()
	hud.add_child(inventory_panel)
	inventory_panel.setup(self)
	storage_panel = StoragePanel.new()
	hud.add_child(storage_panel)
	storage_panel.setup(self)
	furnace_panel = FurnacePanel.new()
	hud.add_child(furnace_panel)
	furnace_panel.setup(self)
	save_label = _label(hud, Vector2.ZERO, 14)
	save_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	save_label.offset_left = -420
	save_label.offset_right = -24
	save_label.offset_top = 20
	save_label.offset_bottom = 44
	save_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	save_label.add_theme_color_override("font_color", Color("cfd6c2"))
	save_label.text = "Your progress here is saved as you play"
	world = get_parent() if get_parent() != null and get_parent().has_method("save_game") else null
	inventory.changed.connect(_inventory_changed)
	_update_hud()

func _label(parent: Node, pos: Vector2, font_size: int) -> Label:
	var label := Label.new()
	label.position = pos
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F11:
		var fullscreen := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if fullscreen else DisplayServer.WINDOW_MODE_FULLSCREEN)
		return
	if inventory_panel.visible or storage_panel.visible or furnace_panel.visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_V:
			set_third_person(not view_rig.third_person)
			return
		if event.physical_keycode == KEY_I:
			open_inventory()
			return
		if event.physical_keycode == KEY_C:
			if world and world.save_game() != OK:
				show_quit_error()
				return
			get_tree().change_scene_to_file("res://scenes/character_creator.tscn")
			return
		if event.keycode == KEY_ESCAPE:
			open_inventory()
			return
		if controls_active:
			var shortcut := hotbar_key(event)
			if shortcut >= 0:
				use_hotbar(shortcut)
				return
			if event.physical_keycode == KEY_SPACE:
				jump_buffer = JUMP_BUFFER
			if event.physical_keycode == KEY_E:
				collect_requested = true
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed and controls_active:
		bow.cancel_draw()
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		if controls_active and equipped_item == "bow":
			fire_bow()
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not controls_active:
			_capture_controls(true)
			return # The click that resumes play must not also swing the axe.
		if equipped_item in ["stone_axe", "stone_pickaxe", "stone_spear"] and inventory.count(equipped_item) > 0:
			axe.start_swing()
		elif equipped_item == "bow":
			if inventory.count("arrow") > 0:
				bow.begin_draw()
			else:
				_show_feedback("No arrows • Craft a bundle at your workbench.")
		elif equipped_item == "torch":
			_show_feedback("Pine torch • Press its hotbar key again to put it away.")
		else:
			_show_feedback("Empty hands • Gather sticks and stones, then build at camp.")
	if event is InputEventMouseMotion and controls_active:
		rotate_y(-event.relative.x * mouse_sensitivity)
		camera.rotation.x = clampf(camera.rotation.x - event.relative.y * mouse_sensitivity, deg_to_rad(-85.0), deg_to_rad(85.0))

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_instance_valid(axe):
		_capture_controls(false)
		_cancel_actions()

func _capture_controls(active: bool) -> void:
	controls_active = active
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if active else Input.MOUSE_MODE_VISIBLE

func _cancel_actions() -> void:
	jump_buffer = 0.0
	collect_requested = false
	axe.cancel_swing()
	if is_instance_valid(bow):
		bow.cancel_draw()

func _physics_process(delta: float) -> void:
	if not controls_active:
		return
	damage_grace = maxf(0, damage_grace - delta)
	heal_delay = maxf(0, heal_delay - delta)
	if health < 100 and heal_delay == 0 and global_position.distance_to(spawn_position) < 6:
		heal_clock += delta
		if heal_clock >= 0.25:
			heal_clock = 0
			health = mini(100, health + 1)
			_progress_changed()
	bow.advance(delta)
	update_first_person_hands()
	grounded_grace = JUMP_GRACE if is_on_floor() else maxf(0.0, grounded_grace - delta)
	if not is_on_floor():
		velocity.y -= gravity * delta
	elif velocity.y < 0.0:
		velocity.y = 0.0
	if jump_buffer > 0.0 and grounded_grace > 0.0:
		velocity.y = jump_speed
		jump_buffer = 0.0
		grounded_grace = 0.0
	jump_buffer = maxf(0.0, jump_buffer - delta)
	var input_vector := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_W):
		input_vector.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S):
		input_vector.y += 1.0
	if Input.is_physical_key_pressed(KEY_A):
		input_vector.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D):
		input_vector.x += 1.0
	input_vector = input_vector.normalized()
	var move_direction := (transform.basis * Vector3(input_vector.x, 0.0, input_vector.y)).normalized()
	var sprinting := stamina.advance(delta, Input.is_physical_key_pressed(KEY_SHIFT) and not input_vector.is_zero_approx())
	var speed := sprint_speed if sprinting else walk_speed
	velocity.x = move_direction.x * speed
	velocity.z = move_direction.z * speed
	move_and_slide()
	if global_position.y < -15.0:
		global_position = spawn_position
		velocity = Vector3.ZERO
		grounded_grace = 0.0
		_cancel_actions()
		_show_feedback("Back in the clearing")
	if axe.advance(delta):
		var hit := _spear_target() if equipped_item == "stone_spear" else (_melee_target(REACH) if axe_equipped else _aim_target())
		if equipped_item in ["stone_spear", "stone_axe"] and not hit.is_empty() and hit.collider.has_method("receive_melee_hit"):
			var damage := Axe.SPEAR_DAMAGE if equipped_item == "stone_spear" else Axe.AXE_DAMAGE
			var message: String = hit.collider.receive_melee_hit(damage, hit.position)
			axe.impact.play()
			_show_feedback(message)
		elif equipped_item == "stone_spear" and not hit.is_empty():
			_show_feedback("Spear blocked • Practice on the target at the far right of camp.")
		elif axe_equipped and not hit.is_empty() and hit.collider.has_method("chop"):
			if hit.collider.chop(hit.position):
				axe.impact.play()
				_progress_changed()
				_show_feedback("Timber! Collect the fallen wood with E." if hit.collider.hits_left == 0 else "Good hit")
		elif equipped_item == "stone_pickaxe" and not hit.is_empty() and hit.collider.has_method("mine"):
			if hit.collider.mine(hit.position):
				axe.impact.play()
				_progress_changed()
				if hit.collider.has_method("mined_message"):
					_show_feedback(hit.collider.mined_message())
				else:
					_show_feedback("Boulder broken! E to gather stones." if hit.collider.hits_left == 0 else "Stone chipped")
	if collect_requested:
		collect_requested = false
		var target := _interaction_target()
		if is_instance_valid(target):
			if target.has_method("collect_into"):
				var item: String = target.item_id
				var amount: int = target.collect_into(inventory)
				if amount > 0:
					if item == "stone_axe":
						equip_axe(true)
					_show_feedback("+%d %s" % [amount, Inventory.ITEMS[item].name.to_lower()])
				else:
					_show_feedback("Backpack full • Press I to drop a stack or craft.")
			elif target.is_in_group("workbenches"):
				open_inventory(target)
			elif target.is_in_group("chests"):
				open_storage(target)
			elif target.is_in_group("furnaces"):
				open_furnace(target)
	feedback_time = maxf(0.0, feedback_time - delta)
	_update_hud()

func _aim_target() -> Dictionary:
	var origin := camera.global_position
	var query := PhysicsRayQueryParameters3D.create(origin, origin + view_rig.shot_direction(3) * REACH, 3, [get_rid()])
	query.collide_with_areas = true
	return get_world_3d().direct_space_state.intersect_ray(query)

func _spear_target() -> Dictionary:
	return _melee_target(Axe.SPEAR_REACH)

func _melee_target(reach: float) -> Dictionary:
	# Resolve the first solid contact from the traveler, never from the chase camera.
	var origin := camera.global_position
	var query := PhysicsRayQueryParameters3D.create(origin, origin + view_rig.shot_direction(1) * reach, 1, [get_rid()])
	return get_world_3d().direct_space_state.intersect_ray(query)

func receive_damage(amount: int, message: String = "Boar hit! • Sidestep its charge, then counterattack.") -> bool:
	if not controls_active or amount <= 0 or damage_grace > 0: return false
	health = maxi(0, health - amount)
	damage_grace = 1.0
	heal_delay = 8.0
	if health == 0:
		_cancel_actions()
		global_position = spawn_position
		velocity = Vector3.ZERO
		health = 100
		stamina.restore({})
		damage_grace = 3.0
		_show_feedback("Back at camp • Your backpack is safe. Prepare and try again.")
		feedback_time = 4.0
	else:
		_show_feedback(message)
	_progress_changed()
	_update_hud()
	return true

func _show_feedback(text: String) -> void:
	feedback = text
	feedback_time = 1.2

func _interaction_target() -> Node3D:
	# Precise aim takes priority, but gathering does not require looking down at a tiny collider.
	var aimed := _aim_target()
	if not aimed.is_empty() and (aimed.collider.is_in_group("workbenches") or aimed.collider.is_in_group("chests") or aimed.collider.is_in_group("furnaces")):
		return aimed.collider
	var forward := -camera.global_basis.z
	forward.y = 0.0
	if forward.length_squared() < 0.01:
		forward = -global_basis.z
	forward = forward.normalized()
	var best: Node3D = null
	var best_distance := INF
	var candidates := get_tree().get_nodes_in_group("pickups")
	candidates.append_array(get_tree().get_nodes_in_group("wood_bundles"))
	for candidate in candidates:
		if candidate.is_queued_for_deletion() or candidate.collected:
			continue
		var offset: Vector3 = candidate.global_position - global_position
		if absf(offset.y) > 1.8:
			continue
		offset.y = 0.0
		var distance := offset.length()
		if distance > pickup_radius:
			continue
		# Anything at your feet is reachable; farther items use a broad horizontal cone.
		if distance > 1.1 and forward.dot(offset.normalized()) < cos(deg_to_rad(pickup_half_angle)):
			continue
		var sight := PhysicsRayQueryParameters3D.create(camera.global_position, candidate.global_position + Vector3(0, 0.12, 0), 1, [get_rid()])
		if not get_world_3d().direct_space_state.intersect_ray(sight).is_empty():
			continue
		if not aimed.is_empty() and aimed.collider == candidate:
			return candidate
		if distance < best_distance:
			best = candidate
			best_distance = distance
	if best != null:
		return best
	# A waist-high table should be usable while looking level in either camera mode.
	for bench in get_tree().get_nodes_in_group("workbenches"):
		if not bench.within_reach(self):
			continue
		var offset: Vector3 = bench.global_position - global_position
		offset.y = 0
		var distance := offset.length()
		if distance > 1.1 and forward.dot(offset.normalized()) < cos(deg_to_rad(pickup_half_angle)):
			continue
		if distance < best_distance:
			best = bench
			best_distance = distance
	return best

func _update_hud() -> void:
	resource_label.text = "%s   /   PACK %d / %d" % [Inventory.ITEMS[equipped_item].name.to_upper() if not equipped_item.is_empty() else "EMPTY HANDS", inventory.used_slots(), inventory.slots.size()]
	vitals.refresh(health, stamina)
	if equipped_item == "bow":
		resource_label.text += "   /   ARROWS %d" % inventory.count("arrow")
	if is_instance_valid(hotbar_view):
		hotbar_view.refresh()
	if feedback_time > 0.0:
		prompt_label.text = feedback
		return
	if bow.drawing:
		prompt_label.text = "DRAW %d%% • Release to fire • Right click to cancel" % roundi(bow.charge() * 100)
		return
	var nearby := _interaction_target()
	if is_instance_valid(nearby):
		prompt_label.text = nearby.prompt()
		return
	var hit := _aim_target()
	if not hit.is_empty() and hit.collider.has_method("prompt"):
		if hit.collider.has_method("chop") and not axe_equipped:
			prompt_label.text = "Equip your axe in the backpack [I]." if inventory.count("stone_axe") > 0 else "A pine needs an axe • Gather loose sticks and stones first."
		else:
			prompt_label.text = hit.collider.prompt()
	elif equipped_item == "stone_spear":
		prompt_label.text = "Left click to thrust • Beyond the target: ochre markers lead to Echo Hollow"
	elif equipped_item == "bow":
		prompt_label.text = "Hold to draw • Release to fire • Beyond the target: follow ochre markers to Echo Hollow"
	elif inventory.count("bench") > 0:
		prompt_label.text = "Open your backpack [I] to place your workbench."
	elif not is_instance_valid(workbench):
		prompt_label.text = "Walk near sticks and stones • E Gather • I Backpack"
	elif inventory.count("stone_axe") == 0:
		prompt_label.text = "Return to your workbench to craft a stone axe."
	elif inventory.count("chest") > 0:
		prompt_label.text = "Open your backpack [I] to place your storage chest."
	elif get_tree().get_nodes_in_group("chests").is_empty() and inventory.can_afford(Inventory.CHEST_COST):
		prompt_label.text = "Return to your workbench to craft a storage chest."
	elif inventory.count("furnace") > 0:
		prompt_label.text = "Open your backpack [I] to place your furnace."
	elif inventory.count("iron_ore") > 0 and get_tree().get_nodes_in_group("furnaces").is_empty():
		prompt_label.text = "Iron ore needs a furnace • Craft one at your workbench (10 stones + 2 wood)."
	else:
		prompt_label.text = "Aim at a nearby pine to chop • I Backpack"

func open_inventory(bench: Node3D = null) -> void:
	active_bench = bench
	_enter_menu()
	inventory_panel.show_pack()

func close_inventory() -> void:
	active_bench = null
	inventory_panel.hide()
	_leave_menu()

func open_storage(chest: Node3D) -> void:
	_enter_menu()
	open_chest = chest
	chest.set_open(true)
	storage_panel.open(chest)

func close_storage() -> void:
	storage_panel.hide()
	if is_instance_valid(open_chest):
		open_chest.set_open(false)
	open_chest = null
	_leave_menu()

func open_furnace(furnace: Node3D) -> void:
	_enter_menu()
	open_furnace_node = furnace
	furnace_panel.open(furnace)

func close_furnace() -> void:
	furnace_panel.hide()
	open_furnace_node = null
	_leave_menu()

func _enter_menu() -> void:
	_capture_controls(false)
	_cancel_actions()
	identity_label.hide()
	resource_label.hide()
	vitals.hide()
	prompt_label.hide()
	save_label.hide()
	hotbar_view.hide()
	get_parent().get_node("HUD/Crosshair").hide()

func _leave_menu() -> void:
	identity_label.show()
	resource_label.show()
	vitals.show()
	prompt_label.show()
	save_label.show()
	hotbar_view.show()
	get_parent().get_node("HUD/Crosshair").show()
	_capture_controls(true)
	_update_hud()
	# Closing a panel is a natural checkpoint.
	if world:
		world.save_game()

func _inventory_changed() -> void:
	if not equipped_item.is_empty() and inventory.count(equipped_item) == 0:
		equipped_item = ""
	axe.set_item(equipped_item)
	bow.visible = equipped_item == "bow"
	if not bow.visible or inventory.count("arrow") == 0:
		bow.cancel_draw()
	_update_hud()
	if inventory_panel.visible:
		inventory_panel.refresh()
	if storage_panel.visible:
		storage_panel.refresh()
	if furnace_panel.visible:
		furnace_panel.refresh()
	_progress_changed()

func equip_axe(equipped: bool) -> void:
	equip_item("stone_axe" if equipped else "")

func equip_item(item: String) -> void:
	if not item.is_empty() and (not item in Inventory.EQUIPPABLE or inventory.count(item) == 0):
		return
	equipped_item = item
	bow.cancel_draw()
	bow.visible = item == "bow"
	axe.cancel_swing()
	axe.set_item(item)
	if not item.is_empty() and not item in hotbar:
		var free := hotbar.find("")
		if free >= 0:
			hotbar[free] = item
	_update_hud()
	_progress_changed()

func toggle_axe() -> void:
	equip_axe(not axe_equipped)

static func hotbar_key(event: InputEventKey) -> int:
	var code := event.physical_keycode if event.physical_keycode != 0 else event.keycode
	if code >= KEY_1 and code <= KEY_9:
		return code - KEY_1
	return 9 if code == KEY_0 else -1

func assign_hotbar(index: int, item: String) -> String:
	if index < 0 or index >= hotbar.size():
		return "Unknown shortcut."
	if not item.is_empty() and (not item in Inventory.EQUIPPABLE or inventory.count(item) == 0):
		return "Choose equipment from your backpack."
	# Moving a shortcut keeps a single, predictable key for each tool.
	for i in range(hotbar.size()):
		if not item.is_empty() and hotbar[i] == item:
			hotbar[i] = ""
	hotbar[index] = item
	_update_hud()
	_progress_changed()
	return "Shortcut %d cleared." % ((index + 1) % 10) if item.is_empty() else "%s assigned to %d." % [Inventory.ITEMS[item].name, (index + 1) % 10]

func use_hotbar(index: int) -> void:
	if index < 0 or index >= hotbar.size():
		return
	var item := hotbar[index]
	if not item.is_empty() and inventory.count(item) == 0:
		equip_item("")
		_show_feedback("%s is not in your backpack. Take it from storage first." % Inventory.ITEMS[item].name)
		return
	equip_item("" if equipped_item == item else item)

func restore_equipment(saved: Dictionary) -> void:
	hotbar.fill("")
	var raw: Variant = saved.get("hotbar", [])
	if raw is Array:
		for i in range(mini(10, raw.size())):
			if raw[i] is String and raw[i] in Inventory.EQUIPPABLE and not raw[i] in hotbar:
				hotbar[i] = raw[i]
	var item: Variant = saved.get("equipped_item", "stone_axe" if saved.get("axe_equipped", false) == true else "")
	equip_item(item if item is String and item in Inventory.EQUIPPABLE and inventory.count(item) > 0 else "")
	# Old saves gain a useful first shortcut even when the axe was put away.
	if not saved.has("hotbar") and inventory.count("stone_axe") > 0:
		hotbar[0] = "stone_axe"
	_update_hud()

func recipe_requirement(id: String) -> String:
	if not Inventory.RECIPES.has(id):
		return "Unknown recipe."
	if not is_instance_valid(workbench):
		return "Craft and place a simple workbench first."
	if not workbench.within_reach(self):
		return "Stand close to your workbench."
	var recipe: Dictionary = Inventory.RECIPES[id]
	if id == "explorer_pack" and inventory.slots.size() >= Inventory.EXPLORER_CAPACITY:
		return "Explorer Pack already fitted (12 slots)."
	if recipe.output in Inventory.EQUIPPABLE and inventory.count(recipe.output) > 0:
		return "You already carry this tool."
	if not Inventory.can_afford_across(containers(), recipe.cost):
		return "Gather the missing materials."
	if not Inventory.can_craft_across(containers(), recipe.cost, "" if recipe.get("upgrade", false) else recipe.output, recipe.amount):
		return "Make room in your backpack first."
	return ""

func craft_recipe(id: String) -> String:
	var reason := recipe_requirement(id)
	if not reason.is_empty():
		return reason
	var recipe: Dictionary = Inventory.RECIPES[id]
	var before := _pack_counts(recipe.cost)
	if not Inventory.craft_across(containers(), recipe.cost, "" if recipe.get("upgrade", false) else recipe.output, recipe.amount):
		return "Couldn't craft: check materials and backpack space."
	if id == "explorer_pack":
		inventory.expand_backpack()
		return "Explorer Pack fitted! You now have twelve backpack slots." + _storage_note(before, recipe.cost)
	if recipe.output in Inventory.EQUIPPABLE:
		equip_item(recipe.output)
	return "Crafted %d %s." % [recipe.amount, Inventory.ITEMS[recipe.output].name.to_lower()] + _storage_note(before, recipe.cost)

func save_and_quit() -> void:
	if world:
		world.request_quit()

func show_quit_error() -> void:
	if storage_panel.visible:
		close_storage()
	open_inventory()
	inventory_panel.message_label.text = "Couldn't save. Your game is still open. Free disk space or check folder access, then retry."

func bench_requirement() -> String:
	if not Inventory.can_afford_across(containers(), Inventory.BENCH_COST):
		return "Gather more sticks and stones by hand."
	if not Inventory.can_craft_across(containers(), Inventory.BENCH_COST, "bench"):
		return "Make room for the workbench: drop one stack."
	return ""

func axe_requirement() -> String:
	if not is_instance_valid(workbench):
		return "Craft and place a simple workbench first."
	if not workbench.within_reach(self):
		return "Stand close to your workbench."
	if inventory.count("stone_axe") > 0:
		return "You already have an axe in your backpack."
	if not Inventory.can_afford_across(containers(), Inventory.AXE_COST):
		return "Gather more sticks and stones."
	if not Inventory.can_craft_across(containers(), Inventory.AXE_COST, "stone_axe"):
		return "Make room for the axe: drop one stack."
	return ""

func craft_bench() -> String:
	var reason := bench_requirement()
	if not reason.is_empty():
		return reason
	var pack_before := _pack_counts(Inventory.BENCH_COST)
	if not Inventory.craft_across(containers(), Inventory.BENCH_COST, "bench"):
		return "Couldn't craft: check materials and backpack space."
	_update_hud()
	return "Workbench crafted. Select it and choose Place workbench here." + _storage_note(pack_before, Inventory.BENCH_COST)

func craft_axe() -> String:
	var reason := axe_requirement()
	if not reason.is_empty():
		return reason
	var pack_before := _pack_counts(Inventory.AXE_COST)
	if not Inventory.craft_across(containers(), Inventory.AXE_COST, "stone_axe"):
		return "Couldn't craft: check materials and backpack space."
	equip_axe(true)
	return "Stone axe crafted and equipped. Close your pack to try it." + _storage_note(pack_before, Inventory.AXE_COST)

func drop_slot(index: int) -> String:
	if index < 0 or index >= inventory.slots.size() or inventory.slots[index].is_empty():
		return "Select an item first."
	# Use the player's horizontal facing; looking straight up or down is safe.
	var ahead := global_position - global_basis.z * 1.15
	var query := PhysicsRayQueryParameters3D.create(ahead + Vector3.UP, ahead + Vector3.DOWN * 4, 1, [get_rid()])
	var ground := get_world_3d().direct_space_state.intersect_ray(query)
	if ground.is_empty():
		return "Move to solid ground before dropping items."
	var stack: Dictionary = inventory.take_slot(index)
	var pickup := Pickup.new()
	pickup.item_id = stack.item
	pickup.amount = stack.amount
	get_parent().add_child(pickup)
	pickup.global_position = ground.position + Vector3(0, 0.035, 0)
	_progress_changed()
	return "Dropped %d %s. You can pick it up again." % [stack.amount, Inventory.ITEMS[stack.item].name.to_lower()]

func _progress_changed() -> void:
	if world:
		world.mark_dirty()

func note_saved(result: Error) -> void:
	if result == OK:
		save_label.text = "Saved  %s" % Time.get_time_string_from_system()
	else:
		save_label.text = "Couldn't save progress (%s)" % error_string(result)

func save_game_now() -> String:
	if world == null:
		return "Saving isn't available here."
	return "Progress saved." if world.save_game() == OK else "Couldn't save. Check that the game can write to its user folder."

func chest_requirement() -> String:
	if not is_instance_valid(workbench):
		return "Craft and place a simple workbench first."
	if not workbench.within_reach(self):
		return "Stand close to your workbench."
	if not Inventory.can_afford_across(containers(), Inventory.CHEST_COST):
		return "Chop a pine for wood, then bring 5 wood and 2 sticks."
	if not Inventory.can_craft_across(containers(), Inventory.CHEST_COST, "chest"):
		return "Make room for the chest: drop one stack."
	return ""

func craft_chest() -> String:
	var reason := chest_requirement()
	if not reason.is_empty():
		return reason
	var pack_before := _pack_counts(Inventory.CHEST_COST)
	if not Inventory.craft_across(containers(), Inventory.CHEST_COST, "chest"):
		return "Couldn't craft: check materials and backpack space."
	return "Storage chest crafted. Select it and choose Place chest here." + _storage_note(pack_before, Inventory.CHEST_COST)

func _nearest_workbench() -> Node3D:
	if not is_inside_tree():
		return null
	if is_instance_valid(active_bench) and not active_bench.is_queued_for_deletion() and active_bench.within_reach(self):
		return active_bench
	var closest: Node3D = null
	var best := INF
	var usable: Node3D = null
	var usable_distance := INF
	for bench in get_tree().get_nodes_in_group("workbenches"):
		if bench.is_queued_for_deletion() or not bench.built:
			continue
		var distance: float = global_position.distance_squared_to(bench.global_position + Vector3(0, 0.9, 0))
		if distance < best:
			closest = bench
			best = distance
		if distance < usable_distance and bench.within_reach(self):
			usable = bench
			usable_distance = distance
	return usable if usable != null else closest

func linked_chests() -> Array:
	var bench := workbench
	return bench.linked_chests() if is_instance_valid(bench) and bench.within_reach(self) else []

func containers() -> Array:
	# Hand crafting works anywhere; chest materials require a usable placed bench.
	var sources := [inventory]
	for chest in linked_chests():
		sources.append(chest.storage)
	return sources

func stock(item: String) -> int:
	return Inventory.count_across(containers(), item)

func _pack_counts(cost: Dictionary) -> Dictionary:
	var counts := {}
	for item in cost:
		counts[item] = inventory.count(item)
	return counts

func _storage_note(pack_before: Dictionary, cost: Dictionary) -> String:
	for item in cost:
		if int(pack_before[item]) - inventory.count(item) < int(cost[item]):
			return " Some materials came from a chest by the bench."
	return ""

func place_selected(index: int) -> String:
	if index < 0 or index >= inventory.slots.size():
		return "Select a workbench or chest first."
	match inventory.slots[index].get("item", ""):
		"bench":
			return place_workbench(index)
		"furnace":
			return place_furnace(index)
		_:
			return place_chest(index)

func _placement_spot(dimensions: Vector3, distance: float) -> Dictionary:
	var ahead := global_position - global_basis.z * distance
	var state := get_world_3d().direct_space_state
	var rotation_basis := Basis(Vector3.UP, rotation.y)
	var low := INF
	var high := -INF
	# Check center and the four corners, so furniture cannot hang off an edge.
	for offset in [Vector3.ZERO, Vector3(-dimensions.x, 0, -dimensions.z) * 0.5, Vector3(dimensions.x, 0, -dimensions.z) * 0.5, Vector3(-dimensions.x, 0, dimensions.z) * 0.5, Vector3(dimensions.x, 0, dimensions.z) * 0.5]:
		var sample: Vector3 = ahead + rotation_basis * offset
		var query := PhysicsRayQueryParameters3D.create(sample + Vector3.UP, sample + Vector3.DOWN * 4, 1, [get_rid()])
		var ground := state.intersect_ray(query)
		if ground.is_empty() or ground.normal.y < 0.9 or not ground.collider.is_in_group("placement_ground"):
			return {"error": "Face clear, level ground before placing it."}
		low = minf(low, ground.position.y)
		high = maxf(high, ground.position.y)
	if high - low > 0.12:
		return {"error": "The ground is too uneven. Find a flatter spot."}
	var spot := Vector3(ahead.x, high, ahead.z)
	# Newly placed bodies may not enter the physics broadphase until the next tick.
	# Compare furniture footprints too, preventing two placements in the same frame.
	var polygon := _furniture_footprint(spot, rotation_basis, dimensions + Vector3(0.1, 0, 0.1))
	for furniture in get_tree().get_nodes_in_group("workbenches") + get_tree().get_nodes_in_group("chests") + get_tree().get_nodes_in_group("furnaces"):
		if furniture.is_queued_for_deletion():
			continue
		var other_size := _furniture_size(furniture)
		if spot.y + dimensions.y < furniture.global_position.y or furniture.global_position.y + other_size.y < spot.y:
			continue
		var other := _furniture_footprint(furniture.global_position, furniture.global_basis, other_size)
		if not Geometry2D.intersect_polygons(polygon, other).is_empty():
			return {"error": "No room there. Find a clearer spot."}
	var sight := PhysicsRayQueryParameters3D.create(camera.global_position, spot + Vector3.UP * 0.5, 1, [get_rid()])
	if not state.intersect_ray(sight).is_empty():
		return {"error": "Something blocks that spot. Move around it first."}
	var footprint := PhysicsShapeQueryParameters3D.new()
	var box := BoxShape3D.new()
	box.size = dimensions + Vector3(0.10, 0, 0.10)
	footprint.shape = box
	footprint.transform = Transform3D(rotation_basis, spot + Vector3.UP * (dimensions.y * 0.5 + 0.025))
	footprint.collision_mask = 3
	footprint.collide_with_areas = true
	footprint.exclude = [get_rid()]
	if not state.intersect_shape(footprint, 1).is_empty():
		return {"error": "No room there. Find a clearer spot."}
	return {"position": spot}

static func _furniture_size(furniture: Node3D) -> Vector3:
	if furniture.is_in_group("workbenches"):
		return Vector3(1.9, 1.05, 1.0)
	if furniture.is_in_group("furnaces"):
		return Furnace.SIZE
	return Vector3(0.92, 0.62, 0.58)

static func _furniture_footprint(spot: Vector3, rotation_basis: Basis, dimensions: Vector3) -> PackedVector2Array:
	var polygon := PackedVector2Array()
	for corner in [Vector3(-1, 0, -1), Vector3(1, 0, -1), Vector3(1, 0, 1), Vector3(-1, 0, 1)]:
		var vertex: Vector3 = spot + rotation_basis * (corner * dimensions * 0.5)
		polygon.append(Vector2(vertex.x, vertex.z))
	return polygon

func place_chest(index: int) -> String:
	if index < 0 or index >= inventory.slots.size() or inventory.slots[index].get("item", "") != "chest":
		return "Select the chest in your backpack first."
	var placement := _placement_spot(Vector3(0.92, 0.62, 0.58), 1.7)
	if placement.has("error"):
		return placement.error
	inventory.take_slot(index)
	var chest := Chest.new()
	get_parent().add_child(chest)
	chest.global_position = placement.position
	chest.rotation.y = rotation.y
	_progress_changed()
	return "Chest placed. Walk up to it and press E to store items."

func place_workbench(index: int) -> String:
	if index < 0 or index >= inventory.slots.size() or inventory.slots[index].get("item", "") != "bench":
		return "Select the workbench in your backpack first."
	var placement := _placement_spot(Vector3(1.9, 1.05, 1.0), 2.2)
	if placement.has("error"):
		return placement.error
	inventory.take_slot(index)
	var bench := Bench.new()
	get_parent().add_child(bench)
	bench.global_position = placement.position
	bench.rotation.y = rotation.y
	active_bench = bench
	_progress_changed()
	return "Workbench placed. Stand nearby and press E to craft tools."

func pickup_workbench(bench: Node3D) -> String:
	if not is_instance_valid(bench) or bench.is_queued_for_deletion():
		return "That workbench is gone."
	if not bench.within_reach(self):
		return "Stand close to the workbench to pick it up."
	if inventory.add("bench", 1) != 1:
		return "Your backpack is full. Make room for the workbench first."
	bench.queue_free()
	active_bench = null
	_progress_changed()
	return "Workbench packed up. Select it in your backpack to place it again."

func place_furnace(index: int) -> String:
	if index < 0 or index >= inventory.slots.size() or inventory.slots[index].get("item", "") != "furnace":
		return "Select the furnace in your backpack first."
	var placement := _placement_spot(Furnace.SIZE, 1.9)
	if placement.has("error"):
		return placement.error
	inventory.take_slot(index)
	var furnace := Furnace.new()
	get_parent().add_child(furnace)
	furnace.global_position = placement.position
	furnace.rotation.y = rotation.y
	_progress_changed()
	return "Furnace placed. Walk up to it and press E to load iron ore and wood."

func pickup_furnace(furnace: Node3D) -> String:
	if not is_instance_valid(furnace) or furnace.is_queued_for_deletion():
		return "That furnace is gone."
	if not furnace.is_empty():
		return "Empty the furnace before picking it up."
	if inventory.add("furnace", 1) != 1:
		return "Your backpack is full. Make room for the furnace first."
	furnace.queue_free()
	if furnace_panel.visible:
		close_furnace()
	_progress_changed()
	return "Furnace packed up."

func pickup_chest(chest: Node3D) -> String:
	if not is_instance_valid(chest):
		return "That chest is gone."
	if not chest.storage.is_empty():
		return "Empty the chest before picking it up."
	if inventory.add("chest", 1) != 1:
		return "Your backpack is full. Make room for the chest first."
	chest.queue_free()
	close_storage()
	_progress_changed()
	return "Chest packed up."

func fire_bow() -> void:
	var power: float = bow.release()
	if power < 0.0 or equipped_item != "bow" or not inventory.craft({"arrow": 1}):
		return
	var projectile := Arrow.new()
	projectile.shooter_rid = get_rid()
	projectile.velocity = view_rig.shot_direction() * lerpf(12.0, 32.0, power)
	get_parent().add_child(projectile)
	# Starting at the camera makes even a wall right in front of the player block the shot.
	projectile.global_position = camera.global_position
	axe.whoosh.play()
	_progress_changed()

func set_third_person(enabled: bool) -> void:
	_cancel_actions()
	view_rig.set_mode(enabled)
	_progress_changed()

func update_first_person_hands() -> void:
	first_left_hand.position = Vector3(-0.32,-0.32,-0.65)
	first_left_hand.set_grip(equipped_item == "bow")
	axe.hand.set_draw_pose(equipped_item == "bow" and bow.drawing)
	axe.hand.position = Vector3.ZERO
	axe.hand.rotation = Vector3.ZERO
	if equipped_item == "bow":
		first_left_hand.global_position = bow.global_position
		if bow.drawing:
			var nock: Vector3 = bow.nocked.position + Vector3(0,0,0.39)
			axe.hand.global_position = bow.to_global(nock)
	elif equipped_item == "stone_spear":
		axe.hand.rotation.x = PI / 2
