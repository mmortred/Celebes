@tool
extends Node2D
## twinkling pixel stars scattered in a rect (local coords).

@export var area := Rect2(0, 0, 640, 120):
	set(v): area = v; _scatter()
@export var count := 40:
	set(v): count = v; _scatter()
@export var star_seed := 7:
	set(v): star_seed = v; _scatter()
@export var color := Color(0.9, 0.9, 1.0, 0.8)

var stars: Array[Vector3] = [] # x, y, twinkle phase
var t := 0.0


func _ready():
	_scatter()


func _scatter():
	var rng := RandomNumberGenerator.new()
	rng.seed = star_seed
	stars.clear()
	for i in count:
		stars.append(Vector3(
			area.position.x + rng.randf() * area.size.x,
			area.position.y + rng.randf() * area.size.y,
			rng.randf() * TAU))
	queue_redraw()


func _process(delta):
	t += delta
	queue_redraw()


func _draw():
	for s in stars:
		var c := color
		c.a *= 0.4 + 0.6 * (0.5 + 0.5 * sin(t * 2.0 + s.z))
		draw_rect(Rect2(floorf(s.x), floorf(s.y), 1, 1), c)
