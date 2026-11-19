extends Control

# character select screen. the layout is in CharacterSelect.tscn (1280x720, scaled to the window)
# this script only changes the text, borders and what you can click

const SEA = Color("56dce8")
const GARBAGE = Color("a5e35f")
const GOLD = Color("d8b76a")
const TAKEN = Color(0.9, 0.35, 0.3)

@onready var ui_layer = $ScaledCharacterUI
@onready var status_label = $ScaledCharacterUI/StatusLabel
@onready var hint_title = $ScaledCharacterUI/HintTitle
@onready var hint = $ScaledCharacterUI/Hint
@onready var ready_button = $ScaledCharacterUI/ReadyButton
@onready var back_button = $ScaledCharacterUI/BackButton
@onready var cards = [
	$ScaledCharacterUI/BugisCard, $ScaledCharacterUI/BajauCard, $ScaledCharacterUI/MinahasanCard,
	$ScaledCharacterUI/PlasticHoardCard, $ScaledCharacterUI/RustyLeviathanCard, $ScaledCharacterUI/ToxicSludgeCard,
] # cards[i] is character id i

var selected_index = -1
var confirmed = false
var player_team = "all"
var local_peer_id = 1


func _ready():
	if NetworkManager.has_meta("character_select_team"):
		player_team = str(NetworkManager.get_meta("character_select_team"))

	if player_team == "spectator":
		hint_title.text = "SPECTATING"
		hint.text = "Spectators don't pick a character.\nYou'll watch the match and can pan around the arena."
		ready_button.visible = false # spectators dont need it
	status_label.text = _initial_status()

	for card in cards:
		card.picked.connect(_select_character)
	ready_button.pressed.connect(_on_ready_pressed)
	back_button.pressed.connect(_on_back_pressed)

	if multiplayer.multiplayer_peer != null:
		local_peer_id = multiplayer.get_unique_id()
	else:
		local_peer_id = 1

	CharacterSelectManager.state_changed.connect(_refresh_multiplayer_state)
	CharacterSelectManager.selection_rejected.connect(_on_selection_rejected)
	if multiplayer.multiplayer_peer != null:
		CharacterSelectManager.register_my_slot(int(NetworkManager.get_meta("character_select_slot", -1)))
	_refresh_multiplayer_state()
	resized.connect(_fit_ui_to_viewport)
	_fit_ui_to_viewport.call_deferred()


# scale the 1280x720 layout to the window size
func _fit_ui_to_viewport():
	if not is_instance_valid(ui_layer):
		return
	var available = size
	if available.x <= 0 or available.y <= 0:
		available = get_viewport_rect().size

	var factor = available.x / 1280.0
	if available.y / 720.0 < factor:
		factor = available.y / 720.0
	ui_layer.scale = Vector2.ONE * factor
	ui_layer.position = (available - Vector2(1280, 720) * factor) * 0.5


func _select_character(index):
	if confirmed:
		return
	if index == selected_index:
		return # already mine, clicking it again does nothing
	CharacterSelectManager.request_character(index)


func _on_ready_pressed():
	if selected_index < 0:
		return
	CharacterSelectManager.request_character_ready(true)


func _on_back_pressed():
	if confirmed:
		CharacterSelectManager.request_character_ready(false) # unready first
		return
	CharacterSelectManager.request_back_to_lobby() # everyone goes back together


# redraw all the cards
func _refresh_multiplayer_state():
	selected_index = CharacterSelectManager.selected_by(local_peer_id)
	confirmed = CharacterSelectManager.is_locked(local_peer_id)

	for card in cards:
		var i = card.character_id
		var selected_owner = CharacterSelectManager.character_owner(i)
		var owner_locked = CharacterSelectManager.is_locked(selected_owner)
		var owner_name = LobbyManager.get_player_name(selected_owner)
		var mine = selected_owner == local_peer_id
		var taken = selected_owner != 0 and not mine
		var allowed = _pickable(i) and (player_team == "all" or player_team == card.team)

		# your own card is not clickable, so clicking it twice doesnt do anything
		card.set_clickable(allowed, allowed and not taken and not confirmed and not mine)

		# text on top of the card
		if mine and owner_locked:
			card.set_owner_text("YOU ✓", SEA)
		elif mine:
			card.set_owner_text("YOU", SEA)
		elif taken and owner_locked:
			card.set_owner_text("%s ✓" % owner_name, Color(1.0, 0.55, 0.45))
		elif taken:
			card.set_owner_text("TAKEN — %s" % owner_name, Color(1.0, 0.55, 0.45))
		else:
			card.set_owner_text("", Color.WHITE)

		if mine and card.team == "sea":
			card.set_border(SEA, 4)
		elif mine:
			card.set_border(GARBAGE, 4)
		elif taken:
			card.set_border(TAKEN, 2)
		else:
			card.set_border(GOLD, 2)

	ready_button.disabled = selected_index < 0
	if confirmed:
		status_label.text = "READY — " + _card_name(selected_index) + " locked in"
	elif selected_index >= 0:
		status_label.text = "Selected: " + _card_name(selected_index)
	else:
		status_label.text = _initial_status()


func _card_name(index):
	return str(cards[index].character_name).replace("\n", " ")


func _pickable(index):
	return index in CharacterSelectManager.PLAYABLE


func _on_selection_rejected(reason):
	status_label.text = reason


func _initial_status():
	if player_team == "sea":
		return "SEA NOMADS — choose a character"
	if player_team == "garbage":
		return "GARBAGE MONSTERS — choose a character"
	if player_team == "spectator":
		return "SPECTATING — no character selection"
	return "Choose a character"
