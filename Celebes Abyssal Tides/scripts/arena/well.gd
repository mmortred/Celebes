extends Node2D

# a team's well, walk in with the pearl to score

@export_enum("Sea Nomads", "Garbage Monsters") var team: int = 0 # GarbageMonsterDrop.tscn already sets this
@export var late = false # true = inner well, only after 5 minutes

@onready var sprite = $AnimatedSprite2D
@onready var score_area = $ScoreArea
@onready var blocker_shape = $Blocker/CollisionShape2D # solid when locked

var active = true


func _ready():
	add_to_group("wells")
	sprite.show_behind_parent = true # so the padlock is drawn on top
	sprite.play("well_normal_state")
	sprite.animation_finished.connect(_on_animation_finished)
	score_area.body_entered.connect(_on_body_entered)
	set_active(not late)


func _on_animation_finished():
	sprite.play("well_normal_state") # back to normal after pearl_point


# locked wells are solid, darker, have a padlock and dont score
func set_active(value):
	active = value
	if value:
		sprite.modulate = Color.WHITE
	else:
		sprite.modulate = Color(0.55, 0.55, 0.6, 0.6)
	blocker_shape.set_deferred("disabled", value)
	queue_redraw()


func _draw():
	if active:
		return
	# padlock on top of the well
	var top = Vector2(0, -92)
	draw_arc(top + Vector2(0, -4), 6.0, PI, TAU, 10, Color(0.85, 0.85, 0.9), 2.5)
	draw_rect(Rect2(top + Vector2(-8, -4), Vector2(16, 13)), Color(0.85, 0.85, 0.9))
	draw_rect(Rect2(top + Vector2(-1.5, 0), Vector2(3, 5)), Color(0.2, 0.2, 0.28))


func play_capture():
	sprite.play("pearl_point")


func _on_body_entered(body):
	if not multiplayer.is_server() or not active:
		return
	if not body.is_in_group("players") or body.is_dead:
		return
	if not body.has_pearl or body.team != team:
		return
	var pearl = get_tree().get_first_node_in_group("pearl")
	if pearl:
		pearl.try_capture(body, self)
