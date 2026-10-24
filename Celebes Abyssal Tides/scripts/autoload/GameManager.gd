extends Node
## Match state, scoring, and the server-authoritative match timer.
## The server owns the timer and pushes it (plus the match state) to every peer
## roughly once per second. Clients never tick the timer themselves.

signal state_changed(new_state: int)
signal time_updated(seconds_remaining: int)
signal leviathan_rising_started
signal match_ended
signal score_changed(scores: Dictionary)
signal announcement(text: String, team: int) # pearl taken / dropped / captured, shown by the HUD
signal match_won(winner: int, reason: String) # winner team, -1 = draw; reason "target" or "time". Starts the winner screen

enum MatchState { MENU, LOBBY, CHARACTER_SELECT, LOADING, IN_PROGRESS, LEVIATHAN_RISING, VICTORY }

const MATCH_DURATION = 300.0   # 5 minutes, per your design doc
const LEVIATHAN_RISING_DURATION = 120.0  # adjust to your actual leviathan-rising length
const TARGET_SCORE = 20 # first team to capture this many pearls wins on the spot
const TEAM_NAMES = {0: "Sea Nomads", 1: "Garbage Monsters"}
const TEAM_COLORS = {0: Color("2ed3be"), 1: Color("a5e35f"), -1: Color.WHITE} # Sea Nomads teal, Garbage Monsters green, neutral
const PIXEL_FONT = preload("res://Celebes Abyssal Tides/assets/font/monogram.ttf") # alerts and name tags

var state: MatchState = MatchState.MENU
var team_scores: Dictionary = {0: 0, 1: 0}
var time_remaining: float = MATCH_DURATION
var match_paused := false # set on every peer by the leviathan cutscene: the timer and the border wait

# Derived from `state` so there is a single source of truth. These keep the
# names the HUD branch already used, so existing HUD code keeps working.
var in_leviathan_rising: bool:
	get:
		return state == MatchState.LEVIATHAN_RISING

var match_active: bool:
	get:
		return state == MatchState.IN_PROGRESS or state == MatchState.LEVIATHAN_RISING


func set_state(new_state: MatchState) -> void:
	if state == new_state:
		return
	state = new_state
	state_changed.emit(state)


func reset_match() -> void:
	team_scores = {0: 0, 1: 0}
	time_remaining = MATCH_DURATION
	match_paused = false


func start_match() -> void:
	if not multiplayer.is_server():
		return
	reset_match()
	set_state(MatchState.IN_PROGRESS)
	sync_timer_state.rpc(time_remaining, state)
	sync_scores.rpc(team_scores)


# SCORING (server decides, everyone hears about it)
func add_score(team: int) -> void:
	if not multiplayer.is_server() or state == MatchState.VICTORY:
		return
	team_scores[team] = int(team_scores.get(team, 0)) + 1
	sync_scores.rpc(team_scores)
	if team_scores[team] >= TARGET_SCORE:
		_end_match(team, "target")


@rpc("authority", "call_local", "reliable")
func sync_scores(scores: Dictionary) -> void:
	team_scores = {0: int(scores.get(0, 0)), 1: int(scores.get(1, 0))}
	score_changed.emit(team_scores)


# team -1 = neutral (white) message
@rpc("authority", "call_local", "reliable")
func announce(text: String, team: int = -1) -> void:
	announcement.emit(text, team)


func _process(delta: float) -> void:
	# also stop once the connection drops (host left): asking a dead peer
	# is_server() prints "multiplayer instance isn't currently active" every frame
	var peer := multiplayer.multiplayer_peer
	if peer == null or peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		return

	if not multiplayer.is_server() or not match_active or match_paused:
		return

	time_remaining -= delta

	if time_remaining <= 0.0:
		if state == MatchState.IN_PROGRESS:
			_enter_leviathan_rising()
		else:
			_end_match(_time_up_winner(), "time")
		return

	# only push updates roughly once a second, not every frame
	if int(time_remaining) != int(time_remaining + delta):
		sync_timer_state.rpc(time_remaining, state)


func _enter_leviathan_rising() -> void:
	time_remaining = LEVIATHAN_RISING_DURATION
	set_state(MatchState.LEVIATHAN_RISING)
	sync_timer_state.rpc(time_remaining, state)
	notify_leviathan_rising.rpc()


func _end_match(winner: int, reason: String) -> void:
	time_remaining = 0.0
	set_state(MatchState.VICTORY)
	sync_timer_state.rpc(time_remaining, state)
	notify_match_ended.rpc()
	notify_match_won.rpc(winner, reason)


# Time ran out before anyone reached TARGET_SCORE: most pearls wins, -1 = draw.
func _time_up_winner() -> int:
	var nomads := int(team_scores.get(0, 0))
	var monsters := int(team_scores.get(1, 0))
	if nomads == monsters:
		return -1
	return 0 if nomads > monsters else 1


# Every peer: the arena pans to the players and the HUD shows the winner screen.
@rpc("authority", "call_local", "reliable")
func notify_match_won(winner: int, reason: String) -> void:
	ScoreboardManager.match_running = false # the match is decided; no "no enemies remain" result on top
	ScoreboardManager.ending = true
	match_won.emit(winner, reason)


@rpc("authority", "call_local", "reliable")
func sync_timer_state(new_time: float, new_state: int) -> void:
	time_remaining = new_time
	set_state(new_state as MatchState)
	time_updated.emit(int(ceil(time_remaining)))


@rpc("authority", "call_local", "reliable")
func notify_leviathan_rising() -> void:
	leviathan_rising_started.emit()


@rpc("authority", "call_local", "reliable")
func notify_match_ended() -> void:
	match_ended.emit()