extends Node2D

# the clam, open when the pearl is home and closed when someone has it

# animation names in the SpriteFrames
@export var with_pearl_anim = &"pearl_available"
@export var closed_anim = &"pearl_taken"
@export var respawn_anim = &"clam_respawn" # should not loop

var clam = null
var open_sprite = null
var closed_sprite = null
var shown_anim = &""


func _ready():
	open_sprite = get_node_or_null("ClamOpen")
	closed_sprite = get_node_or_null("ClamClosed")
	clam = find_clam_sprite()
	if clam:
		for anim in [with_pearl_anim, closed_anim, respawn_anim]:
			if not clam.sprite_frames.has_animation(anim):
				push_warning("ClamZone: no animation '%s', the clam has %s" % [anim, clam.sprite_frames.get_animation_names()])
	show_anim(with_pearl_anim)


func _process(_delta):
	var pearl = get_tree().get_first_node_in_group("pearl")
	if pearl == null:
		return

	var pearl_is_home = pearl.visible and pearl.carrier_name == "" and pearl.global_position.is_equal_approx(pearl.home_position)
	if pearl.respawning:
		show_anim(respawn_anim)
	elif pearl_is_home:
		show_anim(with_pearl_anim)
	else:
		show_anim(closed_anim)


func show_anim(anim):
	if anim == shown_anim:
		return
	shown_anim = anim
	if clam:
		clam.play(anim)
	# for the still pictures: open when the pearl is home, closed for everything else
	if open_sprite:
		open_sprite.visible = anim == with_pearl_anim
	if closed_sprite:
		closed_sprite.visible = anim != with_pearl_anim


func find_clam_sprite():
	for child in get_children():
		if child is AnimatedSprite2D:
			return child
	return null
