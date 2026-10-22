@tool
extends Node2D
## pixel-art coral for the intro seabed, drawn in code. the base sits at this node's origin.
##   BRANCH: orange branching coral with red polyp dots on the tips
##   BRAIN:  pale green mound with maze grooves
##   FINGER: chunky tan antler coral with rounded tips
##   FAN:    dark green fern-like fronds (give it the sway material to move)
##   ROCK:   dark lumpy seabed rock for the others to sit on (size = width)
## static: drawn once, redrawn only when a property changes.

enum Kind { BRANCH, BRAIN, FINGER, FAN, ROCK }

@export var kind := Kind.BRANCH:
	set(v): kind = v; queue_redraw()
@export var size := 60.0: # roughly the height in pixels (width for BRAIN)
	set(v): size = v; queue_redraw()
@export var coral_seed := 1:
	set(v): coral_seed = v; queue_redraw()
@export var flip := false: # mirror so repeated corals don't look identical
	set(v): flip = v; scale.x = -1.0 if v else 1.0


func _ready():
	scale.x = -1.0 if flip else 1.0


func _draw():
	var rng := RandomNumberGenerator.new()
	rng.seed = coral_seed
	match kind:
		Kind.BRANCH:
			_draw_branching(rng, Color(0.98, 0.76, 0.46), Color(0.86, 0.5, 0.3), 6.0, 5, true)
		Kind.FINGER:
			_draw_branching(rng, Color(0.7, 0.58, 0.54), Color(0.5, 0.4, 0.4), 10.0, 3, false)
		Kind.BRAIN:
			_draw_brain()
		Kind.FAN:
			_draw_fan(rng)
		Kind.ROCK:
			_draw_rock(rng)


## recursive branches growing upward; tips get red polyps or rounded caps
func _draw_branching(rng: RandomNumberGenerator, core: Color, shade: Color, width: float, depth: int, polyps: bool):
	var segs: Array = [] # [from, to, width]
	var tips: Array[Vector2] = []
	# short trunk, then the branches fan out wide like the reference
	_grow(Vector2.ZERO, -PI / 2.0, size * 0.2, width, depth, rng, segs, tips)
	# shadow side first, then the lit core, then a thin highlight
	for s in segs:
		draw_line(s[0] + Vector2(1, 0), s[1] + Vector2(1, 0), shade, s[2] + 1.0)
	for s in segs:
		draw_line(s[0], s[1], core, s[2])
	for s in segs:
		if s[2] >= 3.0:
			draw_line(s[0] + Vector2(-1, 0), s[1] + Vector2(-1, 0), core.lightened(0.25), 1.0)
	if polyps:
		# red polyps fringe the outer branches, thickest at the tips
		for s in segs:
			if s[2] <= 3.0:
				for i in 4:
					var along: Vector2 = s[0].lerp(s[1], rng.randf())
					var p := (along + Vector2(rng.randf_range(-3, 3), rng.randf_range(-3, 3))).floor()
					draw_rect(Rect2(p, Vector2.ONE), Color(0.78, 0.14, 0.16))
	for tip in tips:
		if polyps:
			for i in 16:
				var p := (tip + Vector2(rng.randf_range(-5, 5), rng.randf_range(-5, 4))).floor()
				draw_rect(Rect2(p, Vector2.ONE), Color(0.82, 0.16, 0.16) if i % 3 else Color(0.95, 0.35, 0.25))
		else:
			draw_circle(tip, width * 0.5, core)
			draw_rect(Rect2((tip + Vector2(-1, -width * 0.4)).floor(), Vector2(2, 1)), core.lightened(0.25))


func _grow(p: Vector2, angle: float, length: float, width: float, depth: int,
		rng: RandomNumberGenerator, segs: Array, tips: Array[Vector2]):
	var end := (p + Vector2.from_angle(angle) * length).floor()
	segs.append([p, end, width])
	if depth == 0:
		tips.append(end)
		return
	var n := 3 if rng.randf() < 0.35 else 2
	for i in n:
		var a := angle + (i - (n - 1) / 2.0) * 0.85 + rng.randf_range(-0.2, 0.2)
		a = clampf(a, -PI + 0.3, -0.3) # keep growing up, never down
		_grow(end, a, length * rng.randf_range(0.8, 1.0), maxf(width - 1.2, 1.0), depth - 1, rng, segs, tips)


## dome with wavy maze grooves, lit from the top left
func _draw_brain():
	var w := int(size)
	var h := int(size * 0.55)
	var base := Color(0.62, 0.72, 0.55)
	var groove := Color(0.36, 0.45, 0.36)
	var light := Color(0.76, 0.84, 0.66)
	var edge := Color(0.22, 0.28, 0.24)
	for y in h:
		for x in w:
			var nx := (x + 0.5 - w * 0.5) / (w * 0.5)
			var ny := (h - y - 0.5) / float(h)
			var r := nx * nx + ny * ny
			if r > 1.0:
				continue
			var c := base
			var maze := sin(x * 0.32 + 2.4 * sin(y * 0.2)) + sin(y * 0.42 + 1.8 * sin(x * 0.17))
			if absf(maze) < 0.45:
				c = groove
			elif nx < -0.1 and ny > 0.45:
				c = light
			if r > 0.86:
				c = edge
			draw_rect(Rect2(x - w / 2, y - h, 1, 1), c)


## a few curved fronds, each with leaflets on both sides
func _draw_fan(rng: RandomNumberGenerator):
	var dark := Color(0.13, 0.36, 0.28)
	var mid := Color(0.2, 0.5, 0.36)
	for f in 10:
		var angle := -PI / 2.0 + (f - 4.5) * 0.17 + rng.randf_range(-0.08, 0.08)
		var length := size * rng.randf_range(0.6, 1.0)
		var bend := rng.randf_range(-0.35, 0.35)
		var col := dark if f % 2 == 0 else mid
		var prev := Vector2.ZERO
		var steps := int(length / 2.0)
		for i in range(1, steps + 1):
			var k := float(i) / steps
			var a := angle + bend * k
			var p := (prev + Vector2.from_angle(a) * 2.0)
			draw_line(prev.floor(), p.floor(), col, 2.0 if k < 0.6 else 1.0)
			# leaflets angled up and out, shorter toward the tip
			var leaf := (1.0 - k) * 6.0 + 1.5
			draw_line(p.floor(), (p + Vector2.from_angle(a - 0.75) * leaf).floor(), col, 1.0)
			draw_line(p.floor(), (p + Vector2.from_angle(a + 0.75) * leaf).floor(), col, 1.0)
			prev = p


## lumpy dark rock: overlapping bumps with a few lit pixels on top
func _draw_rock(rng: RandomNumberGenerator):
	var body := Color(0.15, 0.1, 0.2)
	var top := Color(0.24, 0.17, 0.3)
	var bumps: Array[Vector3] = []
	var x := -size * 0.5
	while x < size * 0.5:
		var r := rng.randf_range(size * 0.08, size * 0.16)
		bumps.append(Vector3(x + r * 0.5, -r * 0.5, r))
		x += r * 0.9
	for b in bumps:
		draw_circle(Vector2(b.x, b.y), b.z, body)
	for b in bumps:
		draw_circle(Vector2(b.x - b.z * 0.25, b.y - b.z * 0.35), b.z * 0.45, top)
	draw_rect(Rect2(-size * 0.5, -4, size, 4), body)
