extends Node2D
## The arena border after the 5-minute mark: a ring that slowly closes in on the
## centre over the sudden-death time. Players outside it keep taking damage.
## The radius comes from the match timer, so every peer draws the same ring
## without extra syncing; only the server deals the damage.

@export var start_radius := 1300.0
@export var end_radius := 450.0
@export var damage := 8.0 # per tick to anyone outside
@export var damage_interval := 1.0
@export var color := Color(1.0, 0.45, 0.2)

var active := false
var radius := 0.0
var damage_timer := 0.0


func start() -> void:
	active = true
	radius = start_radius
	show()


func _ready() -> void:
	hide()


func _process(delta: float) -> void:
	if not active:
		return
	# 1 at the start of sudden death -> 0 at the end; clients only get the timer
	# once a second, so glide toward the target instead of jumping
	var left := clampf(GameManager.time_remaining / GameManager.SUDDEN_DEATH_DURATION, 0.0, 1.0)
	var target := lerpf(end_radius, start_radius, left)
	radius = lerpf(radius, target, 1.0 - exp(-3.0 * delta))
	queue_redraw()
	if multiplayer.is_server():
		damage_timer += delta
		if damage_timer >= damage_interval:
			damage_timer = 0.0
			_hurt_players_outside()


func _hurt_players_outside() -> void:
	for player in get_tree().get_nodes_in_group("players"):
		if player.is_dead:
			continue
		if player.global_position.distance_to(global_position) > radius:
			player.receive_hit.rpc(damage, "")


func _draw() -> void:
	# soft glow outside the line, then the line itself
	for i in 6:
		draw_arc(Vector2.ZERO, radius + 6.0 + i * 10.0, 0.0, TAU, 128, Color(color, 0.12 - i * 0.018), 10.0)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 128, color, 6.0)
