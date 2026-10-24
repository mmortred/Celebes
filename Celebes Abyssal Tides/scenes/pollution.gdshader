shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform sampler2D noise_tex : repeat_enable;
uniform vec4 sludge_color : source_color = vec4(0.62, 0.58, 0.32, 1.0);
uniform float tint_strength : hint_range(0.0, 1.0) = 0.75;
uniform float wobble : hint_range(0.0, 0.01) = 0.003;
uniform float fade_start = 0.35;
uniform float fade_end = 0.7;
uniform bool flip_side = false;

void fragment() {
	float x = flip_side ? 1.0 - UV.x : UV.x;
	float n = texture(noise_tex, UV * 4.0 + vec2(TIME * 0.01, TIME * 0.006)).r;

	// Pollution strength: grows toward the monster side, with a ragged noisy edge
	float mask = clamp(smoothstep(fade_start, fade_end, x) + (n - 0.5) * 0.4, 0.0, 1.0);

	// Slow oily wobble, only where polluted
	vec2 wave = vec2(sin(UV.y * 90.0 + TIME * 1.5), cos(UV.x * 90.0 + TIME * 1.2)) * wobble * mask;
	vec3 scene = texture(screen_tex, SCREEN_UV + wave).rgb;

	vec3 tinted = scene * mix(vec3(1.0), sludge_color.rgb * (0.75 + 0.5 * n), tint_strength);
	COLOR = vec4(mix(scene, tinted, mask), 1.0);
}