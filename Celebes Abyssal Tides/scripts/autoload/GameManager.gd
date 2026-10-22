extends Node
## Match state, scoring, and the server-authoritative match timer.
## The server owns the timer and pushes it (plus the match state) to every peer
## roughly once per second. Clients never tick the timer themselves.

signal state_changed(new_state: int)
signal time_updated(seconds_remaining: int)
signal sudden_death_started
signal match_ended

enum MatchState { MENU, LOBBY, CHARACTER_SELECT, LOADING, IN_PROGRESS, SUDDEN_DEATH, VICTORY }

const MATCH_DURATION = 300.0   # 5 minutes, per your design doc
const SUDDEN_DEATH_DURATION = 120.0  # adjust to your actual sudden-death length

var state: MatchState = MatchState.MENU
var team_scores: Dictionary = {0: 0, 1: 0}
var time_remaining: float = MATCH_DURATION

# Derived from `state` so there is a single source of truth. These keep the
# names the HUD branch already used, so existing HUD code keeps working.
var in_sudden_death: bool:
	get:
		return state == MatchState.SUDDEN_DEATH

var match_active: bool:
	get:
		return state == MatchState.IN_PROGRESS or state == MatchState.SUDDEN_DEATH


func set_state(new_state: MatchState) -> void:
	if state == new_state:
		return
	state = new_state
	state_changed.emit(state)


func reset_match() -> void:
	team_scores = {0: 0, 1: 0}
	time_remaining = MATCH_DURATION


func start_match() -> void:
	if not multiplayer.is_server():
		return
	reset_match()
	set_state(MatchState.IN_PROGRESS)
	sync_timer_state.rpc(time_remaining, state)


func _process(delta: float) -> void:
	# also stop once the connection drops (host left): asking a dead peer
	# is_server() prints "multiplayer instance isn't currently active" every frame
	var peer := multiplayer.multiplayer_peer
	if peer == null or peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		return

	if not multiplayer.is_server() or not match_active:
		return

	time_remaining -= delta

	if time_remaining <= 0.0:
		if state == MatchState.IN_PROGRESS:
			_enter_sudden_death()
		else:
			_end_match()
		return

	# only push updates roughly once a second, not every frame
	if int(time_remaining) != int(time_remaining + delta):
		sync_timer_state.rpc(time_remaining, state)


func _enter_sudden_death() -> void:
	time_remaining = SUDDEN_DEATH_DURATION
	set_state(MatchState.SUDDEN_DEATH)
	sync_timer_state.rpc(time_remaining, state)
	notify_sudden_death.rpc()


func _end_match() -> void:
	time_remaining = 0.0
	set_state(MatchState.VICTORY)
	sync_timer_state.rpc(time_remaining, state)
	notify_match_ended.rpc()


@rpc("authority", "call_local", "reliable")
func sync_timer_state(new_time: float, new_state: int) -> void:
	time_remaining = new_time
	set_state(new_state as MatchState)
	time_updated.emit(int(ceil(time_remaining)))


@rpc("authority", "call_local", "reliable")
func notify_sudden_death() -> void:
	sudden_death_started.emit()


@rpc("authority", "call_local", "reliable")
func notify_match_ended() -> void:
	match_ended.emit()