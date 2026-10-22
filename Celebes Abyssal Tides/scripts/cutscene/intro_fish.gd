@tool
extends Node2D
## placeholder fish for the intro (almond body + forked tail, head on the left).
## swims sideways, bobs, and wraps around the screen. swap _draw for a Sprite2D later.

@export var swim_speed := 14.0
@export var facing_left := true:
	set(v): facing_left = v; scale.x = 1.0 if v else -1.0
@export var body_size := Vector2(28, 12): # length, height
	set(v): body_size = v; queue_redraw()
@export var body_color := Color("f2a541"):
	set(v): body_color = v; queue_redraw()
@export var bob_amount := 3.0
@export var screen_width := 640.0

var base_y := 0.0
var t := 0.0
var wraps := true # false once fleeing, so it leaves for good


func _ready():
	base_y = position.y
	t = randf() * TAU
	scale.x = 1.0 if facing_left else -1.0


func _process(delta):
	t += delta
	queue_redraw() # tail wiggle
	if Engine.is_editor_hint():
		return
	var dir := -1.0 if facing_left else 1.0
	position.x += dir * swim_speed * delta
	position.y = base_y + sin(t * 1.3) * bob_amount
	# wrap to the other side once fully off screen
	var margin := body_size.x * 2.0
	if not wraps:
		if position.x < -margin or position.x > screen_width + margin:
			hide()
			set_process(false)
	elif facing_left and position.x < -margin:
		position.x = screen_width + margin
	elif not facing_left and position.x > screen_width + margin:
		position.x = -margin


## turn left (away from the pollution) and dart off screen
func flee(speed := 90.0):
	facing_left = true
	wraps = false
	create_tween().tween_property(self, "swim_speed", speed, 1.2).set_ease(Tween.EASE_IN)


func _draw():
	var l := body_size.x
	var h := body_size.y
	var outline := body_color.darkened(0.7)
	var fin := body_color.darkened(0.2)
	var detailed := l >= 20.0 # tiny background fish stay simple

	# body: rounder at the head, tapering toward the tail
	var body := PackedVector2Array()
	var back := PackedVector2Array()
	var belly := PackedVector2Array()
	for i in 20:
		var a := TAU * i / 20.0
		var p := Vector2(cos(a) * l * 0.5, sin(a) * h * 0.5 * (0.75 - 0.25 * cos(a)))
		body.append(p)
		if sin(a) <= 0.0:
			back.append(Vector2(p.x * 0.9, p.y * 0.85 - h * 0.02))
		if sin(a) >= 0.0:
			belly.append(Vector2(p.x * 0.85, p.y * 0.7 + h * 0.08))

	# forked tail and fins, flicking with the swim
	var wig := sin(t * 8.0) * h * 0.15
	var tail_len := l * 0.35
	var tail := PackedVector2Array([
		Vector2(l * 0.4, 0),
		Vector2(l * 0.5 + tail_len, -h * 0.7 + wig),
		Vector2(l * 0.5 + tail_len * 0.65, wig * 0.5),
		Vector2(l * 0.5 + tail_len, h * 0.7 + wig),
	])
	var dorsal := PackedVector2Array([Vector2(-l * 0.12, -h * 0.36), Vector2(l * 0.1, -h * 0.75), Vector2(l * 0.28, -h * 0.28)])
	var pelvic := PackedVector2Array([Vector2(-l * 0.02, h * 0.3), Vector2(l * 0.1, h * 0.62 + wig * 0.3), Vector2(l * 0.16, h * 0.28)])

	for p in [tail, dorsal, pelvic]:
		draw_colored_polygon(p, fin)
		if detailed:
			draw_polyline(p + PackedVector2Array([p[0]]), outline, 1.0)
	if detailed:
		# fin rays
		draw_line(Vector2(l * 0.5, 0), Vector2(l * 0.5 + tail_len * 0.9, -h * 0.5 + wig), outline, 1.0)
		draw_line(Vector2(l * 0.5, 0), Vector2(l * 0.5 + tail_len * 0.9, h * 0.5 + wig), outline, 1.0)

	draw_colored_polygon(body, body_color)
	if not detailed:
		draw_rect(Rect2(-l * 0.34, -h * 0.15, 1, 1), outline)
		return
	draw_colored_polygon(back, body_color.darkened(0.15))
	draw_colored_polygon(belly, body_color.lightened(0.35))
	# scale dots in two staggered rows
	for i in 5:
		var x := -l * 0.05 + i * l * 0.07
		draw_rect(Rect2(x, -h * 0.12, 1, 1), body_color.darkened(0.3))
		draw_rect(Rect2(x + l * 0.035, h * 0.06, 1, 1), body_color.darkened(0.2))
	# gill arc, side fin, eye with a catchlight
	draw_polyline(PackedVector2Array([Vector2(-l * 0.16, -h * 0.3), Vector2(-l * 0.2, 0), Vector2(-l * 0.16, h * 0.3)]), outline, 1.0)
	draw_colored_polygon(PackedVector2Array([Vector2(-l * 0.12, h * 0.02), Vector2(l * 0.02, h * 0.12 + wig * 0.4), Vector2(-l * 0.06, h * 0.18)]), fin)
	draw_polyline(body + PackedVector2Array([body[0]]), outline, 1.0)
	draw_rect(Rect2(-l * 0.37, -h * 0.2, 3, 3), Color(0.95, 0.95, 0.9))
	draw_rect(Rect2(-l * 0.37, -h * 0.2 + 1, 2, 2), Color("1a0f2e"))
