extends Node
## Match state foundation; scoring and timer logic are added in Stage 14.
enum MatchState { MENU, LOBBY, CHARACTER_SELECT, LOADING, IN_PROGRESS, SUDDEN_DEATH, VICTORY }
signal state_changed(new_state: int)
var state: MatchState = MatchState.MENU
var team_scores: Dictionary = {0: 0, 1: 0}
var match_timer := 0.0

func set_state(new_state: MatchState) -> void:
	if state == new_state:
		return
	state = new_state
	state_changed.emit(state)

func reset_match() -> void:
	team_scores = {0: 0, 1: 0}
	match_timer = 0.0
