extends Node3D
## Small visual offsets below the responsive seated look pivots.

@export var enabled: bool = true

@export_category("Idle Breathing")
@export var breathing_enabled: bool = true
@export_range(0.0, 0.01, 0.0001, "suffix:m") var breathing_amplitude: float = 0.0015
@export_range(0.05, 0.5, 0.01, "suffix:Hz") var breathing_speed: float = 0.2

@export_category("Camera Sway")
@export var sway_enabled: bool = true
@export_range(0.0, 0.3, 0.01) var sway_strength: float = 0.08
@export_range(0.01, 0.3, 0.005, "suffix:s") var sway_smoothing: float = 0.075
@export_range(0.0, 1.0, 0.05, "suffix:°") var sway_max_angle: float = 0.35

@export_category("Micro Movement")
@export var micro_movement_enabled: bool = true
@export_range(0.0, 0.003, 0.0001, "suffix:m") var micro_movement_strength: float = 0.0007
@export_range(0.0, 0.15, 0.005, "suffix:°") var micro_rotation_strength: float = 0.025
@export_range(0.05, 0.5, 0.01, "suffix:Hz") var micro_movement_speed: float = 0.11

@export_category("Head Tilt")
@export var tilt_enabled: bool = true
@export_range(0.0, 2.0, 0.05, "suffix:°") var tilt_strength: float = 1.0
@export_range(0.01, 0.5, 0.01, "suffix:s") var tilt_smoothing: float = 0.12
@export_range(0.0, 90.0, 1.0, "suffix:°/s") var tilt_speed_threshold: float = 25.0

var _base_transform: Transform3D
var _look_delta := Vector2.ZERO
var _sway := Vector2.ZERO
var _tilt := 0.0
var _idle_weight := 1.0
var _time := 0.0


func _ready() -> void:
	_base_transform = transform


func add_look_delta(look_delta: Vector2) -> void:
	if not enabled:
		return
	_look_delta += look_delta
	if sway_enabled:
		var limit := deg_to_rad(sway_max_angle)
		_sway -= look_delta * sway_strength
		_sway = _sway.clamp(Vector2(-limit, -limit), Vector2(limit, limit))


func _process(delta: float) -> void:
	if not enabled:
		transform = _base_transform
		_look_delta = Vector2.ZERO
		_sway = Vector2.ZERO
		_tilt = 0.0
		return

	_time += delta
	var angular_speed := _look_delta / maxf(delta, 0.0001)
	_look_delta = Vector2.ZERO
	var idle_target := 1.0 - clampf(angular_speed.length() / deg_to_rad(30.0), 0.0, 1.0)
	_idle_weight = lerpf(_idle_weight, idle_target, _weight(delta, 0.35))
	_sway = _sway.lerp(Vector2.ZERO, _weight(delta, sway_smoothing)) if sway_enabled else Vector2.ZERO

	var target_tilt := 0.0
	if tilt_enabled:
		var speed := maxf(absf(rad_to_deg(angular_speed.y)) - tilt_speed_threshold, 0.0)
		target_tilt = signf(angular_speed.y) * clampf(speed / 150.0, 0.0, 1.0) * deg_to_rad(tilt_strength)
	_tilt = lerpf(_tilt, target_tilt, _weight(delta, tilt_smoothing))

	var offset := Vector3.ZERO
	var angles := Vector3(_sway.x, _sway.y, _tilt)
	if breathing_enabled:
		offset.y = sin(_time * TAU * breathing_speed) * breathing_amplitude * _idle_weight
	if micro_movement_enabled:
		var phase := _time * TAU * micro_movement_speed
		# Incommensurate slow sines, with no random jumps or wrapping discontinuities.
		var drift := Vector2(sin(phase) * 0.65 + sin(phase * 1.37) * 0.35, sin(phase * 0.73))
		offset += Vector3(drift.x, drift.y * 0.5, 0.0) * micro_movement_strength
		angles += Vector3(drift.y, drift.x, 0.0) * deg_to_rad(micro_rotation_strength)
	transform = _base_transform * Transform3D(Basis.from_euler(angles), offset)


func _weight(delta: float, smoothing: float) -> float:
	return 1.0 - exp(-delta / maxf(smoothing, 0.0001))
