extends Control

const WINNER_KEY_DELAY = 1.5 # wait a bit before a key counts so your last attack click doesnt skip it
const KILL_SHOW_TIME = 5.0 # how long a kill stays in the kill feed

@onready var timer_label = $ScoreboardNode/Label
@onready var hp_bar = $PlayerStats/TextureProgressBar
@onready var hp_label = $PlayerStats/TextureProgressBar/Label
@onready var player_name_label = $PlayerStats/PlayerPortrait/PlayerNameLabel
@onready var nomads_score = $ScoreboardNode/NomadsContainer/TeamScoreLabel
@onready var monsters_score = $ScoreboardNode/MonstersContainer/TeamScoreLabel
@onready var respawn_label = $RespawnLabel
@onready var tuna_rush_label = $PlayerStats/TunaRushLabel
@onready var pearl_label = $KillFeed/PearlLabel
@onready var kill_lines = [$KillFeed/KillLine1, $KillFeed/KillLine2] # line 1 is the newest
@onready var primary_slot = $PlayerStats/AbilityContainerHBox/PrimarySlot # E
@onready var ultimate_slot = $PlayerStats/AbilityContainerHBox/UltimateSlot # R

var my_player = null # set in set_player
var kill_timers = [0.0, 0.0] # time left for each kill line
var alert_label = null # the pearl taken / dropped / captured text
var alert_tween = null
var waiting_for_key = false # winner screen, any key goes back to the lobby


func _ready():
	add_to_group("hud") # player.gd finds the hud with this
	GameManager.time_updated.connect(_on_time_updated)
	GameManager.serpent_rising_started.connect(_on_serpent_rising_started)
	GameManager.match_ended.connect(_on_match_ended)
	GameManager.score_changed.connect(_on_score_changed)
	GameManager.announcement.connect(show_alert)
	GameManager.match_won.connect(show_winner)
	ScoreboardManager.kill_happened.connect(add_kill)
	_on_score_changed(GameManager.team_scores) # show the real scores
	_make_alert_label()
	initialize_hud()


# kill feed, pearl, respawn countdown and tuna rush time
func _process(delta):
	update_kill_feed(delta)
	update_pearl_label()

	if my_player == null or not is_instance_valid(my_player):
		respawn_label.visible = false
		tuna_rush_label.visible = false
		return

	if my_player.is_dead and my_player.respawn_timer > 0:
		respawn_label.visible = true
		respawn_label.text = "RESPAWN IN %d" % ceil(my_player.respawn_timer)
	else:
		respawn_label.visible = false

	if my_player.tuna_rush_timer > 0:
		tuna_rush_label.visible = true
		tuna_rush_label.text = "TUNA RUSH %d" % ceil(my_player.tuna_rush_timer)
	else:
		tuna_rush_label.visible = false


# new kill goes on line 1, the old line 1 moves down to line 2
func add_kill(killer_name, victim_name, killer_team):
	kill_lines[1].text = kill_lines[0].text
	kill_lines[1].modulate = kill_lines[0].modulate
	kill_timers[1] = kill_timers[0]

	if killer_name == "":
		kill_lines[0].text = "%s was defeated" % victim_name
	else:
		kill_lines[0].text = "%s defeated %s" % [killer_name, victim_name]
	kill_lines[0].modulate = GameManager.TEAM_COLORS.get(killer_team, Color.WHITE)
	kill_timers[0] = KILL_SHOW_TIME


# each line hides by itself after a few seconds
func update_kill_feed(delta):
	for i in kill_lines.size():
		if kill_timers[i] > 0:
			kill_timers[i] -= delta
		kill_lines[i].visible = kill_timers[i] > 0


# which team has the pearl, on top of the kill feed. hidden if nobody has it
func update_pearl_label():
	var pearl = get_tree().get_first_node_in_group("pearl")
	var carrier = null
	if pearl and pearl.carrier_name != "":
		carrier = pearl.find_player(pearl.carrier_name)
	if carrier == null:
		pearl_label.visible = false
		return
	pearl_label.visible = true
	pearl_label.text = "%s HAVE THE PEARL" % GameManager.TEAM_NAMES[carrier.team].to_upper()
	pearl_label.modulate = GameManager.TEAM_COLORS.get(carrier.team, Color.WHITE)


func _on_score_changed(scores):
	nomads_score.text = str(scores.get(0, 0))
	monsters_score.text = str(scores.get(1, 0))


# text under the timer, hidden until something happens
func _make_alert_label():
	alert_label = Label.new()
	alert_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	alert_label.offset_top = 52
	alert_label.offset_bottom = 70
	alert_label.offset_left = -200
	alert_label.offset_right = 200
	alert_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	alert_label.add_theme_font_override("font", GameManager.PIXEL_FONT)
	alert_label.add_theme_font_size_override("font_size", 16) # 16 so the font stays sharp
	alert_label.add_theme_constant_override("outline_size", 4)
	alert_label.add_theme_color_override("font_outline_color", Color.BLACK)
	alert_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	alert_label.modulate.a = 0.0
	add_child(alert_label)


# show the text, wait, then fade out
func show_alert(text, team = -1):
	alert_label.text = text
	alert_label.add_theme_color_override("font_color", GameManager.TEAM_COLORS.get(team, Color.WHITE))
	if alert_tween:
		alert_tween.kill() # new message replaces the old one
	alert_label.modulate.a = 1.0
	alert_tween = create_tween()
	alert_tween.tween_interval(2.5)
	alert_tween.tween_property(alert_label, "modulate:a", 0.0, 0.6)


# winner screen (winner -1 = draw)
func show_winner(winner, reason):
	my_player = null # stop the respawn countdown
	$PlayerStats.visible = false
	$PearlIndicator.visible = false
	$KillFeed.visible = false
	alert_label.visible = false
	timer_label.modulate = Color.WHITE # remove the red / orange

	var card = $ScoreboardNode # reuse the score card
	$ScoreboardNode/TextureRect.visible = false # the dark shade on top would look like a black bar
	var nomads_card = $ScoreboardNode/NomadsContainer
	var monsters_card = $ScoreboardNode/MonstersContainer

	# loser is gray
	if winner == -1 or winner == 0:
		nomads_card.modulate = Color.WHITE
	else:
		nomads_card.modulate = Color(0.4, 0.4, 0.45, 1)
	if winner == -1 or winner == 1:
		monsters_card.modulate = Color.WHITE
	else:
		monsters_card.modulate = Color(0.4, 0.4, 0.45, 1)

	card.pivot_offset = Vector2(321, 22) # middle of the card
	var tween = create_tween().set_parallel().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(card, "position:y", size.y * 0.5 - 30.0, 0.9) # bottom half, players are on top
	tween.tween_property(card, "scale", Vector2(1.35, 1.35), 0.9)

	# winner side pulses
	if winner >= 0:
		var winner_card = monsters_card
		if winner == 0:
			winner_card = nomads_card
		var pulse = create_tween().set_loops()
		pulse.tween_property(winner_card, "modulate", Color(1.4, 1.4, 1.4, 1), 0.6)
		pulse.tween_property(winner_card, "modulate", Color.WHITE, 0.6)

	var title = _winner_label(48, GameManager.TEAM_COLORS.get(winner, Color.WHITE), 8)
	if winner < 0:
		title.text = "DRAW!"
	else:
		title.text = "%s WIN!" % GameManager.TEAM_NAMES[winner].to_upper()
	title.position.y = size.y * 0.5 + 22.0
	title.pivot_offset = Vector2(size.x * 0.5, 24)
	title.scale = Vector2(0.2, 0.2)
	tween.tween_property(title, "scale", Vector2.ONE, 0.6).set_delay(0.5) # pops in after the card

	var scores = GameManager.team_scores
	var detail = _winner_label(16, Color(0.85, 0.9, 0.95), 4)
	var why = "Time's up"
	if reason == "target":
		why = "First to %d pearls" % GameManager.PEARLS_TO_WIN
	detail.text = "%s  -  %d : %d" % [why, scores.get(0, 0), scores.get(1, 0)]
	detail.position.y = size.y * 0.5 + 72.0
	detail.modulate.a = 0.0
	tween.tween_property(detail, "modulate:a", 1.0, 0.4).set_delay(0.9)

	var prompt = _winner_label(16, Color.WHITE, 4)
	prompt.text = "Press any key to return to the lobby"
	prompt.position.y = size.y * 0.5 + 96.0
	prompt.modulate.a = 0.0
	await get_tree().create_timer(WINNER_KEY_DELAY).timeout
	waiting_for_key = true
	var blink = create_tween().set_loops()
	blink.tween_property(prompt, "modulate:a", 1.0, 0.5)
	blink.tween_property(prompt, "modulate:a", 0.25, 0.5)


# full width centered text for the winner screen
func _winner_label(font_size, color, outline):
	var label = Label.new()
	label.add_theme_font_override("font", GameManager.PIXEL_FONT)
	label.add_theme_font_size_override("font_size", font_size) # 16, 32, 48 stay sharp
	label.add_theme_color_override("font_color", color)
	label.add_theme_constant_override("outline_size", outline)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.size = Vector2(size.x, font_size + 8)
	add_child(label)
	return label


# any key or mouse button goes back to the lobby (each player on their own)
func _input(event):
	if not waiting_for_key or event.is_echo():
		return
	var is_button = event is InputEventKey or event is InputEventMouseButton or event is InputEventJoypadButton
	if is_button and event.pressed:
		waiting_for_key = false
		get_viewport().set_input_as_handled()
		CharacterSelectManager.leave_match_to_lobby()


# character face inside the portrait frame (same as character select)
func show_character_icon(character_id):
	var portrait = $PlayerStats/PlayerPortrait
	var icon = portrait.get_node_or_null("CharacterIcon")
	if icon == null:
		icon = TextureRect.new()
		icon.name = "CharacterIcon"
		icon.position = Vector2(8, 8) # so the border still shows
		icon.size = portrait.size - Vector2(16, 16)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		portrait.add_child(icon)
		portrait.move_child(icon, 0) # behind the name
	icon.texture = CharacterSelectManager.get_icon(character_id)


# only MY player calls this (see player.gd _ready)
func set_player(player):
	my_player = player
	show_character_icon(CharacterSelectManager.play_as(player.character))
	player_name_label.text = LobbyManager.get_player_name(player.get_multiplayer_authority())
	player_name_label.label_settings = player_name_label.label_settings.duplicate() # own copy so the color doesnt change the shared one
	player_name_label.label_settings.font_color = GameManager.TEAM_COLORS.get(player.team, Color.WHITE)
	player.health.health_changed.connect(_on_health_changed)
	_on_health_changed(player.health.current_health, player.health.max_health) # show full hp right away
	primary_slot.set_ability(player.primary_ability, key_name("primary"))
	ultimate_slot.set_ability(player.ultimate_ability, key_name("ultimate"))


# the key that is set for an action, like "E"
func key_name(action):
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			var code = event.physical_keycode
			if code == 0:
				code = event.keycode
			return OS.get_keycode_string(code)
	return ""


func _on_health_changed(new_health, max_health):
	hp_bar.max_value = max_health
	hp_bar.value = new_health
	hp_label.text = str(int(new_health))


func _on_time_updated(seconds_remaining):
	var total = int(seconds_remaining)
	var minutes = total / 60
	var secs = total % 60
	timer_label.text = "%02d:%02d" % [minutes, secs]
	if total <= 10:
		timer_label.modulate = Color.RED
	else:
		timer_label.modulate = Color.WHITE


func _on_serpent_rising_started():
	timer_label.modulate = Color.ORANGE


func _on_match_ended():
	timer_label.text = "00:00"


# called from the game_start animation
func call_start_match():
	GameManager.start_match()


func initialize_hud():
	$AnimationPlayer.play("game_start")
