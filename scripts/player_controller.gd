extends CharacterBody3D

@export var move_speed: float = 5.5
@export var sprint_speed: float = 8.5
@export var jump_velocity: float = 4.5
@export var mouse_sensitivity: float = 0.005

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _pitch_limit := deg_to_rad(89.0)

@onready var _head: Node3D = $Head

func _ready() -> void:
    _ensure_default_actions()
    Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion:
        _rotate_view(event)
    elif event.is_action_pressed("ui_cancel"):
        Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _physics_process(delta: float) -> void:
    var input_dir := _get_input_direction()
    var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y))
    var target_speed := sprint_speed if Input.is_action_pressed("move_sprint") else move_speed

    if direction != Vector3.ZERO:
        direction = direction.normalized()
        velocity.x = direction.x * target_speed
        velocity.z = direction.z * target_speed
    else:
        velocity.x = move_toward(velocity.x, 0, target_speed)
        velocity.z = move_toward(velocity.z, 0, target_speed)

    if not is_on_floor():
        velocity.y -= _gravity * delta
    elif Input.is_action_just_pressed("move_jump"):
        velocity.y = jump_velocity
    else:
        velocity.y = 0.0

    move_and_slide()

func _get_input_direction() -> Vector2:
    var forward := int(Input.is_action_pressed("move_forward")) - int(Input.is_action_pressed("move_back"))
    var right := int(Input.is_action_pressed("move_right")) - int(Input.is_action_pressed("move_left"))
    return Vector2(right, forward)

func _rotate_view(event: InputEventMouseMotion) -> void:
    rotate_y(-event.relative.x * mouse_sensitivity)
    var new_pitch := clamp(_head.rotation.x - event.relative.y * mouse_sensitivity, -_pitch_limit, _pitch_limit)
    _head.rotation.x = new_pitch

func _ensure_default_actions() -> void:
    _ensure_action("move_forward", [Key.KEY_W, Key.KEY_UP])
    _ensure_action("move_back", [Key.KEY_S, Key.KEY_DOWN])
    _ensure_action("move_left", [Key.KEY_A, Key.KEY_LEFT])
    _ensure_action("move_right", [Key.KEY_D, Key.KEY_RIGHT])
    _ensure_action("move_jump", [Key.KEY_SPACE])
    _ensure_action("move_sprint", [Key.KEY_SHIFT])

func _ensure_action(action_name: StringName, key_list: Array) -> void:
    if not InputMap.has_action(action_name):
        InputMap.add_action(action_name)

    for keycode in key_list:
        var key_event := InputEventKey.new()
        key_event.keycode = keycode
        key_event.physical_keycode = keycode

        if not InputMap.action_has_event(action_name, key_event):
            InputMap.action_add_event(action_name, key_event)
