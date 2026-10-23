@tool
extends Node2D
## placeholder trash for the intro. sits still until release() is called,
## then sinks with a side-to-side drift and slows to a stop at rest_y.
## release() can also give it a push (the pollution wave carrying it) that fades out.
## swap _draw for a Sprite2D later.

enum Kind { BAG, BOTTLE, CAN, TIRE, SLIPPER }

@export var kind := Kind.BAG:
	set(v): kind = v; queue_redraw()
@export var velocity := Vector2(0, 22) # sink speed + sideways current
@export var drift := 10.0 # side-to-side wobble
@export var spin := 0.6 # radians per second
@export var rest_y := 330.0
@export var floating := false # bob on the sea surface instead of sinking
@export var carry_drag := 1.1 # how fast the wave's push dies away

var active := false
var t := 0.0
var base_y := 0.0
var base_scale := Vector2.ONE
var carry := Vector2.ZERO # push from the wave, fades out


func _ready():
	t = randf() * TAU
	base_y = position.y
	base_scale = scale


func release(push := Vector2.ZERO):
	active = true
	carry = push
	show()


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
	position += (velocity * slow + carry) * delta
	position.x += sin(t * 1.4) * drift * slow * delta
	carry = carry.lerp(Vector2.ZERO, 1.0 - exp(-carry_drag * delta))
	rotation += spin * maxf(slow, carry.length() / 200.0) * delta # tumbles while carried
	if kind == Kind.BAG:
		# bag "breathes" as it drifts
		scale.y = base_scale.y * (1.0 + sin(t * 2.0) * 0.12)


const OUTLINE := Color(0.06, 0.05, 0.1, 0.9)


## filled shape with a dark outline
func _shape(points: PackedVector2Array, fill: Color):
	draw_colored_polygon(points, fill)
	draw_polyline(points + PackedVector2Array([points[0]]), OUTLINE, 1.0)


func _draw():
	match kind:
		Kind.BAG:
			var c := Color(0.85, 0.9, 0.95, 0.6)
			# handles behind the bag
			draw_arc(Vector2(-4, -5), 3.0, PI, TAU, 6, OUTLINE, 2.0)
			draw_arc(Vector2(4, -5), 3.0, PI, TAU, 6, OUTLINE, 2.0)
			draw_arc(Vector2(-4, -5), 3.0, PI, TAU, 6, c, 1.0)
			draw_arc(Vector2(4, -5), 3.0, PI, TAU, 6, c, 1.0)
			_shape(PackedVector2Array([
				Vector2(-7, -4), Vector2(-2, -3), Vector2(2, -4), Vector2(7, -4), Vector2(9, 8),
				Vector2(4, 10), Vector2(0, 11), Vector2(-5, 9), Vector2(-9, 8)
			]), c)
			# wrinkles and a printed logo
			draw_line(Vector2(-4, -2), Vector2(-5, 7), Color(0.6, 0.65, 0.75, 0.6), 1.0)
			draw_line(Vector2(3, -2), Vector2(5, 8), Color(0.6, 0.65, 0.75, 0.6), 1.0)
			draw_rect(Rect2(-2, 2, 3, 3), Color(0.9, 0.35, 0.3, 0.7))
		Kind.BOTTLE:
			var c := Color(0.55, 0.85, 0.6, 0.75)
			_shape(PackedVector2Array([
				Vector2(-1.5, -10), Vector2(1.5, -10), Vector2(1.5, -7), Vector2(3, -5),
				Vector2(3, 6), Vector2(-3, 6), Vector2(-3, -5), Vector2(-1.5, -7)
			]), c)
			draw_rect(Rect2(-1.5, -11, 3, 1), Color(0.2, 0.4, 0.9)) # cap
			draw_rect(Rect2(-3, -2, 6, 3), Color(0.9, 0.3, 0.25, 0.85)) # label
			draw_line(Vector2(-1.5, -4), Vector2(-1.5, 4), Color(0.9, 1.0, 0.9, 0.7), 1.0) # shine
		Kind.CAN:
			_shape(PackedVector2Array([Vector2(-3, -5), Vector2(3, -5), Vector2(3, 5), Vector2(-3, 5)]), Color(0.8, 0.15, 0.2))
			draw_rect(Rect2(-3, -5, 6, 1), Color(0.75, 0.75, 0.8))
			draw_rect(Rect2(-3, 0, 6, 1), Color(0.95, 0.95, 0.95))
			draw_line(Vector2(-1.5, -3), Vector2(-1.5, 3), Color(1, 0.6, 0.6), 1.0) # shine
		Kind.TIRE:
			draw_arc(Vector2.ZERO, 7.0, 0.0, TAU, 20, OUTLINE, 6.0)
			draw_arc(Vector2.ZERO, 7.0, 0.0, TAU, 20, Color(0.14, 0.14, 0.17), 4.0)
			# tread marks and a dull rim highlight
			for i in 10:
				var a := TAU * i / 10.0
				draw_line(Vector2.from_angle(a) * 5.5, Vector2.from_angle(a) * 8.5, Color(0.08, 0.08, 0.1), 1.0)
			draw_arc(Vector2.ZERO, 6.0, PI * 1.1, PI * 1.6, 6, Color(0.35, 0.35, 0.4), 1.0)
		Kind.SLIPPER:
			_shape(PackedVector2Array([
				Vector2(-3, -9), Vector2(3, -9), Vector2(4, -4), Vector2(3, 1), Vector2(4, 6),
				Vector2(3, 9), Vector2(-3, 9), Vector2(-4, 6), Vector2(-3, 1), Vector2(-4, -4)
			]), Color(0.25, 0.55, 0.9))
			draw_line(Vector2(-3, 7), Vector2(3, 7), Color(0.15, 0.35, 0.65), 1.0) # heel
			draw_line(Vector2(-3, -2), Vector2(0, -6), Color(0.95, 0.95, 0.95), 1.0) # strap
			draw_line(Vector2(3, -2), Vector2(0, -6), Color(0.95, 0.95, 0.95), 1.0)
