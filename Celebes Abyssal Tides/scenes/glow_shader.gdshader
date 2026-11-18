shader_type canvas_item;

// underwater wobble: bends whatever is behind it and adds a little color

uniform float wave_speed : hint_range(0.0, 5.0) = 1.0;
uniform float wave_strength : hint_range(0.0, 0.05) = 0.01; // how far it bends
uniform float wave_frequency : hint_range(1.0, 50.0) = 15.0; // more = smaller waves
uniform vec4 tint_color : source_color = vec4(0.1, 0.3, 0.4, 0.15);
uniform float tint_strength : hint_range(0.0, 1.0) = 0.3;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear;

void fragment() {
	// 2 waves, one for x and one for y
	float wave_x = sin(SCREEN_UV.y * wave_frequency + TIME * wave_speed) * wave_strength;
	float wave_y = cos(SCREEN_UV.x * wave_frequency + TIME * wave_speed * 0.8) * wave_strength;

	// the screen behind this, moved a bit
	vec4 screen_color = texture(SCREEN_TEXTURE, SCREEN_UV + vec2(wave_x, wave_y));

	vec3 final_color = mix(screen_color.rgb, tint_color.rgb, tint_strength * tint_color.a);
	COLOR = vec4(final_color, 1.0);
}
