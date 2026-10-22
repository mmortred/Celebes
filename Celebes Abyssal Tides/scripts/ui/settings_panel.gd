extends Control

const ACTIONS := ["move_up", "move_down", "move_left", "move_right", "dash"]
const LABELS := ["Move Up", "Move Down", "Move Left", "Move Right", "Dash"]
const SAVE_PATH := "user://keybinds.cfg"
var awaiting_action := ""
var buttons: Dictionary = {}
var notice: Label

func _ready() -> void:
	_load_bindings()
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.01, 0.04, 0.09, 0.96)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var frame := PanelContainer.new()
	frame.custom_minimum_size = Vector2(470, 0)
	center.add_child(frame)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(450, 0)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	frame.add_child(scroll)
	var panel := VBoxContainer.new()
	panel.custom_minimum_size = Vector2(420, 0)
	panel.add_theme_constant_override("separation", 12)
	scroll.add_child(panel)
	# Keep the panel within the current viewport when resized.
	frame.custom_minimum_size.y = minf(560.0, get_viewport_rect().size.y * 0.88)
	get_viewport().size_changed.connect(func() -> void:
		frame.custom_minimum_size.y = minf(560.0, get_viewport_rect().size.y * 0.88)
	)
	# Profile controls are local; the lobby synchronizes names when connected.
	var profile_title := Label.new()
	profile_title.text = "PLAYER PROFILE"
	profile_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(profile_title)
	var name_row := HBoxContainer.new()
	panel.add_child(name_row)
	var name_caption := Label.new()
	name_caption.text = "Username"
	name_caption.custom_minimum_size.x = 150
	name_row.add_child(name_caption)
	var name_input := LineEdit.new()
	name_input.custom_minimum_size.x = 230
	name_input.max_length = PlayerProfile.MAX_NAME_LENGTH
	name_input.text = PlayerProfile.username
	name_input.placeholder_text = "Enter username"
	name_row.add_child(name_input)
	name_input.text_submitted.connect(func(_value: String) -> void:
		_save_username(name_input)
	)
	var save_name := Button.new()
	save_name.text = "Save Username"
	save_name.pressed.connect(func() -> void:
		_save_username(name_input)
	)
	panel.add_child(save_name)
	var title := Label.new()
	title.text = "SETTINGS - HOTKEYS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(title)
	for i in ACTIONS.size():
		var row := HBoxContainer.new()
		panel.add_child(row)
		var label := Label.new()
		label.text = LABELS[i]
		label.custom_minimum_size.x = 150
		row.add_child(label)
		var button := Button.new()
		button.custom_minimum_size.x = 230
		button.pressed.connect(_begin_rebind.bind(ACTIONS[i]))
		row.add_child(button)
		buttons[ACTIONS[i]] = button
	notice = Label.new()
	notice.text = "Click a hotkey to change it (Ctrl/Shift/Alt supported)."
	panel.add_child(notice)
	var reset := Button.new()
	reset.text = "Reset to defaults"
	reset.pressed.connect(_reset_defaults)
	panel.add_child(reset)
	var close := Button.new()
	close.text = "Close"
	close.pressed.connect(queue_free)
	panel.add_child(close)
	_refresh()

func _begin_rebind(action: String) -> void:
	awaiting_action = action
	notice.text = "Press a key combination for " + action + " (Esc to cancel)"

func _input(event: InputEvent) -> void:
	if awaiting_action.is_empty() or not event is InputEventKey or not event.pressed or event.echo:
		return
	get_viewport().set_input_as_handled()
	if event.keycode == KEY_ESCAPE:
		awaiting_action = ""
		notice.text = "Cancelled"
		return
	if event.keycode in [KEY_SHIFT, KEY_CTRL, KEY_ALT, KEY_META]:
		return
	var key := InputEventKey.new()
	key.physical_keycode = event.physical_keycode
	key.shift_pressed = event.shift_pressed
	key.ctrl_pressed = event.ctrl_pressed
	key.alt_pressed = event.alt_pressed
	key.meta_pressed = event.meta_pressed
	InputMap.action_erase_events(awaiting_action)
	InputMap.action_add_event(awaiting_action, key)
	awaiting_action = ""
	_save_bindings()
	notice.text = "Hotkey saved"
	_refresh()

func _refresh() -> void:
	for action in ACTIONS:
		var events := InputMap.action_get_events(action)
		buttons[action].text = events[0].as_text() if not events.is_empty() else "Unassigned"

func _save_bindings() -> void:
	var config := ConfigFile.new()
	for action in ACTIONS:
		config.set_value("hotkeys", action, InputMap.action_get_events(action))
	config.save(SAVE_PATH)

func _load_bindings() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	for action in ACTIONS:
		var saved: Array = config.get_value("hotkeys", action, [])
		if not saved.is_empty():
			InputMap.action_erase_events(action)
			for event in saved:
				InputMap.action_add_event(action, event)

func _reset_defaults() -> void:
	var defaults := [KEY_W, KEY_S, KEY_A, KEY_D, KEY_SPACE]
	for i in ACTIONS.size():
		var event := InputEventKey.new()
		event.physical_keycode = defaults[i]
		InputMap.action_erase_events(ACTIONS[i])
		InputMap.action_add_event(ACTIONS[i], event)
	_save_bindings()
	notice.text = "Defaults restored"
	_refresh()

func _save_username(name_input: LineEdit) -> void:
	PlayerProfile.set_username(name_input.text)
	name_input.text = PlayerProfile.username
	notice.text = "Username saved: " + PlayerProfile.username
