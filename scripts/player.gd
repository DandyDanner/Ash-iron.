extends CharacterBody3D

const Profile = preload("res://scripts/character_profile.gd")
const Traveler = preload("res://scripts/traveler_model.gd")
const Axe = preload("res://scripts/starter_axe.gd")
const Inventory = preload("res://scripts/inventory.gd")
const InventoryPanel = preload("res://scripts/inventory_panel.gd")
const Pickup = preload("res://scripts/resource_pickup.gd")
const REACH := 2.6
const JUMP_GRACE := 0.1
const JUMP_BUFFER := 0.12

@export var walk_speed: float = 5.0
@export var sprint_speed: float = 8.0
@export var mouse_sensitivity: float = 0.0025
@export var jump_speed: float = 5.4
@onready var camera: Camera3D = $Camera3D

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var identity_label: Label
var resource_label: Label
var prompt_label: Label
var axe: Node3D
var controls_active := true
var inventory := Inventory.new()
var inventory_panel: Control
var workbench: Node3D
var axe_equipped := false
var wood: int:
	get: return inventory.count("wood")
var jump_buffer := 0.0
var grounded_grace := 0.0
var collect_requested := false
var feedback_time := 0.0
var feedback := ""
var spawn_position: Vector3

func _ready() -> void:
	spawn_position = global_position
	_capture_controls(true)
	var profile := Profile.load_profile()
	var display_name: String = profile.name if not profile.name.is_empty() else "Traveler"
	var hud := CanvasLayer.new()
	add_child(hud)
	identity_label = _label(hud, Vector2(24, 20), 17)
	identity_label.text = "%s · %s\nKeepsake: %s\n\nWASD Move · Shift Sprint · Space Jump\nE Gather / bench · I Backpack / craft\nLeft click Use axe · C Character · Esc Release mouse" % [display_name, Profile.BACKGROUNDS[profile.background], Profile.KEEPSAKES[profile.keepsake]]
	resource_label = _label(hud, Vector2(24, 175), 22)
	resource_label.add_theme_color_override("font_color", Color("f4d79a"))
	prompt_label = _label(hud, Vector2.ZERO, 21)
	prompt_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	prompt_label.offset_left = -450
	prompt_label.offset_right = 450
	prompt_label.offset_top = -85
	prompt_label.offset_bottom = -35
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.add_theme_color_override("font_color", Color("fff1cb"))
	Traveler.oval(camera, Vector3(-0.28, -0.35, -0.43), Vector3(0.14, 0.16, 0.38), Profile.CLOTHES[profile.clothes])
	var left_hand := Traveler.oval(camera, Vector3(-0.27, -0.32, -0.62), Vector3(0.105, 0.115, 0.15), Profile.SKINS[profile.skin])
	left_hand.name = "LeftHand"
	axe = Axe.new()
	camera.add_child(axe)
	axe.setup(Profile.CLOTHES[profile.clothes], Profile.SKINS[profile.skin])
	axe.set_equipped(false)
	workbench = get_tree().get_first_node_in_group("workbenches")
	inventory_panel = InventoryPanel.new()
	hud.add_child(inventory_panel)
	inventory_panel.setup(self)
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
	if inventory_panel.visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_I:
			open_inventory()
			return
		if event.physical_keycode == KEY_C:
			get_tree().change_scene_to_file("res://scenes/character_creator.tscn")
			return
		if event.keycode == KEY_ESCAPE:
			_capture_controls(false)
			_cancel_actions()
			return
		if controls_active:
			if event.physical_keycode == KEY_SPACE:
				jump_buffer = JUMP_BUFFER
			if event.physical_keycode == KEY_E:
				collect_requested = true
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not controls_active:
			_capture_controls(true)
			return # The click that resumes play must not also swing the axe.
		if axe_equipped and inventory.count("stone_axe") > 0:
			axe.start_swing()
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

func _physics_process(delta: float) -> void:
	if not controls_active:
		return
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
	var speed := sprint_speed if Input.is_physical_key_pressed(KEY_SHIFT) else walk_speed
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
		var hit := _aim_target()
		if not hit.is_empty() and hit.collider.has_method("chop"):
			if hit.collider.chop(hit.position):
				axe.impact.play()
				_show_feedback("Timber! Collect the fallen wood with E." if hit.collider.hits_left == 0 else "Good hit")
	if collect_requested:
		collect_requested = false
		var target := _aim_target()
		if not target.is_empty():
			if target.collider.has_method("collect_into"):
				var item: String = target.collider.item_id
				var amount: int = target.collider.collect_into(inventory)
				if amount > 0:
					if item == "stone_axe":
						equip_axe(true)
					_show_feedback("+%d %s" % [amount, Inventory.ITEMS[item].name.to_lower()])
				else:
					_show_feedback("Backpack full • Press I to drop a stack or craft.")
			elif target.collider == workbench:
				open_inventory()
	feedback_time = maxf(0.0, feedback_time - delta)
	_update_hud()

func _aim_target() -> Dictionary:
	var origin := camera.global_position
	var query := PhysicsRayQueryParameters3D.create(origin, origin - camera.global_basis.z * REACH, 3, [get_rid()])
	query.collide_with_areas = true
	return get_world_3d().direct_space_state.intersect_ray(query)

func _show_feedback(text: String) -> void:
	feedback = text
	feedback_time = 1.2

func _update_hud() -> void:
	resource_label.text = "%s   /   PACK %d / 8" % ["STONE AXE" if axe_equipped else "EMPTY HANDS", inventory.used_slots()]
	if feedback_time > 0.0:
		prompt_label.text = feedback
		return
	var hit := _aim_target()
	if not hit.is_empty() and hit.collider.has_method("prompt"):
		if hit.collider.has_method("chop") and not axe_equipped:
			prompt_label.text = "Equip your axe in the backpack [I]." if inventory.count("stone_axe") > 0 else "A pine needs an axe • Gather loose sticks and stones first."
		else:
			prompt_label.text = hit.collider.prompt()
	elif not workbench.built:
		prompt_label.text = "Look down for sticks and stones • E Gather • I Backpack"
	elif inventory.count("stone_axe") == 0:
		prompt_label.text = "Return to your workbench to craft a stone axe."
	else:
		prompt_label.text = "Aim at a nearby pine to chop • I Backpack"

func open_inventory() -> void:
	_capture_controls(false)
	_cancel_actions()
	identity_label.hide()
	resource_label.hide()
	prompt_label.hide()
	get_parent().get_node("HUD/Crosshair").hide()
	inventory_panel.show_pack()

func close_inventory() -> void:
	inventory_panel.hide()
	identity_label.show()
	resource_label.show()
	prompt_label.show()
	get_parent().get_node("HUD/Crosshair").show()
	_capture_controls(true)
	_update_hud()

func _inventory_changed() -> void:
	if inventory.count("stone_axe") == 0:
		axe_equipped = false
	axe.set_equipped(axe_equipped)
	_update_hud()
	if inventory_panel.visible:
		inventory_panel.refresh()

func equip_axe(equipped: bool) -> void:
	axe_equipped = equipped and inventory.count("stone_axe") > 0
	axe.set_equipped(axe_equipped)
	_update_hud()

func toggle_axe() -> void:
	equip_axe(not axe_equipped)

func bench_requirement() -> String:
	if workbench.built:
		return "Your bench is ready in the clearing."
	if not inventory.can_afford(Inventory.BENCH_COST):
		return "Gather more sticks and stones by hand."
	if not workbench.within_reach(self):
		return "Stand near the marked CAMP WORKSITE."
	return ""

func axe_requirement() -> String:
	if not workbench.built:
		return "Build the simple bench first."
	if not workbench.within_reach(self):
		return "Stand close to your workbench."
	if inventory.count("stone_axe") > 0:
		return "You already have an axe in your backpack."
	if not inventory.can_afford(Inventory.AXE_COST):
		return "Gather more sticks and stones."
	if not inventory.can_craft(Inventory.AXE_COST, "stone_axe"):
		return "Make room for the axe: drop one stack."
	return ""

func build_bench() -> String:
	var reason := bench_requirement()
	if not reason.is_empty():
		return reason
	if not inventory.craft(Inventory.BENCH_COST):
		return "Not enough supplies."
	workbench.build()
	_update_hud()
	return "Bench built! Gather 3 sticks + 2 stones for your first axe."

func craft_axe() -> String:
	var reason := axe_requirement()
	if not reason.is_empty():
		return reason
	if not inventory.craft(Inventory.AXE_COST, "stone_axe"):
		return "Couldn't craft: check materials and backpack space."
	equip_axe(true)
	return "Stone axe crafted and equipped. Close your pack to try it."

func drop_slot(index: int) -> String:
	if index < 0 or index >= Inventory.CAPACITY or inventory.slots[index].is_empty():
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
	return "Dropped %d %s. You can pick it up again." % [stack.amount, Inventory.ITEMS[stack.item].name.to_lower()]
