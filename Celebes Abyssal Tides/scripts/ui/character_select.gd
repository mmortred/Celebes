extends Control

# character select screen. the layout is in CharacterSelect.tscn (1280x720, scaled to the window)
# this script only changes the text, borders and what you can click

const SEA = Color("56dce8")
const GARBAGE = Color("a5e35f")
const GOLD = Color("d8b76a")
const TAKEN = Color(0.9, 0.35, 0.3)
const CHARACTER_SCENES = preload("res://Celebes Abyssal Tides/scripts/arena/arena.gd").CHARACTER_SCENES # the same scenes the arena uses

@onready var ui_layer = $ScaledCharacterUI
@onready var status_label = $ScaledCharacterUI/StatusLabel
@onready var hint_title = $ScaledCharacterUI/HintTitle
@onready var hint = $ScaledCharacterUI/Hint
@onready var hint_panel = $ScaledCharacterUI/HintPanel
@onready var details_panel = $ScaledCharacterUI/DetailsPanel
@onready var detail_name = $ScaledCharacterUI/DetailName
@onready var detail_stats = $ScaledCharacterUI/DetailStats
@onready var skill_icons = [$ScaledCharacterUI/Skill1Icon, $ScaledCharacterUI/Skill2Icon]
@onready var skill_texts = [$ScaledCharacterUI/Skill1Text, $ScaledCharacterUI/Skill2Text]
@onready var ready_button = $ScaledCharacterUI/ReadyButton
@onready var back_button = $ScaledCharacterUI/BackButton
@onready var cards = [
	$ScaledCharacterUI/BugisCard, $ScaledCharacterUI/BajauCard, $ScaledCharacterUI/MinahasanCard,
	$ScaledCharacterUI/PlasticHoardCard, $ScaledCharacterUI/RustyLeviathanCard, $ScaledCharacterUI/ToxicSludgeCard,
] # cards[i] is character id i

var selected_index = -1
var confirmed = false
var player_team = "all"
var hovered_index = -1
var details = {} # character id -> its stats and skills (read once from the character scene)
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
		card.hovered.connect(_on_card_hovered)
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

	_show_details()
	ready_button.disabled = selected_index < 0
	if confirmed:
		status_label.text = "READY — " + _card_name(selected_index) + " locked in"
	elif selected_index >= 0:
		status_label.text = "Selected: " + _card_name(selected_index)
	else:
		status_label.text = _initial_status()


func _on_card_hovered(index):
	hovered_index = index
	_show_details()


# hover a card = its details, otherwise the one you picked, otherwise the normal hint
func _show_details():
	var index = hovered_index
	if index < 0:
		index = selected_index
	var has_details = index >= 0 and CHARACTER_SCENES.has(index)
	hint_panel.visible = not has_details
	hint_title.visible = not has_details
	hint.visible = not has_details
	details_panel.visible = has_details
	detail_name.visible = has_details
	detail_stats.visible = has_details
	for i in 2:
		skill_icons[i].visible = has_details
		skill_texts[i].visible = has_details
	if not has_details:
		return
	var info = _get_details(index)
	detail_name.text = _card_name(index)
	detail_stats.text = info.stats
	for i in 2:
		skill_icons[i].texture = info.icons[i]
		skill_texts[i].text = info.texts[i]


# the text comes from the character scene and the ability scripts
func _get_details(index):
	if details.has(index):
		return details[index]
	var player = CHARACTER_SCENES[index].instantiate() # not added to the game, we only read it
	var info = {"stats": player.get_basic_stats(), "icons": [], "texts": []}
	var keys = ["[E] ", "[R] "]
	var abilities = [player.get_node("PrimaryAbility"), player.get_node("UltAbility")]
	for i in 2:
		abilities[i]._ready() # thats where the abilities set their name and cooldown
		info.icons.append(abilities[i].get_icon())
		info.texts.append(keys[i] + abilities[i].get_info().replace("\r", ""))
	player.free()
	details[index] = info
	return info


func _card_name(index):
	return str(cards[index].character_name).replace("\r", "").replace("\n", " ")


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
