extends Camera2D
## free camera for spectators: they have no player, they can only look around.
## pan with WASD / arrow keys or drag with the right or middle mouse button,
## mouse wheel zooms. the view is kept inside `bounds` when it is set.

@export var pan_speed := 260.0 # pixels per second at zoom 1
@export var min_zoom := 0.5
@export var max_zoom := 2.0
var bounds := Rect2() # world rect to stay inside; empty = no limit
var dragging := false


func _ready() -> void:
	make_current()
	_add_spectating_label()


func _process(delta: float) -> void:
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	dir += Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	position += dir.limit_length(1.0) * pan_speed * delta / zoom.x
	_keep_in_bounds()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT or event.button_index == MOUSE_BUTTON_MIDDLE:
			dragging = event.pressed
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom = (zoom * 1.1).clampf(min_zoom, max_zoom)
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom = (zoom / 1.1).clampf(min_zoom, max_zoom)
	elif event is InputEventMouseMotion and dragging:
		position -= event.relative / zoom
		_keep_in_bounds()


func _keep_in_bounds() -> void:
	if bounds.size == Vector2.ZERO:
		return
	var half_view := get_viewport_rect().size / zoom * 0.5
	var min_pos := bounds.position + half_view
	var max_pos := bounds.end - half_view
	# arena smaller than the view on an axis: just centre on it
	position.x = bounds.get_center().x if min_pos.x > max_pos.x else clampf(position.x, min_pos.x, max_pos.x)
	position.y = bounds.get_center().y if min_pos.y > max_pos.y else clampf(position.y, min_pos.y, max_pos.y)


func _add_spectating_label() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 20
	add_child(layer)
	var label := Label.new()
	label.text = "SPECTATING  -  WASD / drag to look around, wheel to zoom"
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 3)
	label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	label.offset_top = -22
	label.offset_bottom = -6
	label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layer.add_child(label)
