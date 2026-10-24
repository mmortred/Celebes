extends Node2D
## A team's scoring well. Walk in carrying the pearl to score (server checks).
## Each well belongs to a phase: "early" wells count for the first 5 minutes,
## "late" wells after the 5-minute mark (the arena switches them).
## Art: each well scene's AnimatedSprite2D has "well_normal_state" (idle) and
## "pearl_point" (plays once on a capture).

@export_enum("Sea Nomads", "Garbage Monsters") var team := 0 # GarbageMonsterDrop.tscn already sets Garbage Monsters, don't override it per instance
@export var late := false # true = only scores after the 5-minute mark (inner wells)

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var score_area: Area2D = $ScoreArea
@onready var blocker_shape: CollisionShape2D = $Blocker/CollisionShape2D # solid while locked

var active := true


func _ready() -> void:
	add_to_group("wells")
	sprite.show_behind_parent = true # so the padlock (_draw) shows on top of the well
	sprite.play("well_normal_state")
	sprite.animation_finished.connect(func(): sprite.play("well_normal_state"))
	score_area.body_entered.connect(_on_body_entered)
	set_active(not late)


# Locked wells (inner ones before 5:00, outer ones after) are solid so nobody can
# step in, dimmed, show a padlock, and don't score.
func set_active(value: bool) -> void:
	active = value
	sprite.modulate = Color.WHITE if value else Color(0.55, 0.55, 0.6, 0.6)
	blocker_shape.set_deferred("disabled", value)
	queue_redraw()


func _draw() -> void:
	if active:
		return
	# padlock floating over the well
	var top := Vector2(0, -92)
	draw_arc(top + Vector2(0, -4), 6.0, PI, TAU, 10, Color(0.85, 0.85, 0.9), 2.5)
	draw_rect(Rect2(top + Vector2(-8, -4), Vector2(16, 13)), Color(0.85, 0.85, 0.9))
	draw_rect(Rect2(top + Vector2(-1.5, 0), Vector2(3, 5)), Color(0.2, 0.2, 0.28))


func play_capture() -> void:
	sprite.play("pearl_point")


func _on_body_entered(body) -> void:
	if not multiplayer.is_server() or not active:
		return
	if not body.is_in_group("players") or body.is_dead or not body.has_pearl or body.team != team:
		return
	var pearl = get_tree().get_first_node_in_group("pearl")
	if pearl:
		pearl.try_capture(body, self)
