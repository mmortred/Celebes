extends Control

@onready var timer_label: Label = $ScoreboardNode/Label
@onready var hp_bar: TextureProgressBar = $PlayerStats/TextureProgressBar #+
@onready var hp_label: Label = $PlayerStats/TextureProgressBar/Label #+
@onready var player_name_label: Label = $PlayerStats/PlayerPortrait/PlayerNameLabel #+

func _ready():
	add_to_group("hud") #+ player.gd finds the HUD through this group
	GameManager.time_updated.connect(_on_time_updated)
	GameManager.sudden_death_started.connect(_on_sudden_death_started)
	GameManager.match_ended.connect(_on_match_ended)
	initialize_hud()

func set_player(player): #+ called by MY player only (player.gd _ready checks authority)
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
	
func team_score(team):
	pass
