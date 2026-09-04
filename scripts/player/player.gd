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

@export_category("Camera Inertia")
@export_range(0.01, 0.30, 0.005, "suffix:s") var rotation_smoothing_time: float = 0.075
@export_range(0.0, 5.0, 0.1, "suffix:°") var max_turn_roll: float = 1.4
@export_range(0.0, 1.0, 0.01) var turn_roll_influence: float = 0.35
@export_range(0.0, 0.03, 0.001, "suffix:m") var lateral_sway_distance: float = 0.008
@export_range(0.0, 0.02, 0.001, "suffix:m") var vertical_sway_distance: float = 0.004
@export_range(0.01, 0.30, 0.005, "suffix:s") var secondary_smoothing_time: float = 0.10

@export_category("Idle Breathing")
@export var idle_breathing_enabled: bool = true
@export_range(0.05, 0.50, 0.01, "suffix:Hz") var breathing_frequency: float = 0.20
@export_range(0.0, 0.01, 0.0005, "suffix:m") var breathing_height: float = 0.0015
@export_range(0.0, 0.5, 0.01, "suffix:°") var breathing_roll: float = 0.08

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D

var _initial_yaw: float
var _initial_pitch: float
var _initial_camera_position: Vector3
var _initial_camera_rotation: Vector3
var _target_yaw_offset := 0.0
var _target_pitch_offset := 0.0
var _displayed_yaw_offset := 0.0
var _displayed_pitch_offset := 0.0
var _camera_roll := 0.0
var _camera_sway := Vector3.ZERO
var _idle_time := 0.0


func _ready() -> void:
	_initial_yaw = rotation.y
	_initial_pitch = head.rotation.x
	_initial_camera_position = camera.position
	_initial_camera_rotation = camera.rotation
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _process(delta: float) -> void:
	_update_smoothed_rotation(delta)
	_update_camera_feel(delta)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed and not event.echo:
		_toggle_mouse_capture()
		get_viewport().set_input_as_handled()
		return

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_update_look(event.relative)


func _update_look(mouse_delta: Vector2) -> void:
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


func _apply_input_curve(mouse_delta: Vector2) -> Vector2:
	var magnitude := mouse_delta.length()
	if is_zero_approx(magnitude):
		return Vector2.ZERO

	var limited_magnitude := minf(magnitude, max_mouse_delta)
	var normalized_magnitude := limited_magnitude / max_mouse_delta
	var curved_magnitude := pow(normalized_magnitude, input_curve_exponent) * max_mouse_delta
	return mouse_delta / magnitude * curved_magnitude


func _update_smoothed_rotation(delta: float) -> void:
	var weight := _smoothing_weight(delta, rotation_smoothing_time)
	_displayed_yaw_offset = lerp(_displayed_yaw_offset, _target_yaw_offset, weight)
	_displayed_pitch_offset = lerp(_displayed_pitch_offset, _target_pitch_offset, weight)

	rotation.y = _initial_yaw + _displayed_yaw_offset
	head.rotation.x = _initial_pitch + _displayed_pitch_offset


func _update_camera_feel(delta: float) -> void:
	_idle_time = fmod(_idle_time + delta, 1000.0)

	var yaw_lag := angle_difference(_displayed_yaw_offset, _target_yaw_offset)
	var pitch_lag := _target_pitch_offset - _displayed_pitch_offset
	var turn_amount := clampf(yaw_lag / deg_to_rad(8.0), -1.0, 1.0)
	var pitch_amount := clampf(pitch_lag / deg_to_rad(8.0), -1.0, 1.0)
	var target_roll := turn_amount * deg_to_rad(max_turn_roll) * turn_roll_influence
	var target_sway := Vector3(
		-turn_amount * lateral_sway_distance,
		pitch_amount * vertical_sway_distance,
		0.0
	)

	var secondary_weight := _smoothing_weight(delta, secondary_smoothing_time)
	_camera_roll = lerp(_camera_roll, target_roll, secondary_weight)
	_camera_sway = _camera_sway.lerp(target_sway, secondary_weight)

	var breathing_position := Vector3.ZERO
	var breathing_rotation := 0.0
	if idle_breathing_enabled:
		var breathing_phase := _idle_time * TAU * breathing_frequency
		breathing_position.y = sin(breathing_phase) * breathing_height
		breathing_rotation = sin(breathing_phase * 0.5 + 1.2) * deg_to_rad(breathing_roll)

	var camera_rotation := _initial_camera_rotation
	camera_rotation.z += _camera_roll + breathing_rotation
	camera.rotation = camera_rotation
	camera.position = _initial_camera_position + _camera_sway + breathing_position


func _smoothing_weight(delta: float, smoothing_time: float) -> float:
	return 1.0 - exp(-delta / maxf(smoothing_time, 0.0001))


func _toggle_mouse_capture() -> void:
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
