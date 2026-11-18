extends Node2D

# a team's well, stand in it with the pearl for 2.5 seconds to score
# getting hit starts the channel over, leaving the well or dying stops it

@export_enum("Sea Nomads", "Garbage Monsters") var team: int = 0 # GarbageMonsterDrop.tscn already sets this
@export var late = false # true = inner well, only after 5 minutes

const CHANNEL_TIME = 2.5 # same length as the channel animation

@onready var sprite = $AnimatedSprite2D
@onready var score_area = $ScoreArea
@onready var blocker_shape = $Blocker/CollisionShape2D # solid when locked
@onready var channel_player = $ChannelPlayer
@onready var channel_bar = $ChannelBar

var active = true
var channeler = null # host: the carrier standing in me
var channel_timer = 0.0


func _ready():
	add_to_group("wells")
	sprite.show_behind_parent = true # so the padlock is drawn on top
	sprite.play("well_normal_state")
	sprite.animation_finished.connect(_on_animation_finished)
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


# host only: check who is standing in the well and count the channel
func _process(delta):
	if not multiplayer.is_server():
		return
	var carrier = null
	if active:
		carrier = find_carrier()

	if carrier != channeler:
		channeler = carrier
		channel_timer = 0.0
		if carrier == null:
			channel_stopped.rpc()
		else:
			channel_started.rpc()
		return

	if channeler == null:
		return
	channel_timer += delta
	if channel_timer >= CHANNEL_TIME:
		var player = channeler
		channeler = null
		channel_stopped.rpc()
		var pearl = get_tree().get_first_node_in_group("pearl")
		if pearl:
			pearl.try_capture(player, self)


# my team's pearl carrier inside the score area, null if theres none
func find_carrier():
	for body in score_area.get_overlapping_bodies():
		if not body.is_in_group("players") or body.is_dead:
			continue
		if body.has_pearl and body.team == team:
			return body
	return null


# host: player.gd calls this when the carrier gets hit, the channel starts over
func interrupt_channel(player):
	if player != channeler:
		return
	channel_timer = 0.0
	channel_started.rpc()


# everyone sees the bar fill up over the well
@rpc("authority", "call_local", "reliable")
func channel_started():
	channel_player.stop() # so it starts from 0 again after a hit
	channel_player.play("channel")


@rpc("authority", "call_local", "reliable")
func channel_stopped():
	channel_player.stop()
	channel_bar.visible = false
