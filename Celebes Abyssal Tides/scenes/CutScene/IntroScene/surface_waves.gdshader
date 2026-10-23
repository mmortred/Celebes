shader_type canvas_item;

// rolling sea surface seen from the side: transparent above the wave line,
// water below it with a bright crest. put it on a thin ColorRect along the horizon.
uniform vec4 water_color : source_color = vec4(0.1, 0.22, 0.3, 1.0);
uniform vec4 crest_color : source_color = vec4(0.55, 0.75, 0.85, 1.0);
uniform float wave_height = 0.25; // fraction of the rect height
uniform vec2 pixel_grid = vec2(400.0, 16.0); // snap to chunky pixels

void fragment() {
	vec2 uv = floor(UV * pixel_grid) / pixel_grid;
	float w = 0.5
			+ sin(uv.x * 30.0 + TIME * 1.5) * wave_height * 0.5
			+ sin(uv.x * 71.0 - TIME * 2.3) * wave_height * 0.25;
	float below = step(w, uv.y);
	float crest = 1.0 - smoothstep(0.0, 0.15, uv.y - w);
	COLOR = mix(water_color, crest_color, crest) * vec4(1.0, 1.0, 1.0, below);
}
