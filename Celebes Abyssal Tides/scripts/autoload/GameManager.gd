extends Node

# match state, score and timer (only the host counts the time)

signal state_changed(new_state)
signal time_updated(seconds_remaining)
signal serpent_rising_started
signal match_ended
signal score_changed(scores)
signal announcement(text, team) # pearl taken / dropped / captured, the hud shows it
signal match_won(winner, reason) # winner team (-1 = draw), reason is "target" or "time"

enum MatchState { MENU, LOBBY, CHARACTER_SELECT, LOADING, IN_PROGRESS, SERPENT_RISING, VICTORY }

const MATCH_DURATION = 300.0 # 5 minutes
const SERPENT_RISING_DURATION = 120.0
const PEARLS_TO_WIN = 12 # <-- pearls a team needs to win the match (change this number)
const TEAM_NAMES = {0: "Sea Nomads", 1: "Garbage Monsters"}
const TEAM_COLORS = {0: Color("2ed3be"), 1: Color("a5e35f"), -1: Color.WHITE} # teal, green, white
const PIXEL_FONT = preload("res://Celebes Abyssal Tides/assets/font/monogram.ttf")

var state = MatchState.MENU
var team_scores = {0: 0, 1: 0}
var time_remaining = MATCH_DURATION
var match_paused = false # the serpent cutscene pauses the timer and the border


func set_state(new_state):
	if state == new_state:
		return
	state = new_state
	state_changed.emit(state)


func is_match_active():
	if state == MatchState.IN_PROGRESS:
		return true
	if state == MatchState.SERPENT_RISING:
		return true
	return false


func reset_match():
	team_scores = {0: 0, 1: 0}
	time_remaining = MATCH_DURATION
	match_paused = false


func start_match():
	if not multiplayer.is_server():
		return
	reset_match()
	set_state(MatchState.IN_PROGRESS)
	sync_timer_state.rpc(time_remaining, state)
	sync_scores.rpc(team_scores)


# host only: a team got a pearl in
func add_score(team):
	if not multiplayer.is_server():
		return
	if state == MatchState.VICTORY:
		return
	team_scores[team] = int(team_scores.get(team, 0)) + 1
	sync_scores.rpc(team_scores)
	if team_scores[team] >= PEARLS_TO_WIN:
		_end_match(team, "target")


@rpc("authority", "call_local", "reliable")
func sync_scores(scores: Dictionary):
	team_scores = {0: int(scores.get(0, 0)), 1: int(scores.get(1, 0))}
	score_changed.emit(team_scores)


# team -1 = white text
@rpc("authority", "call_local", "reliable")
func announce(text: String, team: int = -1):
	announcement.emit(text, team)


func _process(delta):
	# stop if theres no connection (host left), or else is_server() spams errors every frame
	var peer = multiplayer.multiplayer_peer
	if peer == null:
		return
	if peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		return

	if not multiplayer.is_server():
		return
	if not is_match_active() or match_paused:
		return

	time_remaining -= delta

	if time_remaining <= 0.0:
		if state == MatchState.IN_PROGRESS:
			_enter_serpent_rising()
		else:
			_end_match(_time_up_winner(), "time")
		return

	# only send when the seconds number changes, not every frame
	if int(time_remaining) != int(time_remaining + delta):
		sync_timer_state.rpc(time_remaining, state)


func _enter_serpent_rising():
	time_remaining = SERPENT_RISING_DURATION
	set_state(MatchState.SERPENT_RISING)
	sync_timer_state.rpc(time_remaining, state)
	notify_serpent_rising.rpc()


func _end_match(winner, reason):
	time_remaining = 0.0
	set_state(MatchState.VICTORY)
	sync_timer_state.rpc(time_remaining, state)
	notify_match_ended.rpc()
	notify_match_won.rpc(winner, reason)


# time is up: the team with more pearls wins, -1 = draw
func _time_up_winner():
	var nomads = int(team_scores.get(0, 0))
	var monsters = int(team_scores.get(1, 0))
	if nomads == monsters:
		return -1
	if nomads > monsters:
		return 0
	return 1


# every peer: the arena moves the camera and the hud shows the winner
@rpc("authority", "call_local", "reliable")
func notify_match_won(winner: int, reason: String):
	ScoreboardManager.match_running = false # so it doesnt also say "no enemies remain"
	ScoreboardManager.ending = true
	match_won.emit(winner, reason)


@rpc("authority", "call_local", "reliable")
func sync_timer_state(new_time: float, new_state: int):
	time_remaining = new_time
	set_state(new_state)
	time_updated.emit(int(ceil(time_remaining)))


@rpc("authority", "call_local", "reliable")
func notify_serpent_rising():
	serpent_rising_started.emit()


@rpc("authority", "call_local", "reliable")
func notify_match_ended():
	match_ended.emit()


# F11 switches between fullscreen and a window you can resize (works on every screen)
func _unhandled_input(event):
	if not event is InputEventKey:
		return
	if not event.pressed or event.echo or event.keycode != KEY_F11:
		return
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(Vector2i(1280, 720))
		var screen = DisplayServer.window_get_current_screen()
		var middle = DisplayServer.screen_get_position(screen) + (DisplayServer.screen_get_size(screen) - Vector2i(1280, 720)) / 2
		DisplayServer.window_set_position(middle)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
