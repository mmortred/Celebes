extends CanvasLayer

# scoreboard in the arena, TAB opens and closes it. spectators can open it too

const PIXEL_FONT = preload("res://Celebes Abyssal Tides/assets/fonts/PixelifySans-VariableFont_wght.ttf")

var panel = null
var rows = null
var confirmation = null
var result = null
var shown = false


func _ready():
	layer = 15 # on top of the hud

	var root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(center)

	panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(470, 290)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var style = StyleBoxFlat.new()
	style.bg_color = Color("#061522")
	style.border_color = Color("#49c8dc")
	style.set_border_width_all(2)
	style.set_corner_radius_all(5)
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)

	var column = VBoxContainer.new()
	column.add_theme_constant_override("separation", 7)
	margin.add_child(column)
	column.add_child(_make_label("CELEBES  /  MATCH SCOREBOARD", 18, Color("#88eff8")))

	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size.y = 198
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(scroll)
	rows = VBoxContainer.new()
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows.add_theme_constant_override("separation", 3)
	scroll.add_child(rows)

	var footer = HBoxContainer.new()
	column.add_child(footer)
	var hint = _make_label("TAB  -  CLOSE", 11)
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(hint)
	var exit = Button.new()
	exit.text = "LEAVE MATCH"
	_font(exit, 12)
	exit.pressed.connect(_ask_leave)
	footer.add_child(exit)
	panel.visible = false

	confirmation = ConfirmationDialog.new()
	confirmation.title = "Leave match?"
	confirmation.dialog_text = "Leave this match? If you are the host, the match ends for everyone."
	confirmation.confirmed.connect(_leave)
	add_child(confirmation)

	# shows who won when the match ends
	result = _make_label("", 16, Color("#a1effa"))
	result.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	result.position = Vector2(80, 120)
	result.size = Vector2(480, 95)
	result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result.visible = false
	root.add_child(result)

	ScoreboardManager.scoreboard_changed.connect(_refresh)
	ScoreboardManager.match_result_changed.connect(_result)
	_refresh()


func _font(control, size = 12):
	control.add_theme_font_override("font", PIXEL_FONT)
	control.add_theme_font_size_override("font_size", size)


func _make_label(value, size = 12, tint = Color("#d4f3fa")):
	var label = Label.new()
	label.text = value
	_font(label, size)
	label.add_theme_color_override("font_color", tint)
	label.clip_text = true
	return label


func _unhandled_input(event):
	if not event is InputEventKey:
		return
	if event.keycode != KEY_TAB or not event.pressed or event.echo:
		return
	if confirmation.visible:
		return
	shown = not shown
	panel.visible = shown
	if shown:
		_refresh()
	get_viewport().set_input_as_handled()


# remake all the rows
func _refresh():
	if rows == null:
		return
	for child in rows.get_children():
		rows.remove_child(child)
		child.queue_free()

	for team in [0, 1]:
		if team == 0:
			rows.add_child(_make_label("SEA NOMADS", 15, Color("#6bdce9")))
		else:
			rows.add_child(_make_label("GARBAGE MONSTERS", 15, Color("#b1e97c")))
		rows.add_child(_make_label("PLAYER                                 K    D    A", 11))

		for peer_id in ScoreboardManager.records:
			var data = ScoreboardManager.records[peer_id]
			if int(data.get("team", 2)) != team:
				continue
			var line = HBoxContainer.new()
			rows.add_child(line)

			var player_name = str(data.get("name", "Player")).substr(0, 22)
			if int(peer_id) == multiplayer.get_unique_id():
				player_name += " *" # me
			var player = _make_label(player_name, 12)
			player.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			line.add_child(player)

			for key in ["kills", "deaths", "assists"]:
				var value = _make_label(str(int(data.get(key, 0))), 12)
				value.custom_minimum_size.x = 36
				value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				line.add_child(value)

	var spectators = 0
	for slot in LobbyManager.slots:
		if int(slot.get("peer_id", 0)) > 0 and int(slot.get("team_id", -1)) == 2:
			spectators += 1
	rows.add_child(_make_label("SPECTATORS: %d" % spectators, 11, Color("#a0b5c5")))


func _ask_leave():
	confirmation.popup_centered()
	panel.visible = true


func _leave():
	ScoreboardManager.request_leave()


func _result(message):
	panel.visible = false
	shown = false
	result.text = message + "\nReturning to menu..."
	result.visible = true
