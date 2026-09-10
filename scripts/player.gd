extends CharacterBody3D

@export var walk_speed: float = 5.0
@export var sprint_speed: float = 8.0
@export var mouse_sensitivity: float = 0.0025

@onready var camera: Camera3D = $Camera3D

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready() -> void:
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
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
