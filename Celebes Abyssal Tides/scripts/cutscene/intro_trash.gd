@tool
extends Node2D
## placeholder trash for the intro. sits still until release() is called,
## then sinks with a side-to-side drift and slows to a stop at rest_y.
## swap _draw for a Sprite2D later.

enum Kind { BAG, BOTTLE, CAN, TIRE, SLIPPER }

@export var kind := Kind.BAG:
	set(v): kind = v; queue_redraw()
@export var velocity := Vector2(0, 22) # sink speed + sideways current
@export var drift := 10.0 # side-to-side wobble
@export var spin := 0.6 # radians per second
@export var rest_y := 330.0
@export var floating := false # bob on the sea surface instead of sinking

var active := false
var t := 0.0
var base_y := 0.0


func _ready():
	t = randf() * TAU
	base_y = position.y


func release():
	active = true


func _process(delta):
	if Engine.is_editor_hint():
		return
	if floating:
		t += delta
		position.y = base_y + sin(t * 1.5) * 2.0
		rotation = sin(t * 1.1) * 0.25
		return
	if not active:
		return
	t += delta
	# slow down as it reaches its resting depth
	var slow := clampf((rest_y - position.y) / 40.0, 0.0, 1.0)
	position += velocity * slow * delta
	position.x += sin(t * 1.4) * drift * slow * delta
	rotation += spin * slow * delta
	if kind == Kind.BAG:
		# bag "breathes" as it drifts
		scale.y = 1.0 + sin(t * 2.0) * 0.12


func _draw():
	match kind:
		Kind.BAG:
			var c := Color(0.85, 0.9, 0.95, 0.55)
			draw_colored_polygon(PackedVector2Array([
				Vector2(-7, -4), Vector2(7, -4), Vector2(9, 8), Vector2(0, 11), Vector2(-9, 8)
			]), c)
			# handles
			draw_arc(Vector2(-4, -5), 3.0, PI, TAU, 6, c, 1.0)
			draw_arc(Vector2(4, -5), 3.0, PI, TAU, 6, c, 1.0)
		Kind.BOTTLE:
			var c := Color(0.55, 0.85, 0.6, 0.7)
			draw_rect(Rect2(-3, -6, 6, 12), c)
			draw_rect(Rect2(-1.5, -10, 3, 4), c)
			draw_rect(Rect2(-1.5, -11, 3, 1), Color(0.2, 0.4, 0.9)) # cap
			draw_rect(Rect2(-3, -2, 6, 3), Color(0.9, 0.3, 0.25, 0.8)) # label
		Kind.CAN:
			draw_rect(Rect2(-3, -5, 6, 10), Color(0.8, 0.15, 0.2))
			draw_rect(Rect2(-3, -5, 6, 1), Color(0.75, 0.75, 0.8))
			draw_rect(Rect2(-3, 0, 6, 1), Color(0.95, 0.95, 0.95))
		Kind.TIRE:
			draw_arc(Vector2.ZERO, 7.0, 0.0, TAU, 16, Color(0.12, 0.12, 0.14), 4.0)
			draw_arc(Vector2.ZERO, 5.0, 0.0, TAU, 12, Color(0.22, 0.22, 0.25), 1.0)
		Kind.SLIPPER:
			draw_colored_polygon(PackedVector2Array([
				Vector2(-3, -9), Vector2(3, -9), Vector2(4, 0), Vector2(3, 9), Vector2(-3, 9), Vector2(-4, 0)
			]), Color(0.25, 0.55, 0.9))
			draw_line(Vector2(-3, -2), Vector2(0, -6), Color(0.95, 0.95, 0.95), 1.0) # strap
			draw_line(Vector2(3, -2), Vector2(0, -6), Color(0.95, 0.95, 0.95), 1.0)
