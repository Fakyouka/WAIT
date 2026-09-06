extends SceneTree

var failures: Array[String] = []
var main: Node
var traffic: Node

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)

func _run() -> void:
	seed(1907)
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	traffic = main.get_node("WorldViewport/Traffic")
	traffic.set_process(false)
	traffic.forward_timer.stop()
	var viewport: SubViewport = main.get_node("WorldViewport")
	var camera := viewport.get_camera_3d()
	_check(viewport.audio_listener_enable_3d, "SubViewport spatial audio enabled")
	_check(camera != null, "Player camera is the active listener")
	for scene: PackedScene in traffic.vehicle_scenes:
		for lane: Path3D in [traffic.lane_forward, traffic.lane_backward]:
			var car := scene.instantiate() as WaitVehicle
			car.setup(car.speed_range.x)
			lane.add_child(car)
			car.set_process(false)
			_check(car.get_node("Wheels").get_child_count() == 4, "Four wheels: " + car.vehicle_type)
			_check(car.get_node("Lights").get_child_count() == 2, "Two headlights")
			_check(car.global_position.distance_to(camera.global_position) > 47.0, "Spawn outside dissolve/audio ranges")
			_check(not car._pass_by_played, "No pass-by on spawn")
			var before := car.global_position
			car._process(0.1)
			_check(absf(angle_difference(car.get_node("Wheels/FrontLeft").rotation.x, -car.progress / car.wheel_radius)) < 0.001, "Wheel angular displacement matches travel/radius")
			_check((car.global_position - before).normalized().dot(-car.global_basis.z) > 0.99, "Forward orientation: " + car.vehicle_type)
			_check(absf(car.global_position.y - car.road_surface_y) < 0.001, "Wheels touch road")
			_check(car.driving_loop.volume_db < -60.0, "Inaudible initial loop")
			var pass_progress := -1.0
			for i in 1000:
				if car.is_queued_for_deletion():
					break
				car._process(0.02)
				if car._pass_by_played and pass_progress < 0.0:
					pass_progress = car.global_position.distance_to(camera.global_position)
			_check(pass_progress > 0.0 and pass_progress < 13.0, "Pass-by near camera: " + car.vehicle_type)
			_check(car.is_queued_for_deletion(), "Despawn at end: " + car.vehicle_type)
			car.free()
	# A fast car catching a slower long bus must keep bumper clearance.
	var bus: WaitVehicle = traffic.vehicle_scenes[5].instantiate()
	var follower: WaitVehicle = traffic.vehicle_scenes[4].instantiate()
	traffic.lane_forward.add_child(bus)
	traffic.lane_forward.add_child(follower)
	bus.set_process(false)
	follower.set_process(false)
	bus.progress = 17.0
	bus.setup(3.0)
	follower.setup(13.0)
	for i in 500:
		bus._process(0.02)
		follower._process(0.02)
		_check(bus.progress - follower.progress - (bus.vehicle_length + follower.vehicle_length) * 0.5 >= 1.499, "Bumper clearance")
	follower.move_speed = 0.0
	for i in 200:
		follower._process(0.02)
	var angle: float = follower.get_node("Wheels/FrontLeft").rotation.x
	follower._process(0.1)
	_check(is_equal_approx(angle, follower.get_node("Wheels/FrontLeft").rotation.x), "Stopped wheel stays still")
	bus.free()
	follower.free()
	# Distribution and rarity are tested independently of the random scheduler.
	var counts := [0, 0, 0, 0, 0, 0]
	for i in 10000:
		counts[traffic._choose_vehicle()] += 1
	for i in counts.size():
		_check(absf(counts[i] / 100.0 - traffic.spawn_weights[i]) < 2.0, "Weighted distribution")
	traffic._bus_available = 45.0
	traffic._taxi_available = 22.0
	for i in 1000:
		_check(traffic._choose_vehicle() < 4, "Special vehicle cooldown")
	traffic._bus_available = 0.0
	traffic._taxi_available = 0.0
	_check(traffic._try_spawn_car(traffic.lane_forward), "First spawn")
	_check(not traffic._try_spawn_car(traffic.lane_forward), "Occupied spawn rejected")
	_clear_lanes()
	for i in 4:
		var car: WaitVehicle = traffic.vehicle_scenes[0].instantiate()
		traffic.lane_forward.add_child(car)
		car.set_process(false)
		car.progress = 20.0 + i * 15.0
	_check(not traffic._try_spawn_car(traffic.lane_backward), "Global cap enforced")
	_clear_lanes()
	print("TRAFFIC VALIDATION: ", failures.size(), " failures; weights ", counts)
	if "--capture" in OS.get_cmdline_user_args():
		await _capture(viewport)
	if "--live" in OS.get_cmdline_user_args():
		await _live_audio_check()
	if "--benchmark" in OS.get_cmdline_user_args():
		await _benchmark()
	main.queue_free()
	await process_frame
	await process_frame
	quit(0 if failures.is_empty() else 1)

func _clear_lanes() -> void:
	for lane in [traffic.lane_forward, traffic.lane_backward]:
		for child in lane.get_children():
			if child is WaitVehicle:
				child.free()

func _capture(viewport: SubViewport) -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	for i in 6:
		var car: WaitVehicle = traffic.vehicle_scenes[i].instantiate()
		traffic.lane_forward.add_child(car)
		car.set_process(false)
		car.progress = 48.0
		car._age = 5.0
		car._update_height()
		car._update_audio()
		for frame in 8:
			await process_frame
		await RenderingServer.frame_post_draw
		var output := OS.get_environment("TEMP").path_join("wait_vehicle_" + car.vehicle_type + ".png")
		viewport.get_texture().get_image().save_png(output)
		print("CAPTURE ", output)
		car.free()
	# Look along the far lane from the same seated player position.
	var player: Node3D = main.get_node("WorldViewport/Player")
	var original_yaw := player.rotation.y
	for index in [4, 5]:
		var car: WaitVehicle = traffic.vehicle_scenes[index].instantiate()
		traffic.lane_backward.add_child(car)
		car.set_process(false)
		car.progress = 42.0
		car._age = 5.0
		car._update_height()
		car._update_audio()
		var offset := car.global_position - viewport.get_camera_3d().global_position
		player.rotation.y = original_yaw + atan2(offset.x, offset.z)
		for frame in 8:
			await process_frame
		await RenderingServer.frame_post_draw
		viewport.get_texture().get_image().save_png(OS.get_environment("TEMP").path_join("wait_vehicle_" + car.vehicle_type + "_approach.png"))
		car.free()
	player.rotation.y = original_yaw

func _live_audio_check() -> void:
	# Real audio mixing and rendered frames, without changing the saved player/camera.
	var traffic_bus := AudioServer.get_bus_index("Traffic")
	var rain_bus := AudioServer.get_bus_index("Ambience")
	var car: WaitVehicle = traffic.vehicle_scenes[0].instantiate()
	var bus: WaitVehicle = traffic.vehicle_scenes[5].instantiate()
	car.setup(9.0)
	bus.setup(6.5)
	traffic.lane_forward.add_child(car)
	traffic.lane_backward.add_child(bus)
	var loudest := -200.0
	var frames := 0
	var total_frame_time := 0.0
	for second in 17:
		await create_timer(1.0).timeout
		var peak := maxf(AudioServer.get_bus_peak_volume_left_db(traffic_bus, 0), AudioServer.get_bus_peak_volume_right_db(traffic_bus, 0))
		loudest = maxf(loudest, peak)
		frames += 1
		total_frame_time += Performance.get_monitor(Performance.TIME_PROCESS)
		print("LIVE t=", second + 1, " traffic_peak_db=", snappedf(peak, 0.1), " rain_peak_db=", snappedf(AudioServer.get_bus_peak_volume_left_db(rain_bus, 0), 0.1), " draw_calls=", Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	_check(loudest > -70.0, "Spatial audio reaches the Traffic bus")
	print("LIVE average sampled CPU process ms=", total_frame_time / frames * 1000.0, " failures=", failures.size())

func _benchmark() -> void:
	for phase in 2:
		if phase == 1:
			for i in 4:
				var car: WaitVehicle = traffic.vehicle_scenes[[0, 1, 4, 5][i]].instantiate()
				var lane: Path3D = traffic.lane_forward if i < 2 else traffic.lane_backward
				lane.add_child(car)
				car.progress = 43.0 + (i % 2) * 13.0
				car.set_process(false)
				car._age = 5.0
				car._update_height()
				car._update_audio()
		await create_timer(2.0).timeout
		var frames := 0
		var start := Time.get_ticks_msec()
		while Time.get_ticks_msec() - start < 4000:
			await process_frame
			frames += 1
		print("BENCHMARK vehicles=", phase * 4, " fps=", frames / 4.0, " draw_calls=", Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	_clear_lanes()

