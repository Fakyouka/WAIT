extends SceneTree

# Offline authoring utility: Godot writes the reusable scenes and audio resources.
const SURFACE = preload("res://shaders/vehicle_surface.gdshader")
var paint: ShaderMaterial
var trim: ShaderMaterial
var glass: ShaderMaterial
var chrome: ShaderMaterial
var headlamp: ShaderMaterial
var taillamp: ShaderMaterial
var rubber: ShaderMaterial
var cream: ShaderMaterial
var sign_glow: ShaderMaterial
var car_loop: AudioStreamWAV
var bus_loop: AudioStreamWAV
var car_pass: AudioStreamWAV
var bus_pass: AudioStreamWAV
var vehicle: Node3D

func _initialize() -> void:
	call_deferred("_build")

func _build() -> void:
	DirAccess.make_dir_recursive_absolute("res://resources/audio/traffic")
	trim = _material(Color("292f31"))
	glass = _material(Color("354b55"), 0.25)
	chrome = _material(Color("8b8f89"), 0.4)
	headlamp = _material(Color("eee2b9"), 0.35, 1.1)
	taillamp = _material(Color("ac3028"), 0.4, 0.8)
	rubber = _material(Color("171c1e"), 0.94)
	cream = _material(Color("aaa890"))
	sign_glow = _material(Color("c2a96a"), 0.6, 0.4)
	car_loop = _sound("car_driving", 6.0, false, false)
	bus_loop = _sound("bus_driving", 6.0, true, false)
	car_pass = _sound("car_pass_by", 1.4, false, true)
	bus_pass = _sound("bus_pass_by", 1.9, true, true)
	var specs := [
		["car_hatchback", "hatchback", 3.7, 1.65, 0.29, 1.40, 2.4, 0.52, Vector2(8, 11), Color("5b6b5e")],
		["car_sedan", "sedan", 4.5, 1.76, 0.31, 1.42, 2.25, 0.08, Vector2(8, 12), Color("777977")],
		["car_wagon", "wagon", 4.75, 1.78, 0.32, 1.55, 3.05, 0.38, Vector2(8, 11), Color("714443")],
		["car_compact", "older", 3.95, 1.64, 0.30, 1.48, 2.08, 0.0, Vector2(7, 10), Color("a39579")],
		["taxi", "taxi", 4.5, 1.76, 0.31, 1.42, 2.25, 0.08, Vector2(9, 13), Color("b8a05b")],
		["city_bus", "bus", 8.6, 2.30, 0.47, 2.95, 8.0, 0.0, Vector2(6, 9), Color("61776e")]
	]
	_save_base()
	for spec in specs:
		_build_vehicle(spec)
	print("Built six WAIT vehicles and four original PCM audio resources.")
	quit()

func _material(color: Color, roughness: float = 0.7, emission: float = 0.0, wear: bool = false) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = SURFACE
	material.set_shader_parameter("paint_color", color)
	material.set_shader_parameter("surface_roughness", roughness)
	material.set_shader_parameter("glow", emission)
	material.set_shader_parameter("pixel_wear", wear)
	return material

func _node(name_string: String, parent: Node) -> Node3D:
	var node := Node3D.new()
	node.name = name_string
	parent.add_child(node, true)
	node.owner = vehicle
	return node

func _box(name_string: String, parent: Node, size: Vector3, at: Vector3, material: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var node := MeshInstance3D.new()
	node.name = name_string
	node.mesh = mesh
	node.material_override = material
	parent.add_child(node, true)
	node.owner = vehicle
	node.position = at
	if material == paint:
		node.set_meta("body_paint", true)
	return node

func _save_base() -> void:
	vehicle = PathFollow3D.new()
	vehicle.name = "Vehicle"
	vehicle.set_script(load("res://scripts/vehicles/vehicle_base.gd"))
	vehicle.loop = false
	vehicle.rotation_mode = PathFollow3D.ROTATION_Y
	_node("Body", vehicle)
	_node("Wheels", vehicle)
	_node("Lights", vehicle)
	var audio := _node("Audio", vehicle)
	for audio_name in ["DrivingLoop", "PassBy"]:
		var player := AudioStreamPlayer3D.new()
		player.name = audio_name
		player.bus = &"Traffic"
		player.unit_size = 5.0
		player.max_distance = 36.0 if audio_name == "DrivingLoop" else 24.0
		player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
		player.attenuation_filter_cutoff_hz = 6500.0
		player.attenuation_filter_db = -12.0
		player.max_db = -12.0
		player.volume_db = -20.0 if audio_name == "DrivingLoop" else -15.0
		player.stream = car_loop if audio_name == "DrivingLoop" else car_pass
		audio.add_child(player)
		player.owner = vehicle
		player.position.y = 0.5
	_save("res://scenes/vehicles/vehicle_base.tscn")
	vehicle.free()

func _build_vehicle(spec: Array) -> void:
	vehicle = load("res://scenes/vehicles/vehicle_base.tscn").instantiate()
	vehicle.name = str(spec[0]).to_pascal_case()
	vehicle.vehicle_type = spec[1]
	var length: float = spec[2]
	var width: float = spec[3]
	var radius: float = spec[4]
	var height: float = spec[5]
	var cabin_length: float = spec[6]
	var cabin_z: float = spec[7]
	vehicle.vehicle_length = length + 0.12
	vehicle.wheel_radius = radius
	vehicle.speed_range = spec[8]
	vehicle.can_randomize_color = spec[1] not in ["taxi", "bus"]
	paint = _material(spec[9], 0.55, 0.0, true)
	var body := vehicle.get_node("Body")
	var is_bus: bool = spec[1] == "bus"
	var sill := 0.34 if not is_bus else 0.54
	var belt := 0.88 if not is_bus else 1.24
	_box("LowerBody", body, Vector3(width, belt - sill, length), Vector3(0, (belt + sill) / 2, 0), paint)
	_box("Sill", body, Vector3(width + 0.025, 0.1, length * 0.94), Vector3(0, sill + 0.07, 0), trim)
	var rake := 0.0 if is_bus else (0.12 if spec[1] == "older" else 0.38)
	var rear_rake := 0.0 if is_bus else (0.08 if spec[1] == "wagon" else rake * 0.75)
	var front := cabin_z - cabin_length * 0.5
	var rear := cabin_z + cabin_length * 0.5
	var side_x := width * 0.455
	for side in [-1.0, 1.0]:
		_quad("CabinSide", body, [Vector3(side * side_x, belt, front), Vector3(side * side_x, height, front + rake), Vector3(side * side_x, height, rear - rear_rake), Vector3(side * side_x, belt, rear)], Vector3(side, 0, 0), paint)
	_quad("CabinFront", body, [Vector3(-side_x, belt, front), Vector3(-side_x, height, front + rake), Vector3(side_x, height, front + rake), Vector3(side_x, belt, front)], Vector3(0, rake, -(height - belt)).normalized(), paint)
	_quad("CabinRear", body, [Vector3(-side_x, belt, rear), Vector3(-side_x, height, rear - rear_rake), Vector3(side_x, height, rear - rear_rake), Vector3(side_x, belt, rear)], Vector3(0, rear_rake, height - belt).normalized(), paint)
	_box("Roof", body, Vector3(width * 0.93, 0.065, cabin_length - rake - rear_rake + 0.04), Vector3(0, height, cabin_z + (rake - rear_rake) * 0.5), paint)
	var window_height := height - belt - 0.20
	var window_y := belt + 0.08 + window_height * 0.5
	var bottom_y := belt + 0.09
	var top_y := height - 0.09
	var bottom_fraction := 0.09 / (height - belt)
	var top_fraction := 1.0 - bottom_fraction
	for end in [-1.0, 1.0]:
		var bottom_z := front + rake * bottom_fraction - 0.016 if end < 0 else rear - rear_rake * bottom_fraction + 0.016
		var top_z := front + rake * top_fraction - 0.016 if end < 0 else rear - rear_rake * top_fraction + 0.016
		_quad("Windshield" if end < 0 else "RearWindow", body, [Vector3(-width * 0.40, bottom_y, bottom_z), Vector3(-width * 0.40, top_y, top_z), Vector3(width * 0.40, top_y, top_z), Vector3(width * 0.40, bottom_y, bottom_z)], Vector3(0, rake, end * (height - belt)).normalized(), glass)
	var window_count := 6 if is_bus else (3 if spec[1] == "wagon" else 2)
	for side in [-1.0, 1.0]:
		for i in window_count:
			var section := (cabin_length - 0.20) / window_count
			var z := cabin_z - cabin_length * 0.5 + 0.1 + section * (i + 0.5)
			var low_front := front + 0.08 + rake * bottom_fraction
			var high_front := front + 0.08 + rake * top_fraction
			var low_rear := rear - 0.08 - rear_rake * bottom_fraction
			var high_rear := rear - 0.08 - rear_rake * top_fraction
			var fraction_start := float(i) / window_count
			var fraction_end := float(i + 1) / window_count
			var x: float = side * (side_x + 0.018)
			_quad("SideWindow", body, [Vector3(x, bottom_y, lerpf(low_front, low_rear, fraction_start) + 0.035), Vector3(x, top_y, lerpf(high_front, high_rear, fraction_start) + 0.035), Vector3(x, top_y, lerpf(high_front, high_rear, fraction_end) - 0.035), Vector3(x, bottom_y, lerpf(low_front, low_rear, fraction_end) - 0.035)], Vector3(side, 0, 0), glass)
			_box("DoorSeam", body, Vector3(0.016, belt - sill - 0.1, 0.018), Vector3(side * (width * 0.5 + 0.015), (sill + belt) * 0.5, z + section * 0.42), trim)
			if not is_bus:
				_box("Handle", body, Vector3(0.04, 0.04, 0.17), Vector3(side * (width * 0.5 + 0.025), belt - 0.1, z + section * 0.27), chrome)
		_box("SideMoulding", body, Vector3(0.035, 0.045, length * 0.95), Vector3(side * (width * 0.5 + 0.02), belt - 0.18, 0), trim)
		_box("Mirror", body, Vector3(0.17, 0.13, 0.20), Vector3(side * (width * 0.5 + 0.08), belt + 0.10, cabin_z - cabin_length * 0.5 + 0.1), paint)
	for end in [-1.0, 1.0]:
		_box("Bumper", body, Vector3(width + 0.04, 0.14, 0.14), Vector3(0, sill + 0.10, end * length * 0.5), trim)
		_box("LicensePlate", body, Vector3(0.36, 0.11, 0.024), Vector3(0, sill + 0.17, end * (length * 0.5 + 0.08)), cream)
		for side in [-1.0, 1.0]:
			_box("Headlamp" if end < 0 else "TailLamp", body, Vector3(0.30 if not is_bus else 0.38, 0.14, 0.038), Vector3(side * width * 0.34, belt - 0.18, end * (length * 0.5 + 0.025)), headlamp if end < 0 else taillamp)
	for i in 4:
		_box("Grille", body, Vector3(width * 0.32, 0.02, 0.025), Vector3(0, belt - 0.29 + i * 0.05, -length * 0.5 - 0.025), trim)
	var wheelbase := length * (0.65 if is_bus else 0.64)
	for side in [-1.0, 1.0]:
		for end in [-1.0, 1.0]:
			var wheel_name := ("Front" if end < 0 else "Rear") + ("Left" if side < 0 else "Right")
			var wheel := _node(wheel_name, vehicle.get_node("Wheels"))
			wheel.position = Vector3(side * width * 0.49, radius, end * wheelbase * 0.5)
			var cylinder := CylinderMesh.new()
			cylinder.top_radius = radius
			cylinder.bottom_radius = radius
			cylinder.height = 0.22 if not is_bus else 0.29
			cylinder.radial_segments = 12
			cylinder.rings = 1
			var tire := MeshInstance3D.new()
			tire.name = "Tire"
			tire.mesh = cylinder
			tire.material_override = rubber
			wheel.add_child(tire)
			tire.owner = vehicle
			tire.rotation.z = PI / 2
			for spoke in 3:
				var angle := spoke * PI / 3.0
				var hub := _box("HubSpoke", wheel, Vector3(0.025, radius * 1.15, 0.045), Vector3(side * (cylinder.height * 0.5 + 0.016), 0, 0), chrome)
				hub.rotation.x = angle
	for side in [-1.0, 1.0]:
		var light := SpotLight3D.new()
		light.name = "HeadlightLeft" if side < 0 else "HeadlightRight"
		vehicle.get_node("Lights").add_child(light)
		light.owner = vehicle
		light.position = Vector3(side * width * 0.34, belt - 0.18, -length * 0.5 - 0.08)
		light.rotation.x = deg_to_rad(-7.0)
		light.light_color = Color("fff0d5")
		light.light_energy = 1.1
		light.spot_range = 14.0
		light.spot_angle = 32.0
		light.spot_attenuation = 1.5
		light.shadow_enabled = false
	if spec[1] == "taxi":
		_box("TaxiSign", body, Vector3(0.73, 0.24, 0.28), Vector3(0, height + 0.17, 0), sign_glow)
		_pixel_text("TAXI", body, Vector3(-0.31, height + 0.24, -0.15), 0.041, trim)
		for side in [-1.0, 1.0]:
			for i in 12:
				_box("Checker", body, Vector3(0.026, 0.075, 0.075), Vector3(side * (width * 0.5 + 0.04), belt - 0.07 - (i % 2) * 0.075, -0.5 + i * 0.085), trim)
	if is_bus:
		_box("CreamBand", body, Vector3(width + 0.028, 0.23, length + 0.025), Vector3(0, 1.12, 0), cream)
		_box("RouteDisplay", body, Vector3(0.92, 0.36, 0.04), Vector3(0, height - 0.24, -cabin_length * 0.5 - 0.04), trim)
		_pixel_text("12", body, Vector3(-0.23, height - 0.12, -cabin_length * 0.5 - 0.068), 0.058, sign_glow)
		for z in [-2.8, 1.7]:
			_box("PassengerDoor", body, Vector3(0.04, 1.95, 0.9), Vector3(width * 0.5 + 0.04, 1.42, z), trim)
			for panel_z in [-0.22, 0.22]:
				_box("DoorGlass", body, Vector3(0.024, 1.4, 0.36), Vector3(width * 0.5 + 0.07, 1.65, z + panel_z), glass)
		vehicle.driving_volume_db = -18.0
		vehicle.pass_by_volume_db = -13.0
		vehicle.get_node("Audio/DrivingLoop").stream = bus_loop
		vehicle.get_node("Audio/PassBy").stream = bus_pass
	# Bake static details by material; four wheel pivots stay independently animated.
	_merge_meshes(body)
	for wheel in vehicle.get_node("Wheels").get_children():
		_merge_meshes(wheel)
	_save("res://scenes/vehicles/" + spec[0] + ".tscn")
	vehicle.free()

func _pixel_text(value: String, parent: Node, at: Vector3, pixel_size: float, material: Material) -> void:
	var font := {"T": ["111", "010", "010", "010", "010"], "A": ["010", "101", "111", "101", "101"], "X": ["101", "101", "010", "101", "101"], "I": ["111", "010", "010", "010", "111"], "1": ["010", "110", "010", "010", "111"], "2": ["110", "001", "010", "100", "111"]}
	for c in value.length():
		for y in 5:
			for x in 3:
				if font[value[c]][y][x] == "1":
					var pixel_at := at + Vector3((c * 4 + x) * pixel_size, -y * pixel_size, 0)
					pixel_at.x = -pixel_at.x # Front (-Z) is viewed with +X on the left.
					_box("Pixel", parent, Vector3(pixel_size * 0.9, pixel_size * 0.9, 0.012), pixel_at, material)

func _save(path: String) -> void:
	var packed := PackedScene.new()
	assert(packed.pack(vehicle) == OK)
	assert(ResourceSaver.save(packed, path) == OK)

func _sound(label: String, seconds: float, heavy: bool, one_shot: bool) -> AudioStreamWAV:
	var rate := 22050
	var count := int(seconds * rate)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1907 + label.hash()
	var samples := PackedFloat32Array()
	samples.resize(count)
	var low := 0.0
	var softer := 0.0
	for i in count:
		var t := float(i) / rate
		low = lerpf(low, rng.randf_range(-1.0, 1.0), 0.15 if heavy else 0.23)
		softer = lerpf(softer, low, 0.025)
		var engine := sin(TAU * (48.0 if heavy else 76.0) * t) * 0.15 + sin(TAU * (96.0 if heavy else 152.0) * t) * 0.035
		var road := (low - softer) * (0.9 if one_shot else 0.60)
		var envelope := 1.0
		if one_shot:
			envelope = smoothstep(0.0, 0.22, t) * (1.0 - smoothstep(0.28, seconds, t))
		samples[i] = (road + engine * (0.08 if one_shot else 0.65) + softer * (0.6 if heavy else 0.25)) * envelope
	# Crossfade noise across the loop seam; periodic engine tones are integer Hz.
	if not one_shot:
		var blend := 1102
		for i in blend:
			var weight := float(i) / blend
			samples[count - blend + i] = lerpf(samples[count - blend + i], samples[i], weight)
		samples = samples.slice(blend)
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.data = data
	if not one_shot:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_end = samples.size()
	var path := "res://resources/audio/traffic/" + label + ".res"
	assert(ResourceSaver.save(stream, path) == OK)
	return load(path) as AudioStreamWAV

func _quad(label: String, parent: Node, corners: Array, normal: Vector3, material: Material) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var order := [0, 1, 2, 0, 2, 3]
	var cross: Vector3 = (corners[1] - corners[0]).cross(corners[2] - corners[0])
	# Godot front faces use clockwise winding.
	if cross.dot(normal) > 0.0:
		order = [0, 2, 1, 0, 3, 2]
	for index in order:
		surface.set_normal(normal)
		surface.add_vertex(corners[index])
	# append_from must receive indexed surfaces consistently with BoxMesh.
	surface.index()
	var node := MeshInstance3D.new()
	node.name = label
	node.mesh = surface.commit()
	node.material_override = material
	parent.add_child(node, true)
	node.owner = vehicle
	if material == paint:
		node.set_meta("body_paint", true)

func _merge_meshes(parent: Node3D) -> void:
	var groups := {}
	var expected_indices := {}
	for child in parent.get_children():
		if child is MeshInstance3D:
			var material: Material = child.material_override
			if not groups.has(material):
				var surface := SurfaceTool.new()
				surface.begin(Mesh.PRIMITIVE_TRIANGLES)
				groups[material] = surface
				expected_indices[material] = 0
			var arrays: Array = child.mesh.surface_get_arrays(0)
			expected_indices[material] += arrays[Mesh.ARRAY_INDEX].size()
			groups[material].append_from(child.mesh, 0, child.transform)
			child.free()
	for material: Material in groups:
		var mesh := MeshInstance3D.new()
		mesh.name = "Paint" if material == paint else "Detail"
		mesh.mesh = groups[material].commit()
		assert(mesh.mesh.surface_get_arrays(0)[Mesh.ARRAY_INDEX].size() == expected_indices[material], "Baking must preserve every triangle")
		mesh.material_override = material
		parent.add_child(mesh, true)
		mesh.owner = vehicle
		if material == paint:
			mesh.set_meta("body_paint", true)

