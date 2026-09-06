class_name TrafficCar
extends PathFollow3D


@export var target_speed: float = 8.0

@export var acceleration: float = 3.0
@export var braking: float = 8.0

@export var safe_distance: float = 7.0
@export var emergency_distance: float = 2.5


var current_speed: float = 0.0


func _ready() -> void:
	loop = false
	rotation_mode = PathFollow3D.ROTATION_Y

	progress = 0.0
	current_speed = target_speed


func setup(speed: float) -> void:
	target_speed = speed
	current_speed = speed


func _process(delta: float) -> void:
	var desired_speed: float = target_speed

	var car_ahead: TrafficCar = _get_car_ahead()

	if car_ahead != null:
		var distance: float = car_ahead.progress - progress

		if distance < emergency_distance:
			desired_speed = 0.0

		elif distance < safe_distance:
			var distance_factor: float = inverse_lerp(
				emergency_distance,
				safe_distance,
				distance
			)

			desired_speed = min(
				target_speed,
				car_ahead.current_speed * distance_factor
			)

	var speed_change: float = acceleration

	if desired_speed < current_speed:
		speed_change = braking

	current_speed = move_toward(
		current_speed,
		desired_speed,
		speed_change * delta
	)

	progress += current_speed * delta

	if progress_ratio >= 0.999:
		queue_free()


func _get_car_ahead() -> TrafficCar:
	var closest_car: TrafficCar = null
	var closest_distance: float = INF

	for child in get_parent().get_children():
		if child == self:
			continue

		if not child is TrafficCar:
			continue

		var other_car: TrafficCar = child as TrafficCar

		var distance: float = other_car.progress - progress

		if distance <= 0.0:
			continue

		if distance < closest_distance:
			closest_distance = distance
			closest_car = other_car

	return closest_car
