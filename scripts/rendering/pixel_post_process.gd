extends CanvasLayer
## One low-resolution 3D viewport, composited once below full-resolution UI.

@export var world_viewport: SubViewport
@export var enabled: bool = true:
	set(value):
		enabled = value
		_refresh()
@export var virtual_resolution := Vector2i(640, 360):
	set(value):
		virtual_resolution = value.clamp(Vector2i(16, 16), Vector2i(7680, 4320))
		_refresh()
## Whole physical pixels with centered borders. Disable to fill more of the window.
@export var integer_scaling: bool = true:
	set(value):
		integer_scaling = value
		_refresh()

@export_category("Palette")
@export_range(2, 256, 1) var color_levels: int = 64:
	set(value):
		color_levels = value
		_refresh()
@export_range(0.0, 1.0, 0.01) var dithering_strength: float = 0.25:
	set(value):
		dithering_strength = value
		_refresh()
@export_range(0.0, 0.02, 0.0001) var grain_strength: float = 0.001:
	set(value):
		grain_strength = value
		_refresh()

@export_category("Vignette")
@export_range(0.0, 1.0, 0.01) var vignette_strength: float = 0.08:
	set(value):
		vignette_strength = value
		_refresh()
@export_range(0.0, 1.0, 0.01) var vignette_radius: float = 0.65:
	set(value):
		vignette_radius = value
		_refresh()
@export_range(0.01, 1.0, 0.01) var vignette_softness: float = 0.4:
	set(value):
		vignette_softness = value
		_refresh()

@onready var _image: TextureRect = $Image
var _material: ShaderMaterial


func _ready() -> void:
	if world_viewport == null:
		push_error("PixelPostProcess requires a WorldViewport.")
		return
	_material = ShaderMaterial.new()
	_material.shader = preload("res://shaders/pixel_post_process.gdshader")
	_image.material = _material
	_image.texture = world_viewport.get_texture()
	get_viewport().size_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	if not is_node_ready() or _material == null:
		return
	# canvas_items keeps UI sharp, but its logical coordinates can differ from pixels.
	var canvas_scale := get_viewport().get_stretch_transform().get_scale()
	var physical_size := (get_viewport().get_visible_rect().size * canvas_scale).round()
	if physical_size.x < 1.0 or physical_size.y < 1.0:
		return
	var scale_factor := minf(physical_size.x / virtual_resolution.x, physical_size.y / virtual_resolution.y)
	if enabled and integer_scaling and scale_factor >= 1.0:
		scale_factor = floorf(scale_factor)
	var image_size := Vector2(virtual_resolution) * scale_factor
	_image.size = image_size / canvas_scale
	_image.position = ((physical_size - image_size) * 0.5).floor() / canvas_scale
	world_viewport.size = virtual_resolution if enabled else Vector2i(image_size.round()).max(Vector2i(2, 2))
	_material.set_shader_parameter("effects_enabled", enabled)
	_material.set_shader_parameter("color_levels", float(color_levels))
	_material.set_shader_parameter("dithering_strength", dithering_strength)
	_material.set_shader_parameter("grain_strength", grain_strength)
	_material.set_shader_parameter("vignette_strength", vignette_strength)
	_material.set_shader_parameter("vignette_radius", vignette_radius)
	_material.set_shader_parameter("vignette_softness", vignette_softness)


func _unhandled_input(event: InputEvent) -> void:
	if world_viewport == null:
		return
	# TextureRect does not forward input automatically. Root UI gets first refusal.
	var forwarded := event
	if event is InputEventMouse:
		var image_rect := Rect2(_image.position, _image.size)
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED and not image_rect.has_point(event.position):
			return
		var input_scale := Vector2(world_viewport.size) / _image.size
		var input_transform := Transform2D.IDENTITY.scaled(input_scale)
		input_transform.origin = -_image.position * input_scale
		forwarded = event.xformed_by(input_transform)
	world_viewport.push_input(forwarded, true)
	if world_viewport.is_input_handled():
		get_viewport().set_input_as_handled()
