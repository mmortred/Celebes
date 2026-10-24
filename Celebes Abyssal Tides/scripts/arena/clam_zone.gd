extends Node2D
## The clam. Shows the pearl inside while the pearl waits at home, closes once
## someone takes it, and after a capture plays the respawn animation until the
## pearl comes back (the pearl's RETURN_DELAY matches the animation length).
## Reads the pearl's state every frame, so it agrees on every peer without rpcs.
## Works with either an AnimatedSprite2D clam, or two still Sprite2Ds named
## ClamOpen / ClamClosed (only one of them is shown at a time).

# animation names in the AnimatedSprite2D's SpriteFrames, change in the inspector if yours differ
@export var with_pearl_anim: StringName = &"pearl_available"
@export var closed_anim: StringName = &"pearl_taken"
@export var respawn_anim: StringName = &"clam_respawn" # must not loop, holds its last frame until the pearl is back

var clam: AnimatedSprite2D
var open_sprite: Sprite2D
var closed_sprite: Sprite2D
var shown_anim: StringName


func _ready() -> void:
	open_sprite = get_node_or_null("ClamOpen") as Sprite2D
	closed_sprite = get_node_or_null("ClamClosed") as Sprite2D
	clam = find_clam_sprite()
	if clam:
		for anim in [with_pearl_anim, closed_anim, respawn_anim]:
			if not clam.sprite_frames.has_animation(anim):
				push_warning("ClamZone: no animation '%s', the clam has %s" % [anim, clam.sprite_frames.get_animation_names()])
	show_anim(with_pearl_anim)


func _process(_delta: float) -> void:
	var pearl = get_tree().get_first_node_in_group("pearl")
	if pearl == null:
		return
	if pearl.respawning:
		show_anim(respawn_anim)
	elif pearl.visible and pearl.carrier_name == "" \
			and pearl.global_position.is_equal_approx(pearl.home_position):
		show_anim(with_pearl_anim)
	else:
		show_anim(closed_anim)


func show_anim(anim: StringName) -> void:
	if anim == shown_anim:
		return
	shown_anim = anim
	if clam:
		clam.play(anim)
	# still pictures: open while the pearl is home, closed otherwise (taken or respawning)
	if open_sprite:
		open_sprite.visible = anim == with_pearl_anim
	if closed_sprite:
		closed_sprite.visible = anim != with_pearl_anim


func find_clam_sprite() -> AnimatedSprite2D:
	for child in get_children():
		if child is AnimatedSprite2D:
			return child
	return null
