shader_type canvas_item;

// kelp moving in the water: wind wiggle + side to side sway, only the top part moves

uniform float margin_scale : hint_range(1.0, 4.0) = 1.0; // makes the sprite bigger so the kelp doesnt get cut off

uniform float wind_strength = 1.0;
uniform float wind_scale = 10.0;
uniform float wind_speed = 0.1;
uniform float wind_height_start : hint_range(0.0, 1.0) = 0.0;

uniform float sway_strength : hint_range(0.0, 10.0) = 0.5;
uniform float sway_speed = 0.5;
uniform float sway_height_start : hint_range(0.0, 1.0) = 0.0;

// random direction for each grid point
vec2 random(vec2 uv) {
	uv = vec2(dot(uv, vec2(127.1, 311.7)), dot(uv, vec2(269.5, 183.3)));
	return -1.0 + 2.0 * fract(sin(uv) * 43758.5453123);
}

// smooth noise, around 0 to 1
float noise(vec2 uv) {
	vec2 cell = floor(uv);
	vec2 inside = fract(uv);
	vec2 blur = smoothstep(0.0, 1.0, inside);

	float bottom = mix(dot(random(cell + vec2(0.0, 0.0)), inside - vec2(0.0, 0.0)),
			dot(random(cell + vec2(1.0, 0.0)), inside - vec2(1.0, 0.0)), blur.x);
	float top = mix(dot(random(cell + vec2(0.0, 1.0)), inside - vec2(0.0, 1.0)),
			dot(random(cell + vec2(1.0, 1.0)), inside - vec2(1.0, 1.0)), blur.x);
	return mix(bottom, top, blur.y) + 0.5;
}

void vertex() {
	VERTEX *= margin_scale;
}

void fragment() {
	vec2 region_size_px = REGION_RECT.zw / TEXTURE_PIXEL_SIZE;

	// uv inside this tile only (0 to 1)
	vec2 local_uv = (UV - REGION_RECT.xy) / REGION_RECT.zw;
	local_uv = (local_uv - 0.5) * margin_scale + 0.5;

	// snap to the pixels so it stays pixel art
	vec2 pixel_uv = floor(local_uv * region_size_px) / region_size_px;

	// wind wiggle, only above wind_height_start
	float wind_offset = noise(pixel_uv * wind_scale + TIME * wind_speed) * 2.0 - 1.0;
	wind_offset *= step(pixel_uv.y, 1.0 - wind_height_start);
	wind_offset /= region_size_px.x; // same strength for big and small tiles

	// sway, stronger at the top
	float sway_offset = max(0.0, 1.0 - pixel_uv.y - sway_height_start) * sin(TIME * sway_speed);

	pixel_uv.x += sway_offset * sway_strength + wind_offset * wind_strength;

	// back to the real uv, and dont go outside the tile
	vec2 final_uv = pixel_uv * REGION_RECT.zw + REGION_RECT.xy;
	final_uv = clamp(final_uv, REGION_RECT.xy, REGION_RECT.xy + REGION_RECT.zw);

	COLOR = texture(TEXTURE, final_uv);
}
