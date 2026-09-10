extends CharacterBody3D

const Profile = preload("res://scripts/character_profile.gd")
const Traveler = preload("res://scripts/traveler_model.gd")
var identity_label: Label

@export var walk_speed: float = 5.0
@export var sprint_speed: float = 8.0
@export var mouse_sensitivity: float = 0.0025

@onready var camera: Camera3D = $Camera3D

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready() -> void:
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    var profile := Profile.load_profile()
    var display_name: String = profile.name if not profile.name.is_empty() else "Traveler"
    var hud := CanvasLayer.new()
    add_child(hud)
    identity_label = Label.new()
    identity_label.position = Vector2(24, 20)
    identity_label.add_theme_font_size_override("font_size", 18)
    identity_label.add_theme_color_override("font_shadow_color", Color.BLACK)
    identity_label.add_theme_constant_override("shadow_offset_x", 1)
    identity_label.add_theme_constant_override("shadow_offset_y", 2)
    identity_label.text = "%s · %s\nKeepsake: %s\n\nWASD Move · Shift Sprint · C Character\nEsc Release mouse · Click Resume" % [display_name, Profile.BACKGROUNDS[profile.background], Profile.KEEPSAKES[profile.keepsake]]
    hud.add_child(identity_label)
    # Visible cuffs and hands connect the portrait to the first-person view.
    for side in [-1.0, 1.0]:
        var sleeve := Traveler.oval(camera, Vector3(side * 0.28, -0.32, -0.44), Vector3(0.14, 0.16, 0.38), Profile.CLOTHES[profile.clothes])
        sleeve.rotation.x = -0.2
        Traveler.oval(camera, Vector3(side * 0.27, -0.29, -0.63), Vector3(0.105, 0.115, 0.15), Profile.SKINS[profile.skin])

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_C:
        get_tree().change_scene_to_file("res://scenes/character_creator.tscn")
        return
    if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        rotate_y(-event.relative.x * mouse_sensitivity)
        camera.rotation.x = clamp(
            camera.rotation.x - event.relative.y * mouse_sensitivity,
            deg_to_rad(-85.0),
            deg_to_rad(85.0)
        )

    if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

    if event is InputEventMouseButton and event.pressed and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
    if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
        return
    if not is_on_floor():
        velocity.y -= gravity * delta
    else:
        velocity.y = 0.0

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
