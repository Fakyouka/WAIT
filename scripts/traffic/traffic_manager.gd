extends Node3D


@export var car_scene: PackedScene


@export_group("Spawn")

@export var min_spawn_delay: float = 2.5
@export var max_spawn_delay: float = 7.0

@export var spawn_clearance: float = 8.0

@export var max_cars_per_lane: int = 6


@export_group("Speed")

@export var min_car_speed: float = 6.5
@export var max_car_speed: float = 10.0


@onready var lane_forward: Path3D = $LaneForward
@onready var lane_backward: Path3D = $LaneBackward

@onready var forward_timer: Timer = $ForwardTimer
@onready var backward_timer: Timer = $BackwardTimer


func _ready() -> void:
	forward_timer.one_shot = true
	backward_timer.one_shot = true

	forward_timer.timeout.connect(_on_forward_timer_timeout)
	backward_timer.timeout.connect(_on_backward_timer_timeout)

	_schedule_forward()
	_schedule_backward()


func _on_forward_timer_timeout() -> void:
	_try_spawn_car(lane_forward)
	_schedule_forward()


func _on_backward_timer_timeout() -> void:
	_try_spawn_car(lane_backward)
	_schedule_backward()


func _try_spawn_car(lane: Path3D) -> void:
	if car_scene == null:
		return

	if _get_car_count(lane) >= max_cars_per_lane:
		return

	if not _spawn_position_is_clear(lane):
		return

	var car = car_scene.instantiate()

	var speed := randf_range(
		min_car_speed,
		max_car_speed
	)

	car.setup(speed)

	lane.add_child(car)


func _spawn_position_is_clear(lane: Path3D) -> bool:
	for child in lane.get_children():

		if child is PathFollow3D:

			if child.progress < spawn_clearance:
				return false

	return true


func _get_car_count(lane: Path3D) -> int:
	var count := 0

	for child in lane.get_children():

		if child is PathFollow3D:
			count += 1

	return count


func _schedule_forward() -> void:
	forward_timer.wait_time = randf_range(
		min_spawn_delay,
		max_spawn_delay
	)

	forward_timer.start()


func _schedule_backward() -> void:
	backward_timer.wait_time = randf_range(
		min_spawn_delay,
		max_spawn_delay
	)

	backward_timer.start()
