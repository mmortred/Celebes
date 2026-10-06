extends Control

# Stage 5 — Character Select
# Clean 1280x720 layout using only assets already present in Celebes.

const BG = preload("res://Celebes Abyssal Tides/assets/placeholder_assets/LobbyUI.jpg")
const LOGO = preload("res://Celebes Abyssal Tides/assets/ui/celebes_logo.png")
const VAR1 = preload("res://Celebes Abyssal Tides/assets/placeholder_assets/Var1.PNG")
const VAR2 = preload("res://Celebes Abyssal Tides/assets/placeholder_assets/Var2.PNG")
const VAR3 = preload("res://Celebes Abyssal Tides/assets/placeholder_assets/Var3.PNG")
const MONSTER1 = preload("res://Celebes Abyssal Tides/assets/placeholder_assets/Monsters/GarbageMonster1.png")
const READY_SHEET = preload("res://Celebes Abyssal Tides/assets/Lobby/ReadyButton - Edited.png")
const BACK_NORMAL = preload("res://Celebes Abyssal Tides/assets/Lobby/back/343px/back01.png")
const BACK_HOVER = preload("res://Celebes Abyssal Tides/assets/Lobby/back/343px/back03.png")
const BACK_PRESSED = preload("res://Celebes Abyssal Tides/assets/Lobby/back/343px/back05.png")
const PIXEL_FONT = preload("res://Celebes Abyssal Tides/assets/font/monogram.ttf")

const SEA := Color("56dce8")
const GARBAGE := Color("a5e35f")
const GOLD := Color("d8b76a")
const PANEL_BG := Color(0.015, 0.035, 0.055, 0.94)
const CARD_BG := Color(0.025, 0.045, 0.065, 0.97)

const CHARACTERS = [
	{"name": "BUGIS", "team": "sea", "texture": VAR1},
	{"name": "BAJAU", "team": "sea", "texture": VAR2},
	{"name": "MINAHASAN", "team": "sea", "texture": VAR3},
	{"name": "PLASTIC\nHOARD", "team": "garbage", "texture": MONSTER1},
	{"name": "RUSTY\nLEVIATHAN", "team": "garbage", "texture": null},
	{"name": "TOXIC\nSLUDGE", "team": "garbage", "texture": null},
]

var selected_index := -1
var confirmed := false
var player_team := "all"
var card_panels: Array[PanelContainer] = []
var card_buttons: Array[Button] = []
var status_label: Label
var ready_button: TextureButton

func _ready() -> void:
	if NetworkManager.has_meta("character_select_team"):
		player_team = str(NetworkManager.get_meta("character_select_team"))
	_build_ui()

func _build_ui() -> void:
	# Background
	var background := TextureRect.new()
	background.texture = BG
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var shade := ColorRect.new()
	shade.color = Color(0.01, 0.015, 0.04, 0.20)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)

	# Header
	var logo := TextureRect.new()
	logo.texture = LOGO
	logo.position = Vector2(516, 18)
	logo.size = Vector2(247, 139)
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(logo)

	var title_back := PanelContainer.new()
	title_back.position = Vector2(425, 145)
	title_back.size = Vector2(430, 50)
	title_back.add_theme_stylebox_override("panel", _panel_style(Color(0.01, 0.025, 0.04, 0.95), GOLD, 2, 4))
	add_child(title_back)

	var title := _label("CHARACTER SELECT", 36, Color.WHITE)
	title.position = Vector2(425, 146)
	title.size = Vector2(430, 48)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(title)

	# Two clean team panels.
	_add_team_panel("SEA NOMADS", "sea", Vector2(55, 215), [0, 1, 2])
	_add_team_panel("GARBAGE MONSTERS", "garbage", Vector2(665, 215), [3, 4, 5])

	# Footer/status
	status_label = _label(_initial_status(), 22, Color(0.90, 0.96, 1.0))
	status_label.position = Vector2(420, 565)
	status_label.size = Vector2(440, 28)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(status_label)

	ready_button = TextureButton.new()
	ready_button.texture_normal = _atlas(READY_SHEET, Rect2(0, 0, 1032, 448))
	ready_button.texture_hover = _atlas(READY_SHEET, Rect2(1032, 0, 1032, 448))
	ready_button.texture_pressed = _atlas(READY_SHEET, Rect2(2064, 0, 1032, 448))
	# The source atlas frame is 1032x448. Scale the TextureButton itself instead
	# of letting the source texture impose its native minimum size.
	ready_button.position = Vector2(500, 602)
	ready_button.scale = Vector2(0.2713, 0.2121)
	ready_button.ignore_texture_size = false
	ready_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	ready_button.disabled = true
	ready_button.pressed.connect(_on_ready_pressed)
	add_child(ready_button)

	var back := TextureButton.new()
	back.texture_normal = BACK_NORMAL
	back.texture_hover = BACK_HOVER
	back.texture_pressed = BACK_PRESSED
	# Back artwork is 790x343; scale to a compact 230x82 footer button.
	back.position = Vector2(35, 610)
	back.scale = Vector2(0.2911, 0.2391)
	back.ignore_texture_size = false
	back.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	back.pressed.connect(_on_back_pressed)
	add_child(back)

	var hint_panel := PanelContainer.new()
	hint_panel.position = Vector2(885, 602)
	hint_panel.size = Vector2(350, 88)
	hint_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.01, 0.03, 0.05, 0.93), SEA, 2, 5))
	add_child(hint_panel)

	var hint_title := _label("CHOOSE YOUR CHARACTER", 20, SEA)
	hint_title.position = Vector2(900, 610)
	hint_title.size = Vector2(320, 24)
	add_child(hint_title)

	var hint := _label("Select a portrait, then press READY.\nLocked characters await final art.", 16, Color(0.85, 0.91, 0.94))
	hint.position = Vector2(900, 636)
	hint.size = Vector2(320, 45)
	add_child(hint)

func _add_team_panel(title_text: String, team: String, pos: Vector2, indices: Array) -> void:
	var accent: Color = SEA if team == "sea" else GARBAGE
	var panel := PanelContainer.new()
	panel.position = pos
	panel.size = Vector2(560, 330)
	panel.add_theme_stylebox_override("panel", _panel_style(PANEL_BG, accent, 2, 8))
	add_child(panel)

	var header := PanelContainer.new()
	header.position = pos + Vector2(10, 10)
	header.size = Vector2(540, 48)
	header.add_theme_stylebox_override("panel", _panel_style(Color(0.01, 0.025, 0.04, 0.98), accent, 2, 4))
	add_child(header)

	var title := _label(title_text, 28, accent)
	title.position = pos + Vector2(10, 10)
	title.size = Vector2(540, 48)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(title)

	for local_i in 3:
		_add_character_card(indices[local_i], pos + Vector2(25 + local_i * 175, 75), accent)

func _add_character_card(index: int, pos: Vector2, accent: Color) -> void:
	var data: Dictionary = CHARACTERS[index]
	var card := PanelContainer.new()
	card.position = pos
	card.size = Vector2(160, 235)
	card.add_theme_stylebox_override("panel", _panel_style(CARD_BG, GOLD, 2, 5))
	add_child(card)
	card_panels.append(card)

	var portrait_back := PanelContainer.new()
	portrait_back.position = pos + Vector2(9, 9)
	portrait_back.size = Vector2(142, 165)
	portrait_back.add_theme_stylebox_override("panel", _panel_style(Color(0.02, 0.055, 0.075, 1.0), Color(0.18, 0.27, 0.32), 1, 3))
	portrait_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(portrait_back)

	if data.texture != null:
		var portrait := TextureRect.new()
		portrait.texture = data.texture
		portrait.position = pos + Vector2(13, 13)
		portrait.size = Vector2(134, 157)
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(portrait)
	else:
		var missing := _label("?", 70, Color(0.36, 0.42, 0.48))
		missing.position = pos + Vector2(13, 22)
		missing.size = Vector2(134, 135)
		missing.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		missing.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		add_child(missing)

	var separator := ColorRect.new()
	separator.color = GOLD
	separator.position = pos + Vector2(10, 181)
	separator.size = Vector2(140, 1)
	separator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(separator)

	var name_label := _label(str(data.name), 18, Color.WHITE if data.texture != null else Color(0.60, 0.64, 0.68))
	name_label.position = pos + Vector2(5, 185)
	name_label.size = Vector2(150, 43)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(name_label)

	var button := Button.new()
	button.flat = true
	button.position = pos
	button.size = Vector2(160, 235)
	button.focus_mode = Control.FOCUS_NONE
	var allowed := data.texture != null and (player_team == "all" or player_team == str(data.team))
	button.disabled = not allowed
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if allowed else Control.CURSOR_FORBIDDEN
	button.pressed.connect(_select_character.bind(index))
	add_child(button)
	card_buttons.append(button)

func _select_character(index: int) -> void:
	if confirmed:
		return
	selected_index = index
	for i in card_panels.size():
		var data: Dictionary = CHARACTERS[i]
		var base_color: Color = SEA if str(data.team) == "sea" else GARBAGE
		var border_color := base_color if i == index else GOLD
		var width := 4 if i == index else 2
		card_panels[i].add_theme_stylebox_override("panel", _panel_style(CARD_BG, border_color, width, 5))
	status_label.text = "Selected: " + str(CHARACTERS[index].name).replace("\n", " ")
	ready_button.disabled = false

func _on_ready_pressed() -> void:
	if selected_index < 0 or confirmed:
		return
	confirmed = true
	for button in card_buttons:
		button.disabled = true
	status_label.text = "READY — " + str(CHARACTERS[selected_index].name).replace("\n", " ") + " locked in"
	NetworkManager.set_meta("selected_character", selected_index)

func _on_back_pressed() -> void:
	if confirmed:
		confirmed = false
		status_label.text = "Selection unlocked"
		_refresh_enabled_cards()
		return
	if ResourceLoader.exists("res://Celebes Abyssal Tides/scenes/ui/lobby/PvPLobby.tscn"):
		get_tree().change_scene_to_file("res://Celebes Abyssal Tides/scenes/ui/lobby/PvPLobby.tscn")

func _refresh_enabled_cards() -> void:
	for i in card_buttons.size():
		var data: Dictionary = CHARACTERS[i]
		card_buttons[i].disabled = data.texture == null or not (player_team == "all" or player_team == str(data.team))

func _initial_status() -> String:
	match player_team:
		"sea": return "SEA NOMADS — choose a character"
		"garbage": return "GARBAGE MONSTERS — choose a character"
		"spectator": return "SPECTATING — no character selection"
		_: return "Choose a character"

func _label(text_value: String, size_value: int, color_value: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_override("font", PIXEL_FONT)
	label.add_theme_font_size_override("font_size", size_value)
	label.add_theme_color_override("font_color", color_value)
	return label

func _panel_style(bg: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(width)
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	return style

func _atlas(texture: Texture2D, region: Rect2) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = region
	return atlas
