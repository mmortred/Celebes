@tool
extends Node2D
## soft pixel clouds drifting slowly across a band of sky (local coords).

@export var area := Rect2(-200, 0, 1040, 90):
	set(v): area = v; _scatter()
@export var count := 7:
	set(v): count = v; _scatter()
@export var cloud_seed := 5:
	set(v): cloud_seed = v; _scatter()
@export var speed := 3.0 # pixels per second
@export var light := Color(0.98, 0.99, 1.0)
@export var shade := Color(0.8, 0.88, 0.95)

var clouds: Array[Dictionary] = []


func _ready():
	_scatter()


func _scatter():
	var rng := RandomNumberGenerator.new()
	rng.seed = cloud_seed
	clouds.clear()
	for i in count:
		var puffs: Array[Vector3] = [] # x offset, y offset, radius
		var size := rng.randf_range(10.0, 22.0)
		var n := rng.randi_range(4, 7)
		for j in n:
			var k := float(j) / (n - 1) - 0.5
			puffs.append(Vector3(k * size * 3.2 + rng.randf_range(-3, 3),
				-absf(cos(k * PI)) * size * 0.5 + rng.randf_range(-2, 2),
				size * (0.45 + 0.4 * cos(k * PI)) + rng.randf_range(-1, 1)))
		clouds.append({
			"pos": Vector2(area.position.x + rng.randf() * area.size.x, area.position.y + rng.randf() * area.size.y),
			"puffs": puffs,
		})
	queue_redraw()


func _process(delta):
	if Engine.is_editor_hint():
		return
	for c in clouds:
		var p: Vector2 = c.pos + Vector2(speed * delta, 0)
		if p.x > area.end.x + 60.0:
			p.x = area.position.x - 60.0
		c.pos = p
	queue_redraw()


func _draw():
	for c in clouds:
		var base: Vector2 = c.pos.floor()
		# shaded underside first, then the lit tops slightly higher
		for p in c.puffs:
			draw_circle(base + Vector2(p.x, p.y), p.z, shade)
		for p in c.puffs:
			draw_circle(base + Vector2(p.x - 1, p.y - 2), p.z - 1.5, light)
		# flat bottom like the reference
		var w := 0.0
		for p in c.puffs:
			w = maxf(w, absf(p.x) + p.z * 0.6)
		draw_rect(Rect2(base.x - w, base.y, w * 2.0, 2), shade)
