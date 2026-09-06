shader_type canvas_item;
render_mode unshaded, blend_disabled;

uniform bool effects_enabled = true;
uniform float color_levels : hint_range(2.0, 256.0, 1.0) = 64.0;
uniform float dithering_strength : hint_range(0.0, 1.0) = 0.25;
uniform float grain_strength : hint_range(0.0, 0.02) = 0.001;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.08;
uniform float vignette_radius : hint_range(0.0, 1.0) = 0.65;
uniform float vignette_softness : hint_range(0.01, 1.0) = 0.4;

const float BAYER[16] = float[16](
	0.0, 8.0, 2.0, 10.0,
	12.0, 4.0, 14.0, 6.0,
	3.0, 11.0, 1.0, 9.0,
	15.0, 7.0, 13.0, 5.0
);

void fragment() {
	vec2 pixel = floor(UV / TEXTURE_PIXEL_SIZE);
	vec2 uv = (pixel + 0.5) * TEXTURE_PIXEL_SIZE;
	vec3 color = texture(TEXTURE, uv).rgb;
	if (effects_enabled) {
		ivec2 cell = ivec2(mod(pixel, 4.0));
		float dither = (BAYER[cell.y * 4 + cell.x] + 0.5) / 16.0 - 0.5;
		float steps = max(color_levels - 1.0, 1.0);
		color = floor(clamp(color, 0.0, 1.0) * steps + 0.5 + dither * dithering_strength) / steps;
		// Static monochrome pixel grain. No TIME dependency, crawling or flicker.
		float noise = fract(52.9829189 * fract(dot(pixel, vec2(0.06711056, 0.00583715)))) - 0.5;
		color += noise * grain_strength;
		float distance_to_center = length((uv - 0.5) * 2.0) / sqrt(2.0);
		float edge = smoothstep(vignette_radius, vignette_radius + vignette_softness, distance_to_center);
		color *= 1.0 - edge * vignette_strength;
	}
	COLOR = vec4(clamp(color, 0.0, 1.0), 1.0);
}
