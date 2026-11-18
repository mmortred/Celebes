extends Node2D

# pearl icon on the screen edge when the carrier is off screen

const EDGE_MARGIN = 20.0 # space from the screen edge

@onready var sprite = $Sprite2D

var t = 0.0


func _ready():
	visible = false


func _process(delta):
	var carrier = find_carrier()
	if carrier == null or carrier.is_multiplayer_authority():
		visible = false
		return

	# world position -> screen position
	var screen_pos = get_viewport().get_canvas_transform() * carrier.global_position
	var screen = get_viewport().get_visible_rect()
	if screen.has_point(screen_pos):
		visible = false
		return

	var inner = screen.grow(-EDGE_MARGIN)
	global_position = screen_pos.clamp(inner.position, inner.end)
	t += delta
	sprite.position.y = sin(t * 3.0) * 3.0 # bob like the pearl
	visible = true


func find_carrier():
	var pearl = get_tree().get_first_node_in_group("pearl")
	if pearl == null or pearl.carrier_name == "":
		return null
	return pearl.find_player(pearl.carrier_name)
