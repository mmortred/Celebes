extends Control

# Stage 5 — Character Select
# Clean 1280x720 layout using only assets already present in Celebes.

const SEA_BACKGROUND = preload("res://Celebes Abyssal Tides/scenes/ui/SeaBackground.tscn") # the intro's sunset sea
# Portraits are zoomed-in crops of each character's first walk-down frame.
const SEA_NOMAD_WALK = preload("res://Celebes Abyssal Tides/assets/sprite/SeaNomad1/walk down_spear.png")
const SLUDGE_WALK = preload("res://Celebes Abyssal Tides/assets/sprite/GMonster3/monster/sludge walk_down.png")
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

# sheet + face = the crop used as the portrait. sheet null = not made yet, shows "?".
const CHARACTERS = [
	{"name": "BUGIS", "team": "sea", "sheet": SEA_NOMAD_WALK, "face": Rect2(20, 12, 24, 24)},
	{"name": "BAJAU", "team": "sea", "sheet": null},
	{"name": "MINAHASAN", "team": "sea", "sheet": null},
	{"name": "PLASTIC\nHOARD", "team": "garbage", "sheet": null},
	{"name": "RUSTY\nLEVIATHAN", "team": "garbage", "sheet": null},
	{"name": "TOXIC\nSLUDGE", "team": "garbage", "sheet": SLUDGE_WALK, "face": Rect2(10, 2, 44, 44)},
]

var selected_index := -1
var confirmed := false
var player_team := "all"
var card_panels: Array[PanelContainer] = []
var card_buttons: Array[Button] = []
var status_label: Label
var ready_button: TextureButton
var owner_labels: Array[Label] = []
var local_peer_id := 1
var ui_layer: Control

func _ready() -> void:
	if NetworkManager.has_meta("character_select_team"):
		player_team = str(NetworkManager.get_meta("character_select_team"))
	_build_ui()
	local_peer_id = multiplayer.get_unique_id() if multiplayer.multiplayer_peer != null else 1
	CharacterSelectManager.state_changed.connect(_refresh_multiplayer_state)
	CharacterSelectManager.selection_rejected.connect(_on_selection_rejected)
	if multiplayer.multiplayer_peer != null:
		CharacterSelectManager.register_my_slot(int(NetworkManager.get_meta("character_select_slot", -1)))
	_refresh_multiplayer_state()
	resized.connect(_fit_ui_to_viewport)
	_fit_ui_to_viewport.call_deferred()

func _build_ui() -> void:
	ui_layer = Control.new()
	ui_layer.name = "ScaledCharacterUI"
	ui_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ui_layer)
	# Background
	var background: Control = SEA_BACKGROUND.instantiate()
	add_child(background)

	var shade := ColorRect.new()
	shade.color = Color(0.01, 0.015, 0.04, 0.20)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)

	# Header — logo intentionally removed for a cleaner Stage 5 layout.
	var title_back := PanelContainer.new()
	title_back.position = Vector2(425, 35)
	title_back.size = Vector2(430, 54)
	title_back.add_theme_stylebox_override("panel", _panel_style(Color(0.01, 0.025, 0.04, 0.95), GOLD, 2, 4))
	add_child(title_back)

	var title := _label("CHARACTER SELECT", 36, Color.WHITE)
	title.position = Vector2(425, 36)
	title.size = Vector2(430, 52)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(title)

	# Two clean team panels moved upward now that the logo is gone.
	_add_team_panel("SEA NOMADS", "sea", Vector2(55, 110), [0, 1, 2])
	_add_team_panel("GARBAGE MONSTERS", "garbage", Vector2(665, 110), [3, 4, 5])

	# Selection/status line above the footer.
	status_label = _label(_initial_status(), 22, Color(0.90, 0.96, 1.0))
	status_label.position = Vector2(390, 462)
	status_label.size = Vector2(500, 28)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(status_label)

	# Bottom row: BACK | character info | READY.
	# Keep the large source textures scaled down so they never overflow the footer.
	var back := TextureButton.new()
	back.texture_normal = BACK_NORMAL
	back.texture_hover = BACK_HOVER
	back.texture_pressed = BACK_PRESSED
	back.position = Vector2(95, 560)
	back.scale = Vector2(0.2911, 0.2391)
	back.ignore_texture_size = false
	back.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	back.pressed.connect(_on_back_pressed)
	add_child(back)

	var hint_panel := PanelContainer.new()
	hint_panel.position = Vector2(390, 525)
	hint_panel.size = Vector2(500, 125)
	hint_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.01, 0.03, 0.05, 0.95), SEA, 2, 6))
	add_child(hint_panel)

	var spectating := player_team == "spectator"
	var hint_title := _label("SPECTATING" if spectating else "CHOOSE YOUR CHARACTER", 24, SEA)
	hint_title.position = Vector2(410, 540)
	hint_title.size = Vector2(460, 30)
	hint_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(hint_title)

	var hint_text := "Spectators don't pick a character.\nYou'll watch the match and can pan around the arena." if spectating \
			else "Select a portrait, then press READY.\nOther players' picks appear on their character cards."
	var hint := _label(hint_text, 17, Color(0.85, 0.91, 0.94))
	hint.position = Vector2(415, 580)
	hint.size = Vector2(450, 52)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(hint)

	ready_button = TextureButton.new()
	ready_button.texture_normal = _atlas(READY_SHEET, Rect2(0, 0, 1032, 448))
	ready_button.texture_hover = _atlas(READY_SHEET, Rect2(1032, 0, 1032, 448))
	ready_button.texture_pressed = _atlas(READY_SHEET, Rect2(2064, 0, 1032, 448))
	ready_button.position = Vector2(960, 555)
	ready_button.scale = Vector2(0.2713, 0.2121)
	ready_button.ignore_texture_size = false
	ready_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	ready_button.disabled = true
	ready_button.visible = not spectating # nothing to lock in when spectating
	ready_button.pressed.connect(_on_ready_pressed)
	add_child(ready_button)
	for child in get_children():
		if child != ui_layer and child != background and child != shade:
			child.reparent(ui_layer, false)
	move_child(ui_layer, get_child_count() - 1)

func _fit_ui_to_viewport() -> void:
	if not is_instance_valid(ui_layer):
		return
	var available := size
	if available.x <= 0 or available.y <= 0:
		available = get_viewport_rect().size
	var factor: float = minf(available.x / 1280.0, available.y / 720.0)
	ui_layer.scale = Vector2.ONE * factor
	ui_layer.position = (available - Vector2(1280, 720) * factor) * 0.5

func _add_team_panel(title_text: String, team: String, pos: Vector2, indices: Array) -> void:
	var accent: Color = SEA if team == "sea" else GARBAGE
	var panel := PanelContainer.new()
	panel.position = pos
	panel.size = Vector2(560, 330)
	panel.add_theme_stylebox_override("panel", _panel_style(PANEL_BG, accent, 2, 8))
	ui_layer.add_child(panel)

	var header := PanelContainer.new()
	header.position = pos + Vector2(10, 10)
	header.size = Vector2(540, 48)
	header.add_theme_stylebox_override("panel", _panel_style(Color(0.01, 0.025, 0.04, 0.98), accent, 2, 4))
	ui_layer.add_child(header)

	var title := _label(title_text, 28, accent)
	title.position = pos + Vector2(10, 10)
	title.size = Vector2(540, 48)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ui_layer.add_child(title)

	for local_i in 3:
		_add_character_card(indices[local_i], pos + Vector2(25 + local_i * 175, 75), accent)

func _add_character_card(index: int, pos: Vector2, accent: Color) -> void:
	var data: Dictionary = CHARACTERS[index]
	var card := PanelContainer.new()
	card.position = pos
	card.size = Vector2(160, 235)
	card.add_theme_stylebox_override("panel", _panel_style(CARD_BG, GOLD, 2, 5))
	ui_layer.add_child(card)
	card_panels.append(card)

	var portrait_back := PanelContainer.new()
	portrait_back.position = pos + Vector2(9, 9)
	portrait_back.size = Vector2(142, 165)
	portrait_back.add_theme_stylebox_override("panel", _panel_style(Color(0.02, 0.055, 0.075, 1.0), Color(0.18, 0.27, 0.32), 1, 3))
	portrait_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(portrait_back)

	if _has_art(index):
		var portrait := TextureRect.new()
		portrait.texture = _atlas(data.sheet, data.face)
		portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST # keep the pixels crisp when zoomed
		portrait.position = pos + Vector2(13, 13)
		portrait.size = Vector2(134, 157)
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ui_layer.add_child(portrait)
	else:
		var missing := _label("?", 70, Color(0.36, 0.42, 0.48))
		missing.position = pos + Vector2(13, 22)
		missing.size = Vector2(134, 135)
		missing.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		missing.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		ui_layer.add_child(missing)

	var separator := ColorRect.new()
	separator.color = GOLD
	separator.position = pos + Vector2(10, 181)
	separator.size = Vector2(140, 1)
	separator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(separator)

	var name_label := _label(str(data.name), 18, Color.WHITE if _has_art(index) else Color(0.60, 0.64, 0.68))
	name_label.position = pos + Vector2(5, 185)
	name_label.size = Vector2(150, 43)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ui_layer.add_child(name_label)

	var owner_label := _label("", 14, SEA)
	owner_label.position = pos + Vector2(8, 8)
	owner_label.size = Vector2(144, 22)
	owner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	owner_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(owner_label)
	owner_labels.append(owner_label)

	var button := Button.new()
	button.flat = true
	button.position = pos
	button.size = Vector2(160, 235)
	button.focus_mode = Control.FOCUS_NONE
	var allowed := _has_art(index) and (player_team == "all" or player_team == str(data.team))
	button.disabled = not allowed
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if allowed else Control.CURSOR_FORBIDDEN
	button.pressed.connect(_select_character.bind(index))
	ui_layer.add_child(button)
	card_buttons.append(button)

func _select_character(index: int) -> void:
	if confirmed:
		return
	CharacterSelectManager.request_character(index)

func _on_ready_pressed() -> void:
	if selected_index < 0:
		return
	CharacterSelectManager.request_character_ready(true)

func _on_back_pressed() -> void:
	if confirmed:
		CharacterSelectManager.request_character_ready(false)
		return
	if ResourceLoader.exists("res://Celebes Abyssal Tides/scenes/ui/lobby/PvPLobby.tscn"):
		get_tree().change_scene_to_file("res://Celebes Abyssal Tides/scenes/ui/lobby/PvPLobby.tscn")

func _refresh_multiplayer_state() -> void:
	selected_index = CharacterSelectManager.selected_by(local_peer_id)
	confirmed = CharacterSelectManager.is_locked(local_peer_id)
	for i in card_buttons.size():
		var data: Dictionary = CHARACTERS[i]
		var selected_owner := CharacterSelectManager.character_owner(i)
		var mine := selected_owner == local_peer_id
		var taken := selected_owner != 0 and not mine
		var team_ok := player_team == "all" or player_team == str(data.team)
		card_buttons[i].disabled = not _has_art(i) or not team_ok or taken or confirmed
		var owner_name := LobbyManager.get_player_name(selected_owner)
		owner_labels[i].text = ("YOU ✓" if CharacterSelectManager.is_locked(selected_owner) else "YOU") if mine else (("%s ✓" % owner_name) if taken and CharacterSelectManager.is_locked(selected_owner) else ("TAKEN — %s" % owner_name if taken else ""))
		owner_labels[i].modulate = SEA if mine else Color(1.0, 0.55, 0.45)
		var base_color: Color = SEA if str(data.team) == "sea" else GARBAGE
		var border_color := base_color if mine else (Color(0.9, 0.35, 0.3) if taken else GOLD)
		var width := 4 if mine else 2
		card_panels[i].add_theme_stylebox_override("panel", _panel_style(CARD_BG, border_color, width, 5))
	ready_button.disabled = selected_index < 0
	if confirmed:
		status_label.text = "READY — " + str(CHARACTERS[selected_index].name).replace("\n", " ") + " locked in"
	elif selected_index >= 0:
		status_label.text = "Selected: " + str(CHARACTERS[selected_index].name).replace("\n", " ")
	else:
		status_label.text = _initial_status()

func _has_art(index: int) -> bool:
	return CHARACTERS[index].get("sheet") != null


func _on_selection_rejected(reason: String) -> void:
	status_label.text = reason

func _refresh_enabled_cards() -> void:
	_refresh_multiplayer_state()

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
