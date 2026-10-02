extends Node

signal lobby_changed
signal start_requested

const TEAM_SEA := "sea_nomads"
const TEAM_GARBAGE := "garbage_monsters"
const TEAM_SPECTATOR := "spectator"

const SEA_SLOTS := [0, 1, 2]
const GARBAGE_SLOTS := [3, 4, 5]
const SPECTATOR_SLOTS := [6, 7]
const ALL_SLOTS := [0, 1, 2, 3, 4, 5, 6, 7]

# Host-authoritative state:
# { peer_id: {"name": String, "slot": int, "ready": bool} }
var players: Dictionary = {}

func reset() -> void:
	players.clear()
	lobby_changed.emit()

func setup_host() -> void:
	reset()
	if multiplayer.is_server():
		players[1] = {"name": "Player 1", "slot": 0, "ready": false}
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)
		lobby_changed.emit()

func request_join(name: String = "") -> void:
	if multiplayer.is_server():
		return
	register_player.rpc_id(1, name)

@rpc("any_peer", "call_remote", "reliable")
func register_player(name: String) -> void:
	if not multiplayer.is_server():
		return
	var peer_id := multiplayer.get_remote_sender_id()
	if players.has(peer_id):
		return
	var slot := _first_free_playing_slot()
	if slot == -1:
		slot = _first_free_spectator_slot()
	if slot == -1:
		return
	var final_name := name.strip_edges()
	if final_name.is_empty():
		final_name = "Player " + str(peer_id)
	players[peer_id] = {"name": final_name, "slot": slot, "ready": false}
	_sync()

func request_slot(slot: int) -> void:
	if multiplayer.is_server():
		_move_player(1, slot)
	else:
		request_slot_rpc.rpc_id(1, slot)

@rpc("any_peer", "call_remote", "reliable")
func request_slot_rpc(slot: int) -> void:
	if not multiplayer.is_server():
		return
	_move_player(multiplayer.get_remote_sender_id(), slot)

func set_player_ready(value: bool) -> void:
	if multiplayer.is_server():
		_set_ready(1, value)
	else:
		request_ready_rpc.rpc_id(1, value)

@rpc("any_peer", "call_remote", "reliable")
func request_ready_rpc(value: bool) -> void:
	if not multiplayer.is_server():
		return
	_set_ready(multiplayer.get_remote_sender_id(), value)

func can_host_start() -> bool:
	if not multiplayer.is_server():
		return false
	var playing_count := 0
	for peer_id in players:
		var data: Dictionary = players[peer_id]
		if team_for_slot(int(data.slot)) == TEAM_SPECTATOR:
			continue
		playing_count += 1
		if peer_id != 1 and not bool(data.ready):
			return false
	return playing_count >= 2

func request_start() -> void:
	if multiplayer.is_server() and can_host_start():
		start_match.rpc()

@rpc("authority", "call_local", "reliable")
func start_match() -> void:
	start_requested.emit()

func team_for_slot(slot: int) -> String:
	if slot in SEA_SLOTS:
		return TEAM_SEA
	if slot in GARBAGE_SLOTS:
		return TEAM_GARBAGE
	return TEAM_SPECTATOR

func player_in_slot(slot: int) -> int:
	for peer_id in players:
		if int(players[peer_id].slot) == slot:
			return int(peer_id)
	return 0

func local_player_data() -> Dictionary:
	var id := multiplayer.get_unique_id()
	return players.get(id, {})

func _move_player(peer_id: int, slot: int) -> void:
	if not multiplayer.is_server() or slot not in ALL_SLOTS or not players.has(peer_id):
		return
	if player_in_slot(slot) != 0:
		return
	players[peer_id].slot = slot
	# Spectators never block Start Game.
	if team_for_slot(slot) == TEAM_SPECTATOR:
		players[peer_id].ready = false
	_sync()

func _set_ready(peer_id: int, value: bool) -> void:
	if not multiplayer.is_server() or not players.has(peer_id):
		return
	if team_for_slot(int(players[peer_id].slot)) == TEAM_SPECTATOR:
		value = false
	players[peer_id].ready = value
	_sync()

func _first_free_playing_slot() -> int:
	for slot in SEA_SLOTS + GARBAGE_SLOTS:
		if player_in_slot(slot) == 0:
			return slot
	return -1

func _first_free_spectator_slot() -> int:
	for slot in SPECTATOR_SLOTS:
		if player_in_slot(slot) == 0:
			return slot
	return -1

func _on_peer_disconnected(peer_id: int) -> void:
	if players.has(peer_id):
		players.erase(peer_id)
		_sync()

func _sync() -> void:
	sync_lobby.rpc(players)
	lobby_changed.emit()

@rpc("authority", "call_remote", "reliable")
func sync_lobby(state: Dictionary) -> void:
	players = state.duplicate(true)
	lobby_changed.emit()
