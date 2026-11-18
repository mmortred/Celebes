shader_type canvas_item;

// glowing rings around the clam
// based on https://godotshaders.com/shader/shock-wave-animation/ (changed a bit)

uniform float time_scale = 1.0; // speeds up or slows down everything
uniform vec4 primary_color : source_color = vec4(1.0, 0.0, 0.0, 1.0);
uniform vec4 secondary_color : source_color = vec4(0.0, 1.0, 0.0, 1.0);
uniform float turbulence = 0.2; // size of the wavy pattern
uniform float distortion = 0.1; // how strong the wavy pattern is
uniform float ring_count_influence = 10.0; // more = more rings
uniform bool go_backwards = false; // rings go inwards
uniform float alpha_blend : hint_range(-1.0, 10.0) = 0.1;
uniform vec3 color_mix : source_color = vec3(1.0); // black = only use the 2 colors
uniform float distortion_speed = 1.0; // spin speed
uniform float ring_speed = 1.0;
uniform float final_alpha_multi : hint_range(0.1, 10.0, 0.01) = 1.0;
uniform float opacity_smoothstep_1 : hint_range(-10.0, 25.0, 0.01) = -0.25;
uniform float opacity_smoothstep_2 : hint_range(-10.0, 25.0, 0.01) = 1.5;

void fragment() {
	float time = TIME * time_scale;

	vec2 uv = (UV - vec2(0.5)) * 2.0; // -1 to 1, middle is 0
	float dist = length(uv);

	// the rings
	float opacity;
	if (go_backwards) {
		opacity = sin(dist * ring_count_influence + time * ring_speed) * 0.5 + 0.5;
	} else {
		opacity = sin(dist * ring_count_influence - time * ring_speed) * 0.5 + 0.5;
	}

	// stronger in the middle
	opacity *= smoothstep(opacity_smoothstep_1, opacity_smoothstep_2, 1.0 - dist);

	// switch between the 2 colors over time
	vec4 color = mix(primary_color, secondary_color, abs(sin(time))) * dist;

	// wavy pattern
	uv += vec2(sin(uv.y * turbulence / dist), cos(uv.x * turbulence / dist)) * distortion;

	// spin it
	float angle = time * distortion_speed;
	mat2 rotation = mat2(vec2(cos(angle), -sin(angle)), vec2(sin(angle), cos(angle)));
	vec2 rotated_uv = rotation * uv;

	vec2 distorted_uv = rotated_uv + vec2(sin(rotated_uv.y * turbulence + time), cos(rotated_uv.x * turbulence + time)) * distortion;

	vec4 final_color = mix(color, vec4(color_mix, alpha_blend), length(distorted_uv));
	final_color.a *= final_alpha_multi;
	final_color.a = clamp(final_color.a, 0.0, 1.0); // no negative alpha

	COLOR = vec4(final_color.rgb, final_color.a * opacity);
}
