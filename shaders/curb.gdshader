shader_type spatial;

uniform sampler2D concrete_texture : source_color, filter_nearest, repeat_enable;
uniform float block_length : hint_range(0.5, 2.0) = 1.2;
uniform float joint_width : hint_range(0.005, 0.04) = 0.018;
varying vec3 world_position;
varying vec3 world_normal;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}

void fragment() {
	vec3 normal_weight = pow(abs(world_normal), vec3(16.0));
	normal_weight /= max(dot(normal_weight, vec3(1.0)), 0.0001);
	vec3 p = world_position / block_length;
	vec3 concrete = texture(concrete_texture, p.zy).rgb * normal_weight.x
		+ texture(concrete_texture, p.xz).rgb * normal_weight.y
		+ texture(concrete_texture, p.xy).rgb * normal_weight.z;
	// All long curb runs follow world X. Joints continue across top and face.
	float joint = 1.0 - step(joint_width / block_length, fract(p.x));
	ALBEDO = concrete * mix(vec3(0.91, 0.94, 0.95), vec3(0.47), joint);
	ROUGHNESS = 0.78;
	SPECULAR = 0.2;
}
