extends Node2D
## The arena border after the 5-minute mark. It starts around the whole arena,
## slowly shrinks to end_radius (the circle drawn on the map) and stays there.
## Nobody can be outside it: each peer pushes its own player back inside, the
## same way it moves it, so the push looks smooth on every screen.

@export var start_radius := 2000.0 # covers the whole arena, corners included
@export var end_radius := 1300.0 # the final circle; the outer wells end up outside it
@export var shrink_time := 60.0 # seconds to go from start to end
@export var color := Color(1.0, 0.45, 0.2)

var active := false
var radius := 0.0
var elapsed := 0.0


func _ready() -> void:
	hide()


# Called on every peer at the same moment (GameManager's sudden death rpc).
func start() -> void:
	active = true
	elapsed = 0.0
	radius = start_radius
	show()


func _process(delta: float) -> void:
	if not active:
		return
	elapsed += delta
	var progress := clampf(elapsed / shrink_time, 0.0, 1.0)
	radius = lerpf(start_radius, end_radius, smoothstep(0.0, 1.0, progress))
	queue_redraw()


func _physics_process(_delta: float) -> void:
	if not active:
		return
	for player in get_tree().get_nodes_in_group("players"):
		if not player.is_multiplayer_authority():
			continue # each owner keeps its own player inside
		var offset: Vector2 = player.global_position - global_position
		if offset.length() > radius:
			player.global_position = global_position + offset.limit_length(radius)


func _draw() -> void:
	# soft glow outside the line, then the line itself
	for i in 6:
		draw_arc(Vector2.ZERO, radius + 6.0 + i * 10.0, 0.0, TAU, 128, Color(color, 0.12 - i * 0.018), 10.0)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 128, color, 6.0)
