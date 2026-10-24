shader_type canvas_item;

// tall underwater column: the pixel water texture (caustics) shows near the surface
// and fades out with depth, while the colour bands down to the deep.
// `rect_size` must match the rect so tiles keep their pixel size.
uniform sampler2D water : repeat_enable, filter_nearest;
uniform vec2 rect_size = vec2(1040.0, 902.0);
uniform vec2 tile_size = vec2(64.0, 64.0);
uniform vec2 drift = vec2(4.0, 1.0); // pixels per second
uniform float wobble = 1.5; // sideways sway in pixels
uniform vec4 top_color : source_color = vec4(0.08, 0.12, 0.24, 1.0);
uniform vec4 mid_color : source_color = vec4(0.1, 0.08, 0.2, 1.0);
uniform vec4 deep_color : source_color = vec4(0.27, 0.1, 0.24, 1.0);
uniform float texture_depth = 0.35; // texture is gone by this far down (0..1)
uniform float bands = 18.0;

void fragment() {
	vec2 px = floor(UV * rect_size);
	vec2 tp = px;
	tp.x += floor(sin(px.y * 0.15 + TIME * 1.2) * wobble);
	tp += floor(drift * TIME);
	vec3 tex = texture(water, tp / tile_size).rgb;

	// banded, dithered depth gradient
	float dither = mod(px.x + px.y, 2.0) * 0.5 / bands;
	float d = floor((UV.y + dither) * bands) / bands;
	vec3 base = d < 0.5 ? mix(top_color.rgb, mid_color.rgb, d / 0.5)
			: mix(mid_color.rgb, deep_color.rgb, (d - 0.5) / 0.5);

	float lum = dot(tex, vec3(0.333));
	float t = 1.0 - smoothstep(0.0, texture_depth, UV.y);
	vec3 col = mix(base, base * (0.5 + lum * 1.2) + vec3(0.0, 0.03, 0.06), t * 0.85);
	COLOR = vec4(col, 1.0);
}
