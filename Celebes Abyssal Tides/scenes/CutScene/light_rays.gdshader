shader_type canvas_item;
render_mode blend_add;

// soft slanted light shafts that fade toward the bottom
uniform vec4 ray_color : source_color = vec4(0.6, 0.5, 1.0, 0.08);
uniform float speed = 0.15;

void fragment() {
	float x = UV.x + UV.y * 0.25;
	float rays = sin(x * 22.0 + TIME * speed * 3.0) * sin(x * 13.0 - TIME * speed * 2.0);
	rays = smoothstep(0.3, 1.0, rays);
	float fade = 1.0 - UV.y;
	COLOR = vec4(ray_color.rgb, ray_color.a * rays * fade);
}
