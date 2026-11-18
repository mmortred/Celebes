extends Camera2D

# camera for spectators (WASD or drag to move, wheel to zoom, V hides the hud)

@export var pan_speed = 260.0 # pixels per second at zoom 1
@export var min_zoom = 0.5
@export var max_zoom = 2.0

var bounds = Rect2() # stay inside this, empty = no limit
var dragging = false
var hud_hidden = false
var spectating_layer = null


func _ready():
	# V should be in the input map already, this is just in case its missing
	if not InputMap.has_action("toggle_hud"):
		var key = InputEventKey.new()
		key.physical_keycode = KEY_V
		InputMap.add_action("toggle_hud")
		InputMap.action_add_event("toggle_hud", key)
	make_current()
	_add_spectating_label()


func _process(delta):
	var dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	dir += Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	position += dir.limit_length(1.0) * pan_speed * delta / zoom.x
	_keep_in_bounds()


func _unhandled_input(event):
	if event.is_action_pressed("toggle_hud") and not event.is_echo():
		toggle_hud()
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT or event.button_index == MOUSE_BUTTON_MIDDLE:
			dragging = event.pressed
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom = (zoom * 1.1).clampf(min_zoom, max_zoom)
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom = (zoom / 1.1).clampf(min_zoom, max_zoom)
	elif event is InputEventMouseMotion and dragging:
		position -= event.relative / zoom
		_keep_in_bounds()


func toggle_hud():
	hud_hidden = not hud_hidden
	var hud_layer = get_parent().get_node_or_null("CanvasLayer")
	if hud_layer is CanvasLayer:
		hud_layer.visible = not hud_hidden
	if spectating_layer:
		spectating_layer.visible = not hud_hidden


func _keep_in_bounds():
	if bounds.size == Vector2.ZERO:
		return
	var half_view = get_viewport_rect().size / zoom * 0.5
	var min_pos = bounds.position + half_view
	var max_pos = bounds.end - half_view

	# if the arena is smaller than the screen just center it
	if min_pos.x > max_pos.x:
		position.x = bounds.get_center().x
	else:
		position.x = clampf(position.x, min_pos.x, max_pos.x)
	if min_pos.y > max_pos.y:
		position.y = bounds.get_center().y
	else:
		position.y = clampf(position.y, min_pos.y, max_pos.y)


func _add_spectating_label():
	var layer = CanvasLayer.new()
	layer.layer = 20
	add_child(layer)
	spectating_layer = layer

	var label = Label.new()
	label.text = "SPECTATING  -  WASD / drag to look around, wheel to zoom, V to hide HUD"
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 3)
	label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	label.offset_top = -22
	label.offset_bottom = -6
	label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layer.add_child(label)
