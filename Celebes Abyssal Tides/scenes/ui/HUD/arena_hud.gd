extends Control

@onready var timer_label: Label = $ScoreboardNode/Label
@onready var hp_bar: TextureProgressBar = $PlayerStats/TextureProgressBar #+
@onready var hp_label: Label = $PlayerStats/TextureProgressBar/Label #+
@onready var player_name_label: Label = $PlayerStats/PlayerPortrait/PlayerNameLabel #+

@onready var nomads_score: Label = $ScoreboardNode/NomadsContainer/TeamScoreLabel #+ SCORE
@onready var monsters_score: Label = $ScoreboardNode/MonstersContainer/TeamScoreLabel #+ SCORE
var alert_label: Label #+ ALERT pearl taken / dropped / captured banner
var alert_tween: Tween #+ ALERT
var waiting_for_key := false #+ WINNER any key goes back to the lobby once this is on
const WINNER_KEY_DELAY = 1.5 #+ WINNER seconds before a key counts, so a last attack click doesn't skip the screen

func _ready():
	add_to_group("hud") #+ player.gd finds the HUD through this group
	GameManager.time_updated.connect(_on_time_updated)
	GameManager.leviathan_rising_started.connect(_on_leviathan_rising_started)
	GameManager.match_ended.connect(_on_match_ended)
	GameManager.score_changed.connect(_on_score_changed) #+ SCORE
	GameManager.announcement.connect(show_alert) #+ ALERT
	GameManager.match_won.connect(show_winner) #+ WINNER
	_on_score_changed(GameManager.team_scores) #+ SCORE real scores, not the placeholder numbers
	_make_alert_label() #+ ALERT
	initialize_hud()

func _on_score_changed(scores: Dictionary): #+ SCORE
	nomads_score.text = str(scores.get(0, 0)) #+
	monsters_score.text = str(scores.get(1, 0)) #+

func _make_alert_label(): #+ ALERT centred under the timer, hidden until something happens
	alert_label = Label.new() #+
	alert_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP) #+
	alert_label.offset_top = 52 #+
	alert_label.offset_bottom = 70 #+
	alert_label.offset_left = -200 #+
	alert_label.offset_right = 200 #+
	alert_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER #+
	alert_label.add_theme_font_override("font", GameManager.PIXEL_FONT) #+ monogram
	alert_label.add_theme_font_size_override("font_size", 16) #+ monogram's native size, stays crisp
	alert_label.add_theme_constant_override("outline_size", 4) #+
	alert_label.add_theme_color_override("font_outline_color", Color.BLACK) #+
	alert_label.mouse_filter = Control.MOUSE_FILTER_IGNORE #+
	alert_label.modulate.a = 0.0 #+
	add_child(alert_label) #+

func show_alert(text: String, team: int = -1): #+ ALERT pop in, hold, fade out
	alert_label.text = text #+
	alert_label.add_theme_color_override("font_color", GameManager.TEAM_COLORS.get(team, Color.WHITE)) #+
	if alert_tween: #+
		alert_tween.kill() #+ a new message replaces the old one
	alert_label.modulate.a = 1.0 #+
	alert_tween = create_tween() #+
	alert_tween.tween_interval(2.5) #+
	alert_tween.tween_property(alert_label, "modulate:a", 0.0, 0.6) #+

##Winner screen #+
# Everyone sees it, winners and losers: the team score card slides to the middle with the #+
# winning side lit up, a big result line in the pixel font, then "press any key". #+
func show_winner(winner: int, reason: String): #+ WINNER winner -1 = draw
	$PlayerStats.visible = false #+ my HP / portrait don't matter any more
	$PearlIndicator.visible = false #+
	alert_label.visible = false #+
	timer_label.modulate = Color.WHITE #+ no red / orange left over from the last seconds

	var card = $ScoreboardNode #+ reuse the HUD's team score card
	$ScoreboardNode/TextureRect.visible = false #+ its dark top-of-screen shade would slide down with the card as a black band
	var nomads_card = $ScoreboardNode/NomadsContainer #+
	var monsters_card = $ScoreboardNode/MonstersContainer #+
	for side in [[0, nomads_card], [1, monsters_card]]: #+
		side[1].modulate = Color.WHITE if winner in [-1, side[0]] else Color(0.4, 0.4, 0.45, 1) #+ loser greyed out
	card.pivot_offset = Vector2(321, 22) #+ middle of the card
	var tween = create_tween().set_parallel().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT) #+
	tween.tween_property(card, "position:y", size.y * 0.5 - 30.0, 0.9) #+ lower half: the camera keeps the players in the top half
	tween.tween_property(card, "scale", Vector2(1.35, 1.35), 0.9) #+
	if winner >= 0: #+ winning side pulses
		var winner_card = nomads_card if winner == 0 else monsters_card #+
		var pulse = create_tween().set_loops() #+
		pulse.tween_property(winner_card, "modulate", Color(1.4, 1.4, 1.4, 1), 0.6) #+
		pulse.tween_property(winner_card, "modulate", Color.WHITE, 0.6) #+

	var title = _winner_label(48, GameManager.TEAM_COLORS.get(winner, Color.WHITE), 8) #+
	title.text = "DRAW!" if winner < 0 else "%s WIN!" % GameManager.TEAM_NAMES[winner].to_upper() #+
	title.position.y = size.y * 0.5 + 22.0 #+
	title.pivot_offset = Vector2(size.x * 0.5, 24) #+
	title.scale = Vector2(0.2, 0.2) #+
	tween.tween_property(title, "scale", Vector2.ONE, 0.6).set_delay(0.5) #+ pops in after the card arrives

	var scores = GameManager.team_scores #+
	var detail = _winner_label(16, Color(0.85, 0.9, 0.95), 4) #+
	var why = "First to %d pearls" % GameManager.TARGET_SCORE if reason == "target" else "Time's up" #+
	detail.text = "%s  -  %d : %d" % [why, scores.get(0, 0), scores.get(1, 0)] #+
	detail.position.y = size.y * 0.5 + 72.0 #+
	detail.modulate.a = 0.0 #+
	tween.tween_property(detail, "modulate:a", 1.0, 0.4).set_delay(0.9) #+

	var prompt = _winner_label(16, Color.WHITE, 4) #+
	prompt.text = "Press any key to return to the lobby" #+
	prompt.position.y = size.y * 0.5 + 96.0 #+
	prompt.modulate.a = 0.0 #+
	await get_tree().create_timer(WINNER_KEY_DELAY).timeout #+
	waiting_for_key = true #+
	var blink = create_tween().set_loops() #+
	blink.tween_property(prompt, "modulate:a", 1.0, 0.5) #+
	blink.tween_property(prompt, "modulate:a", 0.25, 0.5) #+

func _winner_label(font_size: int, color: Color, outline: int) -> Label: #+ WINNER full-width centred pixel-font line
	var label = Label.new() #+
	label.add_theme_font_override("font", GameManager.PIXEL_FONT) #+ monogram
	label.add_theme_font_size_override("font_size", font_size) #+ multiples of 16 stay crisp
	label.add_theme_color_override("font_color", color) #+
	label.add_theme_constant_override("outline_size", outline) #+
	label.add_theme_color_override("font_outline_color", Color.BLACK) #+
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER #+
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE #+
	label.size = Vector2(size.x, font_size + 8) #+
	add_child(label) #+
	return label #+

func _input(event): #+ WINNER any key or mouse button, each player on their own
	if not waiting_for_key or event.is_echo(): #+
		return #+
	if (event is InputEventKey or event is InputEventMouseButton or event is InputEventJoypadButton) and event.pressed: #+
		waiting_for_key = false #+
		get_viewport().set_input_as_handled() #+
		CharacterSelectManager.leave_match_to_lobby() #+

func show_character_icon(character_id: int): #+ ICON same face crop as character select, inside the portrait frame
	var portrait = $PlayerStats/PlayerPortrait #+
	var icon: TextureRect = portrait.get_node_or_null("CharacterIcon") #+
	if icon == null: #+
		icon = TextureRect.new() #+
		icon.name = "CharacterIcon" #+
		icon.position = Vector2(8, 8) #+ inset so the frame's border stays visible
		icon.size = portrait.size - Vector2(16, 16) #+
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE #+
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED #+
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST #+ crisp pixels
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE #+
		portrait.add_child(icon) #+
		portrait.move_child(icon, 0) #+ behind the name label
	icon.texture = CharacterSelectManager.get_icon(character_id) #+

func set_player(player): #+ called by MY player only (player.gd _ready checks authority)
	show_character_icon(CharacterSelectManager.play_as(player.character)) #+ ICON stand-in's face while art is missing
	player_name_label.text = LobbyManager.get_player_name(player.get_multiplayer_authority()) #+ NAME the username from settings
	player_name_label.label_settings = player_name_label.label_settings.duplicate() #+ NAME own copy so the tint doesn't touch the shared resource
	player_name_label.label_settings.font_color = GameManager.TEAM_COLORS.get(player.team, Color.WHITE) #+ NAME teal / green by team
	player.health.health_changed.connect(_on_health_changed) #+ update the bar every time my HP changes
	_on_health_changed(player.health.current_health, player.health.max_health) #+ show full HP right away

func _on_health_changed(new_health: float, max_health: float): #+
	hp_bar.max_value = max_health #+
	hp_bar.value = new_health #+
	hp_label.text = str(int(new_health)) #+

func _on_time_updated(seconds_remaining: int):
	var minutes = seconds_remaining / 60
	var secs = seconds_remaining % 60
	timer_label.text = "%02d:%02d" % [minutes, secs]


	if seconds_remaining <= 10:
		timer_label.modulate = Color.RED
	else:
		timer_label.modulate = Color.WHITE

func _on_leviathan_rising_started():
	timer_label.modulate = Color.ORANGE
	# end game call

func _on_match_ended():
	timer_label.text = "00:00"
	# insert tranition to match end screen

func call_start_match():
	GameManager.start_match()

func initialize_hud():
	$AnimationPlayer.play("game_start")
	
func team_score(team): #+ SCORE kept for the old call sites; scores come from GameManager now
	return GameManager.team_scores.get(team, 0)
