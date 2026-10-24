@tool
extends Node2D
## leviathan for the title: a huge shadow that swims past under the surface once.
## the head follows `route` from right to left and the body trails along the same
## path, so it slithers. drawn as a dark silhouette with soft edges; only a dim
## gold eye shows. the pass is keyed in the Intro's AnimationPlayer ("title" moves
## head_d along the route and shows/hides it), the body sway clock `t` in its AmbientPlayer.

## path the head follows, in local coords, from where it enters to where it leaves
@export var route := PackedVector2Array([
	Vector2(830, 360), Vector2(640, 325), Vector2(420, 290), Vector2(200, 312),
	Vector2(-40, 345), Vector2(-400, 320), Vector2(-900, 350), Vector2(-1500, 345),
]):
	set(v): route = v; _build_path(); queue_redraw()
@export var length := 1300.0 # head to tail tip
@export var max_width := 90.0
@export var sway := 14.0 # extra s-curve rolling down the body
@export var shadow := Color(0.0, 0.01, 0.03) # opaque; the parent CanvasGroup sets the see-through amount
@export var eye_color := Color(1.0, 0.75, 0.2)
@export var preview_at := 0.45 # how far along the pass to show in the editor

const SAMPLES := 90

var path := PackedVector2Array() # dense polyline along the route
var dist := PackedFloat32Array() # distance along the path at each point
var head_d := 0.0: # how far along the route the head is, animated
	set(v): head_d = v; queue_redraw()
var t := 0.0: # body sway clock, animated
	set(v): t = v; queue_redraw()


func _ready():
	_build_path()
	if Engine.is_editor_hint():
		head_d = _start_d() + (_end_d() - _start_d()) * preview_at
	else:
		hide()


## head starts just off screen, ends once the tail has cleared it
func _start_d() -> float:
	return 0.0


func _end_d() -> float:
	return dist[dist.size() - 1]


## catmull-rom through the route, then cumulative distances for lookups
func _build_path():
	path.clear()
	dist.clear()
	var last := route.size() - 1
	for s in last:
		var p0 := route[maxi(s - 1, 0)]
		var p1 := route[s]
		var p2 := route[s + 1]
		var p3 := route[mini(s + 2, last)]
		for j in 16:
			var u := j / 16.0
			path.append(0.5 * ((2.0 * p1) + (p2 - p0) * u
					+ (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * u * u
					+ (3.0 * p1 - p0 - 3.0 * p2 + p3) * u * u * u))
	path.append(route[last])
	var d := 0.0
	for i in path.size():
		if i > 0:
			d += path[i].distance_to(path[i - 1])
		dist.append(d)


func _at(d: float) -> Vector2:
	if d <= 0.0:
		# before the route starts: keep going straight back along the first segment
		return path[0] + (path[0] - path[1]).normalized() * -d
	var i := dist.bsearch(d)
	if i >= path.size():
		return path[path.size() - 1]
	var span := dist[i] - dist[i - 1]
	return path[i - 1].lerp(path[i], (d - dist[i - 1]) / maxf(span, 0.001))


func _width(u: float) -> float:
	if u < 0.12:
		return lerpf(max_width * 0.62, max_width, u / 0.12) # neck
	return max_width * pow(1.0 - (u - 0.12) / 0.88, 0.7) + 2.0


func _draw():
	if path.size() < 2:
		_build_path()

	# centerline from head (0) back to the tail (SAMPLES)
	var pts := PackedVector2Array()
	for i in SAMPLES + 1:
		var u := float(i) / SAMPLES
		var p := _at(head_d - length * u)
		p.y += sin(u * 7.0 - t * 1.5) * sway * u # 1.5 so the sway loops cleanly with the ambient clock
		pts.append(p)

	var left := PackedVector2Array()
	var right := PackedVector2Array()
	var ups: Array[Vector2] = []
	var tails: Array[Vector2] = []
	for i in pts.size():
		var a := pts[maxi(i - 1, 0)]
		var b := pts[mini(i + 1, SAMPLES)]
		var fwd := (a - b).normalized() # toward the head
		var up := Vector2(-fwd.y, fwd.x) if fwd.x < 0.0 else Vector2(fwd.y, -fwd.x)
		ups.append(up)
		tails.append(-fwd)
		var w := _width(float(i) / SAMPLES)
		left.append(pts[i] + up * w * 0.5)
		right.append(pts[i] - up * w * 0.5)

	var soft := Color(shadow, 0.25)

	# dorsal spines, huge on the neck, swept back
	for i in range(2, SAMPLES - 6, 3):
		var u := float(i) / SAMPLES
		var h := _width(u) * lerpf(0.75, 0.2, u)
		var base := left[i]
		var base2 := left[i + 2]
		var tip := base + ups[i] * h + tails[i] * h * 0.8
		var mid := base + ups[i] * h * 0.55 + tails[i] * h * 0.2
		draw_colored_polygon(PackedVector2Array([base, mid, tip, base2]), shadow)
	# fins under the front and middle of the body
	for u in [0.1, 0.42]:
		var i := int(u * SAMPLES)
		var f := _width(u) * 0.9
		draw_colored_polygon(PackedVector2Array([
			right[i], right[i] - ups[i] * f * 0.6 + tails[i] * f * 0.4,
			right[i] - ups[i] * f * 0.9 + tails[i] * f * 1.2, right[i + 4]]), shadow)

	# body with a soft halo so the edge melts into the water
	var rev := right.duplicate()
	rev.reverse()
	var body := left + rev
	draw_polyline(body + PackedVector2Array([body[0]]), soft, 10.0)
	draw_polyline(body + PackedVector2Array([body[0]]), Color(shadow, 0.5), 5.0)
	draw_colored_polygon(body, shadow)

	_draw_head(pts[0], -tails[0], ups[0], max_width * 0.038, soft)


## head in its own frame: x forward (snout), y up (toward the horns), scaled up
func _draw_head(base: Vector2, fwd: Vector2, up: Vector2, k: float, soft: Color):
	var poly := func(coords: Array) -> PackedVector2Array:
		var out := PackedVector2Array()
		for c in coords:
			out.append(base + fwd * c.x * k + up * c.y * k)
		return out

	var shapes := [
		poly.call([Vector2(-4, -7), Vector2(-24, -16), Vector2(-17, -7), Vector2(-26, -2), Vector2(-6, 0)]), # jaw frill
		poly.call([Vector2(14, 11), Vector2(-12, 24), Vector2(-5, 16), Vector2(6, 10)]), # back horn
		poly.call([Vector2(6, 11), Vector2(-30, 28), Vector2(-20, 18), Vector2(-2, 8)]), # main horn
		poly.call([Vector2(31, 6), Vector2(38, 15), Vector2(39, 5)]), # nose horn
		poly.call([ # skull and jaw
			Vector2(-10, 10), Vector2(0, 13), Vector2(8, 14), Vector2(14, 12), Vector2(19, 13),
			Vector2(24, 10), Vector2(31, 6), Vector2(37, 5), Vector2(41, 2), Vector2(40, -1),
			Vector2(33, -2), Vector2(36, -5), Vector2(28, -9), Vector2(14, -11), Vector2(0, -11),
			Vector2(-10, -6)]),
	]
	for s in shapes:
		draw_polyline(s + PackedVector2Array([s[0]]), soft, 8.0)
	for s in shapes:
		draw_colored_polygon(s, shadow)

	# the only colour on it: a dim gold eye and a faint glow
	var eye: PackedVector2Array = poly.call([Vector2(17, 7), Vector2(22, 9), Vector2(28, 7), Vector2(22, 5.5)])
	var center := base + fwd * 22.0 * k + up * 7.0 * k
	draw_circle(center, 3.5 * k, Color(eye_color, 0.06))
	draw_circle(center, 2.0 * k, Color(eye_color, 0.1))
	draw_colored_polygon(eye, eye_color)
	draw_line(base + fwd * 22.0 * k + up * 5.5 * k, base + fwd * 22.0 * k + up * 9.0 * k, shadow, maxf(k * 0.6, 1.0))
