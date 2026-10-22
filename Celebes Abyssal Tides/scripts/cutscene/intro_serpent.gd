@tool
extends Node2D
## sea serpent for the title screen, drawn in code (dark teal scales, pale belly
## plates, swept-back dorsal spines, horned head with a gold eye).
## holds an s-curve pose with the head raised and facing left. it only idles in
## place (breathing, slow sway, blinking); it never swims. call reveal() to fade it in.

## spine of the pose, tail -> head, in local coords. the head points along the last segment.
@export var pose := PackedVector2Array([
	Vector2(-60, 328), Vector2(20, 336), Vector2(110, 352), Vector2(200, 360),
	Vector2(290, 356), Vector2(370, 340), Vector2(440, 314), Vector2(490, 282),
	Vector2(505, 252), Vector2(490, 228), Vector2(462, 220),
]):
	set(v): pose = v; queue_redraw()
@export var max_width := 22.0
@export var twist_at := 0.68 # where the body rolls so the spines move to the outside of the neck
@export var opacity := 0.92

@export_group("Colors")
@export var scale_color := Color(0.13, 0.26, 0.3)
@export var back_color := Color(0.07, 0.15, 0.19)
@export var belly_color := Color(0.36, 0.5, 0.5)
@export var spine_color := Color(0.06, 0.12, 0.15)
@export var rim_color := Color(0.45, 0.7, 0.72, 0.7)
@export var outline_color := Color(0.02, 0.05, 0.07)
@export var eye_color := Color(1.0, 0.76, 0.2)

const STEPS := 10 # samples per pose segment

var t := 0.0
var home := Vector2.ZERO


func _ready():
	home = position
	if not Engine.is_editor_hint():
		hide()


## fade in while rising slightly out of the dark
func reveal(time := 1.5):
	show()
	modulate.a = 0.0
	position = home + Vector2(0, 12)
	var tw := create_tween().set_parallel()
	tw.tween_property(self, "modulate:a", opacity, time)
	tw.tween_property(self, "position", home, time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _process(delta):
	t += delta
	queue_redraw()


func _width(u: float) -> float:
	if u < 0.55:
		return lerpf(2.0, max_width, pow(smoothstep(0.0, 0.55, u), 0.8))
	return lerpf(max_width, max_width * 0.64, (u - 0.55) / 0.45)


## catmull-rom through the pose, with a gentle idle sway (tail moves most)
func _centerline() -> PackedVector2Array:
	var cp := pose.duplicate()
	var last := cp.size() - 1
	for i in cp.size():
		var k := 1.0 - float(i) / last
		cp[i] += Vector2(0, sin(t * 0.9 + i * 0.7) * (0.6 + k * 2.5))
	cp[last] += Vector2(0, sin(t * 1.1) * 1.5) # head bob
	var out := PackedVector2Array()
	for s in last:
		var p0 := cp[maxi(s - 1, 0)]
		var p1 := cp[s]
		var p2 := cp[s + 1]
		var p3 := cp[mini(s + 2, last)]
		for j in STEPS:
			var u := float(j) / STEPS
			out.append(0.5 * ((2.0 * p1) + (p2 - p0) * u
					+ (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * u * u
					+ (3.0 * p1 - p0 - 3.0 * p2 + p3) * u * u * u))
	out.append(cp[last])
	return out


func _draw():
	if pose.size() < 2:
		return
	var pts := _centerline()
	var n := pts.size()
	var last := n - 1

	# per-sample frame: width, side normal, which side is the back, toward-tail dir
	var w := PackedFloat32Array()
	var nb: Array[Vector2] = [] # back normal
	var tb: Array[Vector2] = [] # points toward the tail
	var fade := PackedFloat32Array() # 0 right at the twist, 1 away from it
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	for i in n:
		var u := float(i) / last
		var fwd := (pts[mini(i + 1, last)] - pts[maxi(i - 1, 0)]).normalized()
		var nl := Vector2(fwd.y, -fwd.x)
		w.append(_width(u))
		nb.append(nl if u < twist_at else -nl)
		tb.append(-fwd)
		fade.append(smoothstep(0.0, 0.06, absf(u - twist_at)))
		left.append(pts[i] + nl * w[i] * 0.5)
		right.append(pts[i] - nl * w[i] * 0.5)

	# dorsal spines behind the body, swept toward the tail, tallest on the neck
	for i in range(4, last - 2, 3):
		var u := float(i) / last
		var length := lerpf(3.0, 13.0, u) * fade[i]
		if length < 1.5 or nb[i].dot(nb[i - 2]) < 0.0:
			continue
		var edge := pts[i] + nb[i] * w[i] * 0.45
		var edge2 := pts[i - 2] + nb[i - 2] * w[i - 2] * 0.45
		var mid := edge + nb[i] * length * 0.55 + tb[i] * length * 0.15
		var tip := edge + nb[i] * length + tb[i] * length * 0.75
		draw_colored_polygon(PackedVector2Array([edge, mid, tip, edge2]), spine_color)
		draw_polyline(PackedVector2Array([edge, mid, tip]), rim_color * Color(1, 1, 1, 0.5), 1.0)

	# body
	var outline := left.duplicate()
	var rev := right.duplicate()
	rev.reverse()
	draw_colored_polygon(left + rev, scale_color)

	for i in last:
		var a := pts[i]
		var b := pts[i + 1]
		if nb[i].dot(nb[i + 1]) < 0.0:
			continue # this is the twist, the strips would cross over
		# darker back
		draw_colored_polygon(PackedVector2Array([
			a + nb[i] * w[i] * 0.5, b + nb[i + 1] * w[i + 1] * 0.5,
			b + nb[i + 1] * w[i + 1] * 0.2, a + nb[i] * w[i] * 0.2]), back_color)
		# pale belly plates on the other side
		var bw := 0.32 * fade[i]
		if bw > 0.02:
			draw_colored_polygon(PackedVector2Array([
				a - nb[i] * w[i] * 0.5, b - nb[i + 1] * w[i + 1] * 0.5,
				b - nb[i + 1] * w[i + 1] * (0.5 - bw), a - nb[i] * w[i] * (0.5 - bw)]), belly_color)
			if i % 2 == 0:
				draw_line(a - nb[i] * w[i] * 0.5, a - nb[i] * w[i] * (0.5 - bw), belly_color.darkened(0.35), 1.0)

	# scale marks: small chevrons in staggered rows
	for i in range(3, last - 2, 2):
		for row in [0.12, -0.08]:
			var c: Vector2 = pts[i] + nb[i] * w[i] * row + tb[i] * (1.5 if (i / 2) % 2 == 0 else 0.0)
			var s := clampf(w[i] * 0.08, 0.8, 1.8)
			draw_polyline(PackedVector2Array([
				c + tb[i] * s + nb[i] * s, c, c + tb[i] * s - nb[i] * s]), scale_color.lightened(0.18), 1.0)

	# rim light along the back, then the outline
	for i in last:
		if fade[i] > 0.5:
			draw_line(pts[i] + nb[i] * (w[i] * 0.5 - 1.0), pts[i + 1] + nb[i + 1] * (w[i + 1] * 0.5 - 1.0), rim_color, 1.0)
	outline.append_array(rev)
	outline.append(left[0])
	draw_polyline(outline, outline_color, 1.0)

	_draw_head(pts[last], -tb[last], nb[last])


## head in its own frame: x forward (snout), y up (toward the back/horns)
func _draw_head(base: Vector2, fwd: Vector2, up: Vector2):
	var H := func(x: float, y: float) -> Vector2: return base + fwd * x + up * y
	var poly := func(coords: Array) -> PackedVector2Array:
		var out := PackedVector2Array()
		for c in coords:
			out.append(H.call(c.x, c.y))
		return out

	# swept-back horns and jaw frill behind the skull
	var horn: PackedVector2Array = poly.call([Vector2(6, 11), Vector2(-26, 24), Vector2(-18, 17), Vector2(-2, 8)])
	var horn2: PackedVector2Array = poly.call([Vector2(14, 11), Vector2(-10, 22), Vector2(-4, 16), Vector2(6, 10)])
	var frill: PackedVector2Array = poly.call([Vector2(-4, -7), Vector2(-22, -15), Vector2(-16, -7), Vector2(-24, -2), Vector2(-6, 0)])
	for p in [frill, horn2, horn]:
		draw_colored_polygon(p, spine_color)
		draw_polyline(p + PackedVector2Array([p[0]]), outline_color, 1.0)
	draw_polyline(poly.call([Vector2(6, 11), Vector2(-26, 24)]), rim_color * Color(1, 1, 1, 0.6), 1.0)

	# skull: tall at the back, brow bump over the eye, tapering snout
	var skull: PackedVector2Array = poly.call([
		Vector2(-9, 9), Vector2(0, 12), Vector2(8, 13), Vector2(14, 11), Vector2(19, 12),
		Vector2(24, 9), Vector2(31, 6), Vector2(37, 5), Vector2(40, 2), Vector2(39, -1),
		Vector2(33, -2), Vector2(35, -5), Vector2(28, -8), Vector2(14, -10), Vector2(0, -10),
		Vector2(-9, -5)])
	draw_colored_polygon(skull, scale_color.lightened(0.08))
	# darker lower jaw
	draw_colored_polygon(poly.call([
		Vector2(-8, -3), Vector2(14, -3), Vector2(33, -2), Vector2(35, -5),
		Vector2(28, -8), Vector2(14, -10), Vector2(0, -10), Vector2(-9, -5)]), back_color)
	# upturned nose horn
	var nose: PackedVector2Array = poly.call([Vector2(31, 6), Vector2(37, 13), Vector2(38, 5)])
	draw_colored_polygon(nose, spine_color)
	draw_polyline(nose + PackedVector2Array([nose[0]]), outline_color, 1.0)
	# light along the top of the head, cheek plates, nostril
	draw_polyline(poly.call([Vector2(-6, 10), Vector2(0, 11), Vector2(8, 12), Vector2(14, 10),
			Vector2(19, 11), Vector2(24, 8), Vector2(31, 5), Vector2(37, 4)]), rim_color, 1.0)
	draw_polyline(poly.call([Vector2(5, 7), Vector2(11, 2), Vector2(9, -3)]), back_color, 1.0)
	draw_polyline(poly.call([Vector2(-3, 8), Vector2(1, 2), Vector2(-1, -4)]), back_color, 1.0)
	draw_rect(Rect2(H.call(36, 2), Vector2.ONE), outline_color)
	# mouth and teeth
	draw_polyline(poly.call([Vector2(12, -3), Vector2(24, -3), Vector2(39, -1)]), outline_color, 1.0)
	for x in [16, 21, 26, 31]:
		draw_rect(Rect2(H.call(x, -4), Vector2.ONE), Color(0.85, 0.88, 0.8))
	draw_polyline(skull + PackedVector2Array([skull[0]]), outline_color, 1.0)

	# heavy brow over a gold slit eye; blinks every few seconds
	draw_polyline(poly.call([Vector2(15, 10), Vector2(21, 11), Vector2(28, 8)]), outline_color, 1.0)
	if fmod(t, 4.3) > 0.14:
		draw_colored_polygon(poly.call([Vector2(17, 7), Vector2(22, 9), Vector2(28, 7), Vector2(22, 5)]), eye_color)
		draw_line(H.call(22, 5), H.call(22, 9), outline_color, 1.0)
		draw_rect(Rect2(H.call(24, 8), Vector2.ONE), Color(1, 1, 0.85))
	else:
		draw_line(H.call(17, 7), H.call(28, 7), outline_color, 1.0)
