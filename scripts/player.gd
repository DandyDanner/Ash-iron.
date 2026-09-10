extends CharacterBody3D

const Profile = preload("res://scripts/character_profile.gd")
const Traveler = preload("res://scripts/traveler_model.gd")
const Axe = preload("res://scripts/starter_axe.gd")
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
var wood := 0
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
	identity_label.text = "%s · %s\nKeepsake: %s\n\nWASD Move · Shift Sprint · Space Jump\nLeft click Swing axe · E Collect wood\nC Character · Esc Release mouse · Click Resume" % [display_name, Profile.BACKGROUNDS[profile.background], Profile.KEEPSAKES[profile.keepsake]]
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
	if event is InputEventKey and event.pressed and not event.echo:
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
		axe.start_swing()
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
		if not target.is_empty() and target.collider.has_method("collect"):
			var amount: int = target.collider.collect()
			wood += amount
			if amount > 0:
				_show_feedback("+%d wood" % amount)
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
	resource_label.text = "STARTER AXE   /   WOOD  %d" % wood
	if feedback_time > 0.0:
		prompt_label.text = feedback
		return
	var hit := _aim_target()
	prompt_label.text = hit.collider.prompt() if not hit.is_empty() and hit.collider.has_method("prompt") else "Walk up to a pine and aim at its trunk."
