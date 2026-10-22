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
	var dark := body_color.darkened(0.45)

	# body: rounder at the head, tapering toward the tail
	var body := PackedVector2Array()
	for i in 20:
		var a := TAU * i / 20.0
		body.append(Vector2(cos(a) * l * 0.5, sin(a) * h * 0.5 * (0.75 - 0.25 * cos(a))))

	# forked tail
	var wig := sin(t * 8.0) * h * 0.15
	var tail_len := l * 0.35
	var tail := PackedVector2Array([
		Vector2(l * 0.4, 0),
		Vector2(l * 0.5 + tail_len, -h * 0.7 + wig),
		Vector2(l * 0.5 + tail_len * 0.65, wig * 0.5),
		Vector2(l * 0.5 + tail_len, h * 0.7 + wig),
	])

	draw_colored_polygon(tail, body_color.darkened(0.15))
	draw_colored_polygon(body, body_color)
	# gill line and eye
	draw_line(Vector2(-l * 0.18, -h * 0.28), Vector2(-l * 0.12, h * 0.28), dark, 1.0)
	draw_rect(Rect2(-l * 0.34, -h * 0.15, 2, 2), Color("1a0f2e"))
