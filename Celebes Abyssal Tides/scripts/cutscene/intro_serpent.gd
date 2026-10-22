@tool
extends Node2D
## sea serpent silhouette for the intro. the head swims right and the body
## follows the same wavy path behind it, so it slithers instead of wiggling.
## hidden until appear() is called (always shown in the editor for placing).

@export var length := 560.0 # head to tail tip, in pixels
@export var thickness := 10.0
@export var speed := 12.0
@export var amplitude := 18.0 # height of the body's s-curves
@export var wavelength := 240.0
@export var undulate := 0.6 # how fast the curves roll along the body
@export var loop := true # come back from the left after leaving the screen
@export var screen_width := 640.0
@export var color := Color(0.04, 0.06, 0.12, 0.75):
	set(v): color = v; queue_redraw()
@export var eye_color := Color(0.3, 1.0, 0.8, 0.0) # alpha 0 = no glow
@export var start_x := 380.0: # head x shown in the editor
	set(v): start_x = v; head_x = v; queue_redraw()

const SEGMENTS := 48

var head_x := 380.0
var active := false
var t := 0.0


func _ready():
	head_x = start_x
	visible = Engine.is_editor_hint()


## start swimming with the head at x (local coords)
func appear(x := -20.0):
	head_x = x
	active = true
	show()


func _process(delta):
	if Engine.is_editor_hint():
		return
	if not active:
		return
	t += delta
	head_x += speed * delta
	if head_x - length > screen_width + 40.0:
		if loop:
			head_x = -40.0
		else:
			active = false
			hide()
	queue_redraw()


func _path_y(x: float) -> float:
	return sin(x * TAU / wavelength + t * undulate) * amplitude


func _draw():
	# centerline from head (0) to tail tip (SEGMENTS)
	var pts := PackedVector2Array()
	for i in SEGMENTS + 1:
		var x := head_x - length * i / SEGMENTS
		pts.append(Vector2(x, _path_y(x)))

	var left := PackedVector2Array()
	var right := PackedVector2Array()
	var ups: Array[Vector2] = []
	for i in pts.size():
		var a := pts[maxi(i - 1, 0)]
		var b := pts[mini(i + 1, pts.size() - 1)]
		var fwd := (a - b).normalized() # toward the head
		var up := Vector2(fwd.y, -fwd.x)
		ups.append(up)
		var u := float(i) / SEGMENTS
		var w := thickness * pow(1.0 - u, 0.8) + 1.0
		left.append(pts[i] + up * w * 0.5)
		right.append(pts[i] - up * w * 0.5)

	# mane near the neck, smaller ridge spikes down the back
	for i in range(2, SEGMENTS - 4, 2):
		var u := float(i) / SEGMENTS
		var spike := 9.0 if u < 0.18 else 4.0 * (1.0 - u)
		var back := (pts[i + 1] - pts[i]).normalized() * spike * 0.8
		draw_colored_polygon(PackedVector2Array([
			left[i], left[i] + ups[i] * spike + back, left[i + 1]
		]), color)

	# fins underneath
	for u in [0.15, 0.5]:
		var i := int(u * SEGMENTS)
		var back := (pts[i + 2] - pts[i]).normalized()
		draw_colored_polygon(PackedVector2Array([
			right[i], right[i] - ups[i] * 8.0 + back * 10.0, right[i + 2]
		]), color)

	right.reverse()
	draw_colored_polygon(left + right, color)

	# head: long snout, swept-back horns, in the head's own frame
	var fwd0 := (pts[0] - pts[1]).normalized()
	var up0 := Vector2(fwd0.y, -fwd0.x)
	var head := func(p: Vector2) -> Vector2: return pts[0] + fwd0 * p.x - up0 * p.y
	var head_shape := PackedVector2Array()
	for p in [Vector2(-6, -6), Vector2(4, -7), Vector2(18, -3), Vector2(20, 1),
			Vector2(14, 3), Vector2(16, 6), Vector2(4, 6), Vector2(-6, 6)]:
		head_shape.append(head.call(p))
	draw_colored_polygon(head_shape, color)
	for horn in [[Vector2(0, -6), Vector2(-16, -16), Vector2(-6, -4)],
			[Vector2(6, -6), Vector2(-6, -13), Vector2(2, -5)]]:
		draw_colored_polygon(PackedVector2Array([head.call(horn[0]), head.call(horn[1]), head.call(horn[2])]), color)
	# whisker trailing from the snout
	draw_line(head.call(Vector2(16, 3)), head.call(Vector2(2, 14 +sin(t * 2.0) * 2.0)), color, 1.0)

	if eye_color.a > 0.0:
		draw_rect(Rect2(head.call(Vector2(8, -3)), Vector2(2, 1)), eye_color)
