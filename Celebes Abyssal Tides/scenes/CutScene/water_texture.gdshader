shader_type canvas_item;

// tiled pixel water texture that drifts slowly, darkening toward the deep.
// put it on a ColorRect; `rect_size` must match the rect so tiles keep their pixel size.
uniform sampler2D water : repeat_enable, filter_nearest;
uniform vec2 rect_size = vec2(800.0, 182.0);
uniform vec2 tile_size = vec2(64.0, 64.0);
uniform vec2 drift = vec2(4.0, 1.0); // pixels per second
uniform float wobble = 1.5; // sideways sway in pixels
uniform vec4 deep_color : source_color = vec4(0.27, 0.1, 0.24, 1.0);
uniform float deep_start = 0.35; // where the darkening starts (0 = top, 1 = bottom)

void fragment() {
	vec2 px = floor(UV * rect_size);
	px.x += floor(sin(px.y * 0.15 + TIME * 1.2) * wobble);
	px += floor(drift * TIME);
	vec4 col = texture(water, px / tile_size);
	float deep = smoothstep(deep_start, 1.0, UV.y);
	COLOR = vec4(mix(col.rgb, deep_color.rgb, deep), 1.0);
}
