extends Control

const ACTIONS := ["move_up", "move_down", "move_left", "move_right", "dash"]
const LABELS := ["Move Up", "Move Down", "Move Left", "Move Right", "Dash"]
const SAVE_PATH := "user://keybinds.cfg"
var awaiting_action := ""
var buttons: Dictionary = {}
var notice: Label

const PIXEL_FONT = preload("res://Celebes Abyssal Tides/assets/fonts/PixelifySans-VariableFont_wght.ttf")
const ACCENT := Color("#55d6ee")
var page_controls: VBoxContainer
var page_audio: VBoxContainer
var page_profile: VBoxContainer
var tab_buttons: Dictionary = {}
var current_tab := "controls"

func _style_button(button: Button) -> void:
	button.add_theme_font_override("font", PIXEL_FONT)
	button.add_theme_font_size_override("font_size", 13)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("#0b2441")
	normal.border_color = Color("#286b87")
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(3)
	var hover := normal.duplicate()
	hover.bg_color = Color("#164565")
	hover.border_color = ACCENT
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_color_override("font_color", Color("#c6f6ff"))

func _label(text_value: String, font_size: int = 13) -> Label:
	var item := Label.new()
	item.text = text_value
	item.add_theme_font_override("font", PIXEL_FONT)
	item.add_theme_font_size_override("font_size", font_size)
	item.add_theme_color_override("font_color", Color("#d3edf9"))
	return item

func _tab(key: String) -> void:
	current_tab = key
	page_controls.visible = key == "controls"
	page_audio.visible = key == "audio"
	page_profile.visible = key == "profile"
	for tab_key in tab_buttons:
		var button: Button = tab_buttons[tab_key]
		button.modulate = Color.WHITE if tab_key == key else Color(0.65, 0.82, 0.92)

func _ready() -> void:
	_load_bindings()
	var shade := ColorRect.new()
	shade.color = Color(0.006, 0.018, 0.05, 0.94)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(shade)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var frame := PanelContainer.new()
	frame.custom_minimum_size = Vector2(555, 306)
	var frame_style := StyleBoxFlat.new()
	frame_style.bg_color = Color("#071b30")
	frame_style.border_color = ACCENT
	frame_style.set_border_width_all(2)
	frame_style.set_corner_radius_all(5)
	frame.add_theme_stylebox_override("panel", frame_style)
	center.add_child(frame)
	var margins := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margins.add_theme_constant_override("margin_" + side, 13)
	frame.add_child(margins)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 9)
	margins.add_child(layout)
	var heading := _label("⚙  SETTINGS", 22)
	heading.add_theme_color_override("font_color", ACCENT)
	layout.add_child(heading)
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 15)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(body)
	var sidebar := VBoxContainer.new()
	sidebar.custom_minimum_size.x = 138
	sidebar.add_theme_constant_override("separation", 9)
	body.add_child(sidebar)
	for key in ["controls", "audio", "profile"]:
		var tab_button := Button.new()
		tab_button.text = {"controls":"⌨  CONTROLS", "audio":"♫  AUDIO", "profile":"♙  PROFILE"}[key]
		tab_button.custom_minimum_size.y = 38
		_style_button(tab_button)
		sidebar.add_child(tab_button)
		tab_button.pressed.connect(_tab.bind(key))
		tab_buttons[key] = tab_button
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(right)
	page_controls = VBoxContainer.new()
	page_controls.add_theme_constant_override("separation", 5)
	right.add_child(page_controls)
	page_controls.add_child(_label("KEY BINDINGS", 17))
	for i in ACTIONS.size():
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 7)
		page_controls.add_child(row)
		var caption := _label(LABELS[i])
		caption.custom_minimum_size.x = 130
		row.add_child(caption)
		var bind_button := Button.new()
		bind_button.custom_minimum_size = Vector2(150, 28)
		bind_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_style_button(bind_button)
		bind_button.pressed.connect(_begin_rebind.bind(ACTIONS[i]))
		row.add_child(bind_button)
		buttons[ACTIONS[i]] = bind_button
	notice = _label("Select a key to rebind. Esc cancels.", 10)
	page_controls.add_child(notice)
	var reset := Button.new()
	reset.text = "RESET TO DEFAULTS"
	_style_button(reset)
	reset.pressed.connect(_reset_defaults)
	page_controls.add_child(reset)

	page_audio = VBoxContainer.new()
	page_audio.add_theme_constant_override("separation", 15)
	right.add_child(page_audio)
	page_audio.add_child(_label("LOBBY MUSIC", 17))
	var volume_row := HBoxContainer.new()
	page_audio.add_child(volume_row)
	volume_row.add_child(_label("Music volume"))
	var volume_slider := HSlider.new()
	volume_slider.custom_minimum_size.x = 185
	volume_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	volume_slider.min_value = 0
	volume_slider.max_value = 100
	volume_slider.step = 1
	volume_slider.value = LobbyAudio.volume * 100.0
	volume_row.add_child(volume_slider)
	var volume_value := _label("%d%%" % int(volume_slider.value))
	volume_row.add_child(volume_value)
	volume_slider.value_changed.connect(func(value: float) -> void:
		LobbyAudio.set_music_volume(value / 100.0)
		volume_value.text = "%d%%" % int(value)
	)
	page_audio.add_child(_label("Changes are saved automatically.", 11))

	page_profile = VBoxContainer.new()
	page_profile.add_theme_constant_override("separation", 12)
	right.add_child(page_profile)
	page_profile.add_child(_label("PLAYER PROFILE", 17))
	page_profile.add_child(_label("Username"))
	var name_input := LineEdit.new()
	name_input.add_theme_font_override("font", PIXEL_FONT)
	name_input.max_length = PlayerProfile.MAX_NAME_LENGTH
	name_input.text = PlayerProfile.username
	name_input.placeholder_text = "Enter username"
	page_profile.add_child(name_input)
	name_input.text_submitted.connect(func(_value: String) -> void: _save_username(name_input))
	var save_name := Button.new()
	save_name.text = "SAVE USERNAME"
	_style_button(save_name)
	save_name.pressed.connect(func() -> void: _save_username(name_input))
	page_profile.add_child(save_name)

	var close := Button.new()
	close.text = "CLOSE"
	close.custom_minimum_size.y = 30
	_style_button(close)
	close.pressed.connect(queue_free)
	layout.add_child(close)
	_tab("controls")
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
