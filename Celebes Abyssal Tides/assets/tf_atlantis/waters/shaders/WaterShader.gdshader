shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;

// Speed and wave scale
uniform vec2 speed = vec2(1.0, .5);
uniform float wave_frequency = 2.0; // Higher = tighter ripples
uniform float wave_strength = 0.004;  // Higher = bigger wobble

// Atlantis Teal Color Controls
uniform vec4 water_tint : source_color = vec4(0.12, 0.58, 0.68, 0.5);
uniform float water_clarity : hint_range(0.0, 1.0) = 0.65;

void fragment() {
	// Use SCREEN_UV so waves flow across ALL tiles smoothly
	vec2 global_uv = SCREEN_UV;
	
	// Math-based wave offset (Global Space)
	vec2 wave_offset;
	wave_offset.x = sin(TIME * speed.x + (global_uv.y * wave_frequency)) * wave_strength;
	wave_offset.y = cos(TIME * speed.y + (global_uv.x * wave_frequency)) * wave_strength;
	
	// 1. Sample distorted ground underneath
	vec4 ground_color = texture(screen_texture, SCREEN_UV + wave_offset);
	
	// 2. Static tile shape (keeps exact tile boundaries intact)
	vec4 water_tile = texture(TEXTURE, UV);
	
	// 3. Color blending
	vec4 final_color = mix(ground_color, water_tint, 1.0 - water_clarity);
	final_color.rgb += water_tile.rgb * 0.2;
	final_color.a = water_tile.a;
	
	COLOR = final_color;
}