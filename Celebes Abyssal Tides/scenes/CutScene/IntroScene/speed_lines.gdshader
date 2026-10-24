shader_type canvas_item;

// manga-style radial speed lines: streaks pointing at the centre, empty in the middle.
// animate `intensity` 0..1.
uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform vec4 line_color : source_color = vec4(1.0, 1.0, 1.0, 0.55);
uniform vec2 pixel_grid = vec2(320.0, 180.0);
uniform float count = 72.0; // number of angular slots
uniform float flicker = 14.0; // re-rolls per second

float hash(float n) {
	return fract(sin(n * 91.345) * 47453.5453);
}

void fragment() {
	vec2 uv = (floor(UV * pixel_grid) + 0.5) / pixel_grid;
	vec2 p = (uv - 0.5) * vec2(pixel_grid.x / pixel_grid.y, 1.0);
	float a = atan(p.y, p.x) / TAU + 0.5;
	float r = length(p);
	float slot = floor(a * count);
	float frame = floor(TIME * flicker);
	float rnd = hash(slot + frame * 13.0);
	float across = fract(a * count);
	// some slots are empty, the rest get a wedge of random thickness
	float line = step(0.6, rnd) * step(abs(across - 0.5), 0.05 + 0.15 * hash(slot * 3.1 + frame));
	// each streak starts at its own distance from the centre
	float start = 0.36 + 0.3 * hash(slot * 7.7 + frame);
	line *= smoothstep(start, start + 0.12, r);
	COLOR = vec4(line_color.rgb, line_color.a * line * intensity);
}
