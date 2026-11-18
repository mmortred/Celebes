extends Node2D

# tuna swimming high above the arena, cleaner sea = more tuna
# sea nomads scoring brings a tuna back, garbage monsters scoring scares one away

const START_TUNA = 6

@onready var school = $School


func _ready():
	GameManager.score_changed.connect(_on_score_changed)
	_on_score_changed(GameManager.team_scores)


func _on_score_changed(scores):
	var count = START_TUNA + int(scores.get(0, 0)) - int(scores.get(1, 0))
	var i = 0
	for tuna in school.get_children():
		if i < count:
			tuna.visible = true
		else:
			tuna.visible = false
		i += 1
