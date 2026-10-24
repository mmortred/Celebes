shader_type canvas_item;

uniform float margin_scale: hint_range(1.0, 4.0) = 1.0;

group_uniforms wind;
uniform float wind_strength = 1.0;
uniform float wind_scale = 10.0;
uniform float wind_speed = 0.1;
uniform float wind_height_start: hint_range(0, 1) = 0.;

group_uniforms sway;
uniform float sway_strength: hint_range(0, 10) = 0.5;
uniform float sway_speed = 0.5;
uniform float sway_height_start: hint_range(0, 1) = 0.;
group_uniforms;


// simple 2D noise (could also be replaced with a texture for more control)
vec2 random(vec2 uv) {
    uv = vec2(dot(uv, vec2(127.1,311.7)), dot(uv, vec2(269.5,183.3)));
    return -1.0 + 2.0 * fract(sin(uv) * 43758.5453123);
}

float noise(vec2 uv) {
    vec2 uv_index = floor(uv);
    vec2 uv_fract = fract(uv);

    vec2 blur = smoothstep(0.0, 1.0, uv_fract);

    return mix( mix(dot( random(uv_index + vec2(0.0,0.0) ), uv_fract - vec2(0.0,0.0) ),
                    dot( random(uv_index + vec2(1.0,0.0) ), uv_fract - vec2(1.0,0.0) ), blur.x),
                mix(dot( random(uv_index + vec2(0.0,1.0) ), uv_fract - vec2(0.0,1.0) ),
                    dot( random(uv_index + vec2(1.0,1.0) ), uv_fract - vec2(1.0,1.0) ), blur.x), blur.y) + 0.5;
}

void vertex() {
	VERTEX *= margin_scale;
}

void fragment() {
	vec2 region_size_px = REGION_RECT.zw / TEXTURE_PIXEL_SIZE;

	// convert altas UV in region space uv
	vec2 local_uv = (UV - REGION_RECT.xy) / REGION_RECT.zw;
	local_uv = (local_uv-0.5) * margin_scale + 0.5;
	
	vec2 pixelated_local_uv = floor(local_uv * region_size_px) / region_size_px;
	
	float wind_offset = noise(pixelated_local_uv * wind_scale + TIME*wind_speed)*2.0-1.0;
	// vertical mask to apply wind_noise only to the top part of the texture
	wind_offset *= step(pixelated_local_uv.y, 1.- wind_height_start);
	// divide wind offset by region width in pixels to normalize it, so that the wind effect is consistent across different region sizes
	wind_offset /= region_size_px.x;

	// sway offset applied from height_start to the top of the texture
	float sway_offset = max(0., (1.0 - pixelated_local_uv.y - sway_height_start))*sin(TIME*sway_speed);

	pixelated_local_uv.x += sway_offset * sway_strength + wind_offset * wind_strength;
	
	// convert back to transformed altas space UV coordinates
	vec2 transformed_uv = pixelated_local_uv * REGION_RECT.zw + REGION_RECT.xy;
	
	// then clamp to the region rect to avoid sampling outside the texture region
	transformed_uv = clamp(transformed_uv, REGION_RECT.xy, REGION_RECT.xy + REGION_RECT.zw);
	
	COLOR = texture(TEXTURE, transformed_uv);
}