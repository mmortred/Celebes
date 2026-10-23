extends Node
## Host-authoritative scoreboard and match departure handling.
signal scoreboard_changed
signal match_result_changed(message: String)

const MAIN_MENU := "res://Celebes Abyssal Tides/scenes/MainMenu.tscn"
const ASSIST_WINDOW := 10.0
var records: Dictionary = {}
var damage_history: Dictionary = {}
var match_running := false
var ending := false
var result_message := ""

func _ready() -> void:
	multiplayer.peer_disconnected.connect(_peer_left)
	multiplayer.server_disconnected.connect(_server_left)

func begin_match() -> void:
	if multiplayer.multiplayer_peer == null or not multiplayer.is_server():
		return
	records.clear()
	damage_history.clear()
	ending = false
	result_message = ""
	for slot in LobbyManager.slots:
		var peer_id := int(slot.get("peer_id", 0))
		var team_id := int(slot.get("team_id", 2))
		if peer_id > 0 and team_id < 2:
			records[peer_id] = {"name": str(slot.get("player_name", "Player %d" % peer_id)), "team": team_id, "kills": 0, "deaths": 0, "assists": 0}
	match_running = true
	_broadcast()
	_check_winner()

func record_damage(victim: int, attacker: int) -> void:
	if not _is_host_active() or victim == attacker or not records.has(victim) or not records.has(attacker):
		return
	if int(records[victim]["team"]) == int(records[attacker]["team"]):
		return
	if not damage_history.has(victim):
		damage_history[victim] = {}
	damage_history[victim][attacker] = Time.get_ticks_msec() / 1000.0

func record_death(victim: int, killer: int) -> void:
	if not _is_host_active() or not records.has(victim):
		return
	records[victim]["deaths"] += 1
	var now := Time.get_ticks_msec() / 1000.0
	if killer != victim and records.has(killer) and int(records[killer]["team"]) != int(records[victim]["team"]):
		records[killer]["kills"] += 1
		for assist_id in damage_history.get(victim, {}):
			var aid := int(assist_id)
			if aid != killer and records.has(aid) and now - float(damage_history[victim][aid]) <= ASSIST_WINDOW:
				records[aid]["assists"] += 1
	damage_history.erase(victim)
	_broadcast()

func _is_host_active() -> bool:
	return multiplayer.multiplayer_peer != null and multiplayer.is_server() and match_running and not ending

func _broadcast() -> void:
	scoreboard_changed.emit()
	if multiplayer.multiplayer_peer != null and multiplayer.is_server():
		_receive_records.rpc(records.duplicate(true))

@rpc("authority", "call_remote", "reliable")
func _receive_records(snapshot: Dictionary) -> void:
	records = snapshot.duplicate(true)
	match_running = not records.is_empty()
	scoreboard_changed.emit()

func request_leave() -> void:
	if multiplayer.multiplayer_peer == null:
		_return_to_menu()
		return
	if multiplayer.is_server():
		_end_all("Host left — match ended.")
	else:
		_request_departure.rpc_id(1)
		NetworkManager.close_connection()
		_clear_local()
		_return_to_menu()

@rpc("any_peer", "call_remote", "reliable")
func _request_departure() -> void:
	if multiplayer.multiplayer_peer == null or not multiplayer.is_server():
		return
	var peer_id := multiplayer.get_remote_sender_id()
	if peer_id == 1:
		return
	_remove_peer(peer_id)

func _peer_left(peer_id: int) -> void:
	if _is_host_active():
		_remove_peer(peer_id)

func _remove_peer(peer_id: int) -> void:
	if not records.has(peer_id):
		return
	records.erase(peer_id)
	damage_history.erase(peer_id)
	for victim in damage_history:
		damage_history[victim].erase(peer_id)
	_broadcast()
	_check_winner()

func _check_winner() -> void:
	if not _is_host_active():
		return
	var nomads := 0
	var monsters := 0
	for data in records.values():
		if int(data["team"]) == 0:
			nomads += 1
		elif int(data["team"]) == 1:
			monsters += 1
	if nomads == 0 or monsters == 0:
		var message := "Sea Nomads win — no enemies remain." if nomads > 0 else "Garbage Monsters win — no enemies remain." if monsters > 0 else "Match ended — no players remain."
		_end_all(message)

func _end_all(message: String) -> void:
	if ending:
		return
	ending = true
	match_running = false
	_announce_end.rpc(message)
	_announce_end(message)

@rpc("authority", "call_remote", "reliable")
func _announce_end(message: String) -> void:
	result_message = message
	match_running = false
	ending = true
	match_result_changed.emit(message)
	_return_after_delay()

func _return_after_delay() -> void:
	await get_tree().create_timer(3.0).timeout
	NetworkManager.close_connection()
	_clear_local()
	_return_to_menu()

func _server_left() -> void:
	if match_running and not ending:
		_announce_end("Host disconnected — match ended.")

func _clear_local() -> void:
	match_running = false
	ending = false
	records.clear()
	damage_history.clear()
	result_message = ""
	GameManager.set_state(GameManager.MatchState.MENU)

func _return_to_menu() -> void:
	get_tree().call_deferred("change_scene_to_file", MAIN_MENU)
