extends Node3D

# Reuse the existing Traffic node, both paths, timers and scene reference.
@export var car_scene: PackedScene
@export var vehicle_scenes: Array[PackedScene] = [
	preload("res://scenes/vehicles/car_hatchback.tscn"),
	preload("res://scenes/vehicles/car_sedan.tscn"),
	preload("res://scenes/vehicles/car_wagon.tscn"),
	preload("res://scenes/vehicles/car_compact.tscn"),
	preload("res://scenes/vehicles/taxi.tscn"),
	preload("res://scenes/vehicles/city_bus.tscn")
]
@export var spawn_weights: PackedFloat32Array = PackedFloat32Array([22, 24, 17, 17, 12, 8])
@export var min_spawn_delay: float = 6.0
@export var max_spawn_delay: float = 15.0
@export var spawn_clearance: float = 7.0
@export var max_vehicles: int = 4
@export var bus_cooldown: float = 45.0
@export var taxi_cooldown: float = 22.0
var _elapsed: float = 0.0
var _bus_available: float = 0.0
var _taxi_available: float = 0.0
var _last_was_pair: bool = false
var _retry_lane: Path3D
@onready var lane_forward: Path3D = $LaneForward
@onready var lane_backward: Path3D = $LaneBackward
@onready var forward_timer: Timer = $ForwardTimer
@onready var backward_timer: Timer = $BackwardTimer

func _ready() -> void:
	# The scene renders through a SubViewport; spatial sound needs its listener enabled.
	get_viewport().audio_listener_enable_3d = true
	# One global schedule avoids doubling the traffic density.
	backward_timer.stop()
	forward_timer.one_shot = true
	forward_timer.timeout.connect(_on_spawn_timeout)
	_schedule_next()

func _process(delta: float) -> void:
	_elapsed += delta

func _on_spawn_timeout() -> void:
	var lane: Path3D = _retry_lane if is_instance_valid(_retry_lane) else (lane_forward if randf() < 0.5 else lane_backward)
	if _try_spawn_car(lane):
		_retry_lane = null
		_schedule_next()
	else:
		_retry_lane = lane
		forward_timer.start(randf_range(1.5, 2.5))

func _try_spawn_car(lane: Path3D) -> bool:
	if _get_car_count(lane_forward) + _get_car_count(lane_backward) >= max_vehicles:
		return false
	var index := _choose_vehicle()
	if index < 0:
		return false
	var scene: PackedScene = car_scene if index == 0 and car_scene != null else vehicle_scenes[index]
	var car := scene.instantiate() as WaitVehicle
	if car == null:
		return false
	for child in lane.get_children():
		if child is WaitVehicle:
			if child.progress < (child.vehicle_length + car.vehicle_length) * 0.5 + spawn_clearance:
				car.free()
				return false
	car.setup(randf_range(car.speed_range.x, car.speed_range.y))
	lane.add_child(car)
	if car.vehicle_type == "bus":
		_bus_available = _elapsed + bus_cooldown
	elif car.vehicle_type == "taxi":
		_taxi_available = _elapsed + taxi_cooldown
	return true

func _choose_vehicle() -> int:
	var weights := spawn_weights.duplicate()
	if weights.size() != vehicle_scenes.size():
		push_error("Traffic: scene and weight counts must match")
		return -1
	if _elapsed < _taxi_available and weights.size() > 4:
		weights[4] = 0.0
	if _elapsed < _bus_available and weights.size() > 5:
		weights[5] = 0.0
	var total := 0.0
	for i in weights.size():
		weights[i] = maxf(weights[i], 0.0) if vehicle_scenes[i] != null else 0.0
		total += weights[i]
	if total <= 0.0:
		return -1
	var choice := randf() * total
	for i in weights.size():
		choice -= weights[i]
		if choice < 0.0:
			return i
	return weights.size() - 1

func _get_car_count(lane: Path3D) -> int:
	var count := 0
	for child in lane.get_children():
		if child is WaitVehicle and not child.is_queued_for_deletion():
			count += 1
	return count

func _schedule_next() -> void:
	var pair := not _last_was_pair and randf() < 0.15
	forward_timer.start(randf_range(2.5, 4.0) if pair else randf_range(min_spawn_delay, max_spawn_delay))
	_last_was_pair = pair
