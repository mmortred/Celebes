extends Control

@onready var timer_label: Label = $ScoreboardNode/Label

func _ready():
	GameManager.time_updated.connect(_on_time_updated)
	GameManager.sudden_death_started.connect(_on_sudden_death_started)
	GameManager.match_ended.connect(_on_match_ended)
	initialize_hud()

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
