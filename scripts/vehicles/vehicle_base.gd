class_name WaitVehicle
extends PathFollow3D

@export var vehicle_type: String = "hatchback"
@export var speed_range: Vector2 = Vector2(8.0, 11.0)
@export var move_speed: float = 9.0
@export var wheel_radius: float = 0.3
@export var vehicle_length: float = 3.7
@export var can_randomize_color: bool = true
@export var driving_volume_db: float = -20.0
@export var pass_by_volume_db: float = -15.0
@export var acceleration: float = 2.0
@export var braking: float = 6.0
@export var safe_distance: float = 4.0
@export var road_surface_y: float = -0.14453

const PALETTE: Array[Color] = [
	Color("374856"), Color("777977"), Color("b0aca0"), Color("714443"),
	Color("5b6b5e"), Color("a39579"), Color("303438")
]
var current_speed: float = 0.0
var _age: float = 0.0
var _pitch: float = 1.0
var _pass_by_played: bool = false
var _previous_along: float = INF
var _paint: ShaderMaterial
@onready var driving_loop: AudioStreamPlayer3D = $Audio/DrivingLoop
@onready var pass_by: AudioStreamPlayer3D = $Audio/PassBy
@onready var wheels: Node3D = $Wheels

func setup(speed: float) -> void:
	move_speed = speed
	current_speed = speed

func _ready() -> void:
	loop = false
	rotation_mode = PathFollow3D.ROTATION_Y
	use_model_front = false # Models face local -Z, including both SpotLights.
	current_speed = move_speed
	_update_height()
	_pitch = randf_range(0.97, 1.03)
	if can_randomize_color:
		_randomize_paint($Body)
	driving_loop.volume_db = -60.0
	driving_loop.pitch_scale = _pitch
	driving_loop.play(randf_range(0.0, driving_loop.stream.get_length()))
	pass_by.volume_db = pass_by_volume_db
	pass_by.pitch_scale = _pitch

func _randomize_paint(node: Node) -> void:
	if node is MeshInstance3D and node.has_meta("body_paint"):
		if _paint == null:
			_paint = node.material_override.duplicate() as ShaderMaterial
			_paint.set_shader_parameter("paint_color", PALETTE.pick_random())
		node.material_override = _paint
	for child in node.get_children():
		_randomize_paint(child)

func _process(delta: float) -> void:
	_age += delta
	var ahead := _get_car_ahead()
	var desired_speed := maxf(move_speed, 0.0)
	var maximum_step := INF
	if ahead != null:
		var gap := ahead.progress - progress - (vehicle_length + ahead.vehicle_length) * 0.5
		var following_distance := safe_distance + current_speed * 0.9
		if gap < following_distance:
			desired_speed = minf(desired_speed, ahead.current_speed * clampf((gap - 1.5) / following_distance, 0.0, 1.0))
		maximum_step = maxf(0.0, gap - 1.5)
	current_speed = move_toward(current_speed, desired_speed, (braking if desired_speed < current_speed else acceleration) * delta)
	var old_progress := progress
	progress += minf(current_speed * delta, maximum_step)
	var travelled := progress - old_progress
	current_speed = travelled / maxf(delta, 0.00001)
	_update_height()
	for wheel: Node3D in wheels.get_children():
		wheel.rotate_x(-travelled / maxf(wheel_radius, 0.01))
	_update_audio()
	if progress_ratio >= 0.9999:
		queue_free()

func _update_height() -> void:
	var lane := get_parent() as Path3D
	if lane != null and lane.curve != null:
		v_offset = road_surface_y - lane.to_global(lane.curve.sample_baked(progress)).y

func _update_audio() -> void:
	var listener := get_viewport().get_camera_3d()
	if listener == null:
		return
	var to_listener := listener.global_position - global_position
	var distance := to_listener.length()
	var fade := smoothstep(0.0, 1.8, _age) * (1.0 - smoothstep(25.0, 36.0, distance))
	var motion := clampf(current_speed / maxf(move_speed, 0.1), 0.0, 1.0)
	driving_loop.volume_db = driving_volume_db + linear_to_db(maxf(fade * lerpf(0.12, 1.0, motion), 0.001))
	driving_loop.pitch_scale = _pitch * lerpf(0.97, 1.0, motion)
	var along := to_listener.dot(-global_basis.z)
	var trigger_distance := current_speed * 0.18
	# Short attack just before closest approach, never on spawn.
	if not _pass_by_played and _age > 1.8 and distance < 13.0 and current_speed > 1.0:
		if _previous_along > trigger_distance and along <= trigger_distance:
			pass_by.play()
			_pass_by_played = true
	_previous_along = along
	for light: SpotLight3D in $Lights.get_children():
		light.light_energy = 1.1 * (1.0 - smoothstep(28.0, 42.0, distance))
		light.visible = distance < 42.0

func _get_car_ahead() -> WaitVehicle:
	var closest: WaitVehicle = null
	var closest_distance := INF
	for child in get_parent().get_children():
		if child is WaitVehicle and child != self and not child.is_queued_for_deletion():
			var separation: float = child.progress - progress
			if separation > 0.0 and separation < closest_distance:
				closest = child
				closest_distance = separation
	return closest
