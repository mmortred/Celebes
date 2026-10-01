extends Node

enum MatchState {
	MENU,
	LOBBY,
	CHARACTER_SELECT,
	LOADING,
	IN_PROGRESS,
	SUDDEN_DEATH,
	VICTORY
}

var state = MatchState.MENU
var team_scores = {0: 0, 1: 0}
var match_timer := 0.0

signal state_changed(new_state)

func set_state(new_state):
	state = new_state
	state_changed.emit(state)
