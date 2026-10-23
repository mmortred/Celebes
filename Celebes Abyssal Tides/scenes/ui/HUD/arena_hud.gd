extends Control

@onready var timer_label: Label = $ScoreboardNode/Label
@onready var hp_bar: TextureProgressBar = $PlayerStats/TextureProgressBar #+
@onready var hp_label: Label = $PlayerStats/TextureProgressBar/Label #+
@onready var player_name_label: Label = $PlayerStats/PlayerPortrait/PlayerNameLabel #+

@onready var nomads_score: Label = $ScoreboardNode/NomadsContainer/TeamScoreLabel #+ SCORE
@onready var monsters_score: Label = $ScoreboardNode/MonstersContainer/TeamScoreLabel #+ SCORE
const TEAM_COLORS = {0: Color("56dce8"), 1: Color("a5e35f"), -1: Color.WHITE} #+ ALERT sea / garbage / neutral
var alert_label: Label #+ ALERT pearl taken / dropped / captured banner
var alert_tween: Tween #+ ALERT

func _ready():
	add_to_group("hud") #+ player.gd finds the HUD through this group
	GameManager.time_updated.connect(_on_time_updated)
	GameManager.sudden_death_started.connect(_on_sudden_death_started)
	GameManager.match_ended.connect(_on_match_ended)
	GameManager.score_changed.connect(_on_score_changed) #+ SCORE
	GameManager.announcement.connect(show_alert) #+ ALERT
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
	alert_label.add_theme_font_size_override("font_size", 12) #+
	alert_label.add_theme_constant_override("outline_size", 4) #+
	alert_label.add_theme_color_override("font_outline_color", Color.BLACK) #+
	alert_label.mouse_filter = Control.MOUSE_FILTER_IGNORE #+
	alert_label.modulate.a = 0.0 #+
	add_child(alert_label) #+

func show_alert(text: String, team: int = -1): #+ ALERT pop in, hold, fade out
	alert_label.text = text #+
	alert_label.add_theme_color_override("font_color", TEAM_COLORS.get(team, Color.WHITE)) #+
	if alert_tween: #+
		alert_tween.kill() #+ a new message replaces the old one
	alert_label.modulate.a = 1.0 #+
	alert_tween = create_tween() #+
	alert_tween.tween_interval(2.5) #+
	alert_tween.tween_property(alert_label, "modulate:a", 0.0, 0.6) #+

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
	show_character_icon(player.character) #+ ICON
	player_name_label.text = LobbyManager.get_player_name(player.get_multiplayer_authority()) #+ NAME the username from settings
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

func _on_sudden_death_started():
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
