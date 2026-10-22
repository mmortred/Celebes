shader_type canvas_item;

// open sea seen toward the horizon: rows squash with distance, the pixel water
// texture rides on it, and white wave streaks roll in. top of the rect = horizon.
// with foam_only on it draws just the white caps (to layer over things under the water).
uniform sampler2D water : repeat_enable, filter_nearest;
uniform vec2 rect_size = vec2(1040.0, 187.0);
uniform vec4 far_color : source_color = vec4(0.5, 0.28, 0.4, 1.0);
uniform vec4 mid_color : source_color = vec4(0.2, 0.14, 0.3, 1.0);
uniform vec4 near_color : source_color = vec4(0.08, 0.12, 0.24, 1.0);
uniform vec4 foam_color : source_color = vec4(0.88, 0.62, 0.66, 1.0);
uniform float texture_amount = 0.45;
uniform float wave_density = 0.3; // 0..1, more white caps
uniform float speed = 1.0;
uniform bool foam_only = false;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
			mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

void fragment() {
	vec2 px = floor(UV * rect_size);
	float y = (px.y + 0.5) / rect_size.y; // 0 at the horizon, 1 right in front
	float depth = 1.0 / (y + 0.06);
	// position on the water plane; waves roll toward the viewer
	vec2 w = vec2((px.x - rect_size.x * 0.5) / rect_size.y * depth, depth * 2.0);
	w.y -= TIME * 0.35 * speed;

	// banded colour from hazy far water to deep teal up close
	float yb = floor(y * 14.0) / 14.0;
	vec3 base = yb < 0.35 ? mix(far_color.rgb, mid_color.rgb, yb / 0.35)
			: mix(mid_color.rgb, near_color.rgb, (yb - 0.35) / 0.65);

	// the pixel water texture, laid on the plane
	vec3 tex = texture(water, w * vec2(0.9, 0.45)).rgb;
	float lum = dot(tex, vec3(0.333));
	base *= mix(1.0, 0.55 + lum * 1.1, texture_amount * smoothstep(0.08, 0.5, y));

	// white caps: thin wavy streaks, with a darker trough just behind each one
	vec2 q = vec2(w.x * 6.0 + sin(w.y * 1.3) * 0.8, w.y * 9.0);
	float th = mix(0.8, 0.74, y) + (1.0 - wave_density) * 0.12;
	float near_fade = smoothstep(0.06, 0.3, y);
	float crest = step(th, noise(q)) * near_fade;
	float trough = step(th, noise(q + vec2(0.0, 0.6))) * (1.0 - crest) * near_fade;
	// far glints flicker near the horizon
	float glint = step(0.99, hash(px + floor(TIME * 5.0))) * pow(1.0 - y, 4.0);

	float foam = max(crest * mix(0.35, 0.7, y), glint * 0.7);
	if (foam_only) {
		COLOR = vec4(foam_color.rgb, foam);
	} else {
		vec3 col = mix(base, base * 0.78, trough * 0.6);
		col = mix(col, foam_color.rgb, foam);
		COLOR = vec4(col, 1.0);
	}
}
