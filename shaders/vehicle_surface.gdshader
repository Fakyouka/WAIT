shader_type spatial;
render_mode diffuse_burley;
uniform vec4 paint_color : source_color = vec4(0.36, 0.4, 0.43, 1.0);
uniform float surface_roughness = 0.65;
uniform float glow = 0.0;
uniform bool pixel_wear = false;
varying vec3 local_position;
varying vec3 world_position;
void vertex() {
	local_position = VERTEX;
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	float visibility = 1.0 - smoothstep(32.0, 42.0, distance(world_position, CAMERA_POSITION_WORLD));
	ivec2 cell = ivec2(mod(FRAGCOORD.xy, 4.0));
	int bayer[16] = int[16](0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5);
	if (visibility < (float(bayer[cell.y * 4 + cell.x]) + 0.5) / 16.0) { discard; }
	vec3 pixel = floor(local_position * 16.0);
	float grain = fract(sin(dot(pixel, vec3(12.9898, 78.233, 39.425))) * 43758.5453);
	float wear = pixel_wear ? mix(0.94, 1.0, step(0.09, grain)) : 1.0;
	ALBEDO = paint_color.rgb * wear;
	ROUGHNESS = surface_roughness;
	SPECULAR = 0.45;
	EMISSION = paint_color.rgb * glow;
}
