extends Node3D

@export_category("Mouse Look")
@export_range(0.0001, 0.01, 0.0001) var mouse_sensitivity: float = 0.002
@export_range(1.0, 2.0, 0.01) var input_curve_exponent: float = 1.12
@export_range(10.0, 200.0, 1.0, "suffix:px") var max_mouse_delta: float = 60.0

@export_category("Look Limits")
@export_range(0.0, 180.0, 1.0, "suffix:°") var look_left_limit: float = 80.0
@export_range(0.0, 180.0, 1.0, "suffix:°") var look_right_limit: float = 80.0
@export_range(0.0, 90.0, 1.0, "suffix:°") var look_up_limit: float = 60.0
@export_range(0.0, 90.0, 1.0, "suffix:°") var look_down_limit: float = 70.0

@onready var head: Node3D = $Head
@onready var camera_effects: Node3D = $Head/CameraEffects
@onready var camera: Camera3D = $Head/CameraEffects/Camera3D

var _initial_yaw: float
var _initial_pitch: float
var _target_yaw_offset := 0.0
var _target_pitch_offset := 0.0


func _ready() -> void:
	_initial_yaw = rotation.y
	_initial_pitch = head.rotation.x
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed and not event.echo:
		_toggle_mouse_capture()
		get_viewport().set_input_as_handled()
		return

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		# Physical mouse pixels keep sensitivity independent of render resolution.
		_update_look(event.screen_relative)
		get_viewport().set_input_as_handled()


func _update_look(mouse_delta: Vector2) -> void:
	var previous := Vector2(_target_pitch_offset, _target_yaw_offset)
	var curved_delta := _apply_input_curve(mouse_delta)
	_target_yaw_offset -= curved_delta.x * mouse_sensitivity
	_target_pitch_offset -= curved_delta.y * mouse_sensitivity

	_target_yaw_offset = clamp(
		_target_yaw_offset,
		-deg_to_rad(look_right_limit),
		deg_to_rad(look_left_limit)
	)
	_target_pitch_offset = clamp(
		_target_pitch_offset,
		-deg_to_rad(look_down_limit),
		deg_to_rad(look_up_limit)
	)
	# Responsive seated pivots; only the small child visual offset lags.
	rotation.y = _initial_yaw + _target_yaw_offset
	head.rotation.x = _initial_pitch + _target_pitch_offset
	camera_effects.add_look_delta(Vector2(_target_pitch_offset, _target_yaw_offset) - previous)


func _apply_input_curve(mouse_delta: Vector2) -> Vector2:
	var magnitude := mouse_delta.length()
	if is_zero_approx(magnitude):
		return Vector2.ZERO

	var limited_magnitude := minf(magnitude, max_mouse_delta)
	var normalized_magnitude := limited_magnitude / max_mouse_delta
	var curved_magnitude := pow(normalized_magnitude, input_curve_exponent) * max_mouse_delta
	return mouse_delta / magnitude * curved_magnitude


func _toggle_mouse_capture() -> void:
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
