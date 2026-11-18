extends Node2D

# dash effect: squash and stretch, afterimages and bubbles

@export var ghost_count = 5 # afterimages during a dash
@export var ghost_color = Color(0.6, 0.95, 1.0, 0.6) # light blue

@onready var player = get_parent()
@onready var sprite = get_parent().get_node("AnimatedSprite2D")

var base_sprite_scale = Vector2.ONE # normal scale of the character
var squash_tween = null # so a new dash restarts it
var puff = null # the bubbles


func _ready():
	base_sprite_scale = sprite.scale
	_build_puff()


func play(direction, duration):
	_squash_and_stretch(direction)
	puff.direction = -direction # bubbles go behind you
	puff.restart()
	_spawn_ghosts(duration)


func _squash_and_stretch(direction):
	var along = Vector2(abs(direction.x), abs(direction.y)) # the axis we are moving on
	var across = Vector2(along.y, along.x)
	var squash = base_sprite_scale * (Vector2.ONE + across * 0.25 - along * 0.2) # flat first
	var stretch = base_sprite_scale * (Vector2.ONE + along * 0.35 - across * 0.15) # then long
	if squash_tween:
		squash_tween.kill()
	squash_tween = create_tween()
	squash_tween.tween_property(sprite, "scale", squash, 0.04)
	squash_tween.tween_property(sprite, "scale", stretch, 0.06)
	squash_tween.tween_property(sprite, "scale", base_sprite_scale, 0.25).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT) # wobble back


func _spawn_ghosts(duration):
	var gap = duration / ghost_count
	for i in ghost_count:
		if player.is_dead or not is_inside_tree():
			return
		# copy of the current frame that fades out
		var ghost = Sprite2D.new()
		ghost.texture = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
		ghost.texture_filter = sprite.texture_filter
		ghost.offset = sprite.offset
		ghost.global_position = sprite.global_position
		ghost.scale = sprite.global_scale
		ghost.modulate = ghost_color
		ghost.modulate.a *= player.modulate.a # hidden in kelp = hidden ghosts
		player.get_parent().add_child(ghost) # not on the player so it stays behind
		var fade = ghost.create_tween()
		fade.tween_property(ghost, "modulate:a", 0.0, 0.3)
		fade.tween_callback(ghost.queue_free)
		await get_tree().create_timer(gap).timeout


func _build_puff():
	puff = CPUParticles2D.new() # no texture = small squares, looks pixel art
	puff.emitting = false
	puff.one_shot = true
	puff.explosiveness = 1.0 # all at once
	puff.amount = 14
	puff.lifetime = 0.45
	puff.local_coords = false # bubbles stay where they spawned
	puff.position = Vector2(0, -8) # feet
	puff.spread = 55.0
	puff.gravity = Vector2(0, -40) # underwater so they go up
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
