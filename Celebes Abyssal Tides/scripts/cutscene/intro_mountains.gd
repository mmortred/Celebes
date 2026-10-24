@tool
extends Node2D
## pixel mountain ranges standing on the horizon (local y = 0 is the waterline).
## drawn one pixel column at a time, far range first. slopes facing the light
## (left) get the lit colour, the others the shadow colour. static, drawn once.

@export var width := 1240:
	set(v): width = v; queue_redraw()
@export var range_seed := 3:
	set(v): range_seed = v; queue_redraw()
@export var sand_color := Color(0.42, 0.26, 0.3)

# per layer: lit, shadow, height, base, feature size (px), island cut-off
const LAYERS := [
	[Color(0.3, 0.18, 0.3), Color(0.25, 0.15, 0.26), 52.0, 12.0, 70.0, 0.0],
	[Color(0.2, 0.11, 0.19), Color(0.15, 0.08, 0.14), 62.0, 0.0, 110.0, 0.22],
	[Color(0.12, 0.07, 0.12), Color(0.08, 0.05, 0.09), 34.0, 0.0, 85.0, 0.42],
]


func _hash(i: int, s: int) -> float:
	var n := (i * 374761393 + s * 668265263) & 0x7fffffff
	n = ((n ^ (n >> 13)) * 1274126177) & 0x7fffffff
	return float(n % 10000) / 10000.0


func _noise(x: float, s: int) -> float:
	var i := floori(x)
	var f := x - i
	f = f * f * (3.0 - 2.0 * f)
	return lerpf(_hash(i, s), _hash(i + 1, s), f)


## 0..1 ridge with sharpened peaks
func _ridge(x: float, s: int, feature: float) -> float:
	var h := 0.0
	var amp := 1.0
	var freq := 1.0 / feature
	var norm := 0.0
	for o in 3:
		h += _noise(x * freq, s * 31 + o) * amp
		norm += amp
		amp *= 0.35
		freq *= 2.3
	return pow(h / norm, 1.7)


func _draw():
	for li in LAYERS.size():
		var layer: Array = LAYERS[li]
		var lit: Color = layer[0]
		var shade: Color = layer[1]
		var s := range_seed * 7 + li
		var heights := PackedFloat32Array()
		var pad := 6 # look this far either side to judge the slope
		for x in width + pad * 2:
			var r := _ridge(x - pad, s, layer[4])
			# islands: drop everything under the cut-off into the sea
			r = maxf(r - layer[5], 0.0) / (1.0 - layer[5])
			heights.append(0.0 if r <= 0.0 else layer[3] + r * layer[2])
		for x in width:
			var h := floorf(heights[x + pad])
			if h < 1.0:
				continue
			var lit_side := heights[x + pad * 2] >= heights[x]
			draw_rect(Rect2(x, -h, 1, h), lit if lit_side else shade)
			# crisp highlight on the ridge line of lit slopes
			if lit_side:
				draw_rect(Rect2(x, -h, 1, 1), lit.lightened(0.15))
		if li == 1:
			# thin beach line in front of the far ranges
			draw_rect(Rect2(0, -1, width, 1), sand_color)
