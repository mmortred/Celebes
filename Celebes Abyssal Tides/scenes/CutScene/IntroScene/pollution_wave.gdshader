shader_type canvas_item;

// murky pollution that wipes in from the right with a jagged, churning front.
// animate `progress` from 0 (clean) to 1 (whole screen polluted).
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec4 murk_color : source_color = vec4(0.3, 0.12, 0.08, 0.4);
uniform vec4 edge_color : source_color = vec4(0.4, 0.1, 0.08, 0.9);
uniform float edge_width = 0.08;
uniform vec2 pixel_grid = vec2(320.0, 180.0); // snap to chunky pixels

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

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		v += a * noise(p);
		p *= 2.0;
		a *= 0.5;
	}
	return v;
}

void fragment() {
	vec2 uv = floor(UV * pixel_grid) / pixel_grid;

	// front line: noisy + a zigzag like the storyboard sketch
	float n = fbm(vec2(uv.y * 6.0, TIME * 0.3));
	float zig = abs(fract(uv.y * 8.0 + TIME * 0.2) - 0.5) * 0.06;
	float front = 1.0 - progress * (1.0 + edge_width * 2.0) + (n - 0.5) * 0.15 + zig;
	float d = uv.x - front; // > 0 means inside the pollution

	float inside = smoothstep(0.0, edge_width, d);
	float swirl = fbm(uv * vec2(5.0, 3.0) + vec2(TIME * 0.05, TIME * 0.08));

	vec4 col = mix(edge_color, murk_color, inside);
	col.rgb *= 0.8 + 0.4 * swirl;
	col.a *= step(0.0, d) * (0.7 + 0.3 * swirl);
	COLOR = col;
}
