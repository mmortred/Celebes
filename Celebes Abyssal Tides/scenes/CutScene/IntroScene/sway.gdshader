shader_type canvas_item;

// sways vertices sideways, more toward the top.
// the base of the item must sit at local y = 0 (works on sprites too, set offset so the bottom is at 0)
uniform float strength = 5.0;
uniform float speed = 1.2;
uniform float height = 100.0;

void vertex() {
	float k = clamp(-VERTEX.y / height, 0.0, 1.0);
	// world x as phase so strands don't move in lockstep
	float phase = MODEL_MATRIX[3].x * 0.05;
	VERTEX.x += sin(TIME * speed + phase + k * 2.0) * strength * k * k;
}
