extends Node2D
## Launch effect with no art needed: squash/stretch, afterimages and a bubble puff, all made in code.
## The player's play_launch_fx rpc calls play() on every peer.

@export var ghost_count = 5 # afterimages left behind during a dash
@export var ghost_color = Color(0.6, 0.95, 1.0, 0.6) # watery cyan tint

@onready var player = get_parent()
@onready var sprite: AnimatedSprite2D = get_parent().get_node("AnimatedSprite2D")

var base_sprite_scale = Vector2.ONE # each character's normal scale, squash/stretch returns to this
var squash_tween = null # so a new dash restarts the squash instead of stacking
var puff: CPUParticles2D = null # bubble burst, built in code


func _ready():
	base_sprite_scale = sprite.scale
	_build_puff()


func play(direction: Vector2, duration: float):
	_squash_and_stretch(direction)
	puff.direction = -direction # bubbles burst out behind you
	puff.restart()
	_spawn_ghosts(duration)


func _squash_and_stretch(direction: Vector2):
	var along = Vector2(abs(direction.x), abs(direction.y)) # which axis we're travelling on
	var across = Vector2(along.y, along.x)
	var squash = base_sprite_scale * (Vector2.ONE + across * 0.25 - along * 0.2) # wind-up: flatten against the push
	var stretch = base_sprite_scale * (Vector2.ONE + along * 0.35 - across * 0.15) # launch: long in the travel direction
	if squash_tween:
		squash_tween.kill()
	squash_tween = create_tween()
	squash_tween.tween_property(sprite, "scale", squash, 0.04)
	squash_tween.tween_property(sprite, "scale", stretch, 0.06)
	squash_tween.tween_property(sprite, "scale", base_sprite_scale, 0.25).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT) # wobble back


func _spawn_ghosts(duration: float):
	var gap = duration / ghost_count # spread the ghosts across the dash
	for i in ghost_count:
		if player.is_dead or not is_inside_tree():
			return
		var ghost = Sprite2D.new() # a frozen copy of the current frame
		ghost.texture = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
		ghost.texture_filter = sprite.texture_filter # keep pixel art crisp
		ghost.offset = sprite.offset
		ghost.global_position = sprite.global_position
		ghost.scale = sprite.global_scale
		ghost.modulate = ghost_color
		ghost.modulate.a *= player.modulate.a # hidden in kelp = hidden ghosts too
		player.get_parent().add_child(ghost) # add to Players, not the player, so it stays behind
		var fade = ghost.create_tween()
		fade.tween_property(ghost, "modulate:a", 0.0, 0.3)
		fade.tween_callback(ghost.queue_free)
		await get_tree().create_timer(gap).timeout


func _build_puff():
	puff = CPUParticles2D.new() # no texture = little squares, fits the pixel art
	puff.emitting = false
	puff.one_shot = true
	puff.explosiveness = 1.0 # all at once
	puff.amount = 14
	puff.lifetime = 0.45
	puff.local_coords = false # bubbles stay where they spawned instead of following the player
	puff.position = Vector2(0, -8) # at the feet
	puff.spread = 55.0
	puff.gravity = Vector2(0, -40) # underwater: drift up
	puff.initial_velocity_min = 50.0
	puff.initial_velocity_max = 120.0
	puff.damping_min = 80.0
	puff.damping_max = 120.0
	puff.scale_amount_min = 2.0
	puff.scale_amount_max = 4.0
	var ramp = Gradient.new()
	ramp.set_color(0, Color(0.85, 1.0, 1.0, 0.9))
	ramp.set_color(1, Color(0.4, 0.8, 1.0, 0.0)) # fade out
	puff.color_ramp = ramp
	add_child(puff)
