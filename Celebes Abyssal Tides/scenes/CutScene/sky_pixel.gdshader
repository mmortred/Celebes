shader_type canvas_item;

// banded pixel-art sunset sky (top -> mid -> horizon) with ordered dithering between bands.
uniform vec4 top_color : source_color = vec4(0.06, 0.05, 0.16, 1.0);
uniform vec4 mid_color : source_color = vec4(0.24, 0.13, 0.36, 1.0);
uniform vec4 horizon_color : source_color = vec4(0.62, 0.32, 0.4, 1.0);
uniform float mid_at = 0.6;
uniform vec2 rect_size = vec2(1240.0, 315.0);
uniform float bands = 12.0;

void fragment() {
	vec2 px = floor(UV * rect_size);
	// 4x4 bayer matrix
	int idx = int(mod(px.x, 4.0)) + int(mod(px.y, 4.0)) * 4;
	float bayer[16] = float[](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);
	float d = (bayer[idx] + 0.5) / 16.0;
	float g = clamp(floor(UV.y * bands + d) / bands, 0.0, 1.0);
	vec3 col = g < mid_at ? mix(top_color.rgb, mid_color.rgb, g / mid_at)
			: mix(mid_color.rgb, horizon_color.rgb, (g - mid_at) / (1.0 - mid_at));
	COLOR = vec4(col, 1.0);
}
