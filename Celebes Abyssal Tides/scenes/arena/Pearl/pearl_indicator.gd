extends Node2D
## Off-screen pearl marker. Lives in the HUD, so it is drawn in screen space.
## When someone carries the pearl and they are outside my camera, the pearl icon
## sits on the screen edge on their side. Hidden while the carrier is on screen
## (their head icon already shows it) and when I am the carrier.

const EDGE_MARGIN = 20.0 # px kept between the icon and the screen edge

@onready var sprite: Sprite2D = $Sprite2D

var t := 0.0


func _ready() -> void:
	visible = false


func _process(delta: float) -> void:
	var carrier = find_carrier()
	if carrier == null or carrier.is_multiplayer_authority():
		visible = false
		return
	# world -> screen, through my player's camera
	var screen_pos: Vector2 = get_viewport().get_canvas_transform() * carrier.global_position
	var screen := get_viewport().get_visible_rect()
	if screen.has_point(screen_pos):
		visible = false
		return
	var inner := screen.grow(-EDGE_MARGIN)
	global_position = screen_pos.clamp(inner.position, inner.end)
	t += delta
	sprite.position.y = sin(t * 3.0) * 3.0 # same bob as the pearl on the ground
	visible = true


func find_carrier() -> Node:
	var pearl = get_tree().get_first_node_in_group("pearl")
	if pearl == null or pearl.carrier_name == "":
		return null
	return pearl.find_player(pearl.carrier_name)
