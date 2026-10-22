extends Node
## Shared lobby data foundation for future Stage 7 integration.
signal lobby_updated
const MAX_PLAYERS := 8
var slots: Array[Dictionary] = []

func _ready() -> void:
	reset_lobby()

func reset_lobby() -> void:
	slots.clear()
	for i in range(MAX_PLAYERS):
		slots.append({"peer_id": 0, "player_name": "", "team_id": get_default_team_for_slot(i), "character_id": -1, "ready": false})
	lobby_updated.emit()

func get_default_team_for_slot(index: int) -> int:
	if index <= 2:
		return 0
	if index <= 5:
		return 1
	return 2

# Display name for a peer, for every screen after the lobby (character select,
# arena labels, HUD). Comes from each player's settings username, which the
# lobby host shares with everyone.
func get_player_name(peer_id: int) -> String:
	var index := find_slot_by_peer(peer_id)
	if index != -1 and str(slots[index].get("player_name", "")) != "":
		return str(slots[index]["player_name"])
	var offline := multiplayer.multiplayer_peer == null
	if offline or peer_id == multiplayer.get_unique_id():
		return PlayerProfile.username
	return "Player %d" % peer_id


func find_slot_by_peer(peer_id: int) -> int:
	for i in range(slots.size()):
		if int(slots[i].get("peer_id", 0)) == peer_id:
			return i
	return -1

func set_slot_player(index: int, peer_id: int, player_name: String = "") -> void:
	if multiplayer.multiplayer_peer == null or not multiplayer.is_server():
		return
	if index < 0 or index >= MAX_PLAYERS or peer_id <= 0:
		return
	if slots.size() != MAX_PLAYERS:
		reset_lobby()
	var old_index := find_slot_by_peer(peer_id)
	if old_index != -1 and old_index != index:
		clear_slot(old_index)
	slots[index] = {"peer_id": peer_id, "player_name": player_name, "team_id": get_default_team_for_slot(index), "character_id": -1, "ready": false}
	sync_lobby()

func apply_host_snapshot(assigned_slots: Dictionary, names: Dictionary) -> void:
	if multiplayer.multiplayer_peer == null or not multiplayer.is_server():
		return
	var previous: Dictionary = {}
	for slot in slots:
		var id := int(slot.get("peer_id", 0))
		if id > 0:
			previous[id] = bool(slot.get("ready", false))
	reset_lobby()
	for index in assigned_slots:
		var slot_index := int(index)
		var id := int(assigned_slots[index])
		if slot_index < 0 or slot_index >= MAX_PLAYERS or id <= 0:
			continue
		slots[slot_index] = {"peer_id": id, "player_name": str(names.get(id, "Player " + str(id))), "team_id": get_default_team_for_slot(slot_index), "character_id": -1, "ready": bool(previous.get(id, false))}
	sync_lobby()

func clear_slot(index: int) -> void:
	if index < 0 or index >= MAX_PLAYERS:
		return
	slots[index] = {"peer_id": 0, "player_name": "", "team_id": get_default_team_for_slot(index), "character_id": -1, "ready": false}
	lobby_updated.emit()

func remove_player(peer_id: int) -> void:
	if not multiplayer.is_server():
		return
	var index := find_slot_by_peer(peer_id)
	if index != -1:
		clear_slot(index)
		sync_lobby()

func reset_ready_states() -> void:
	if not multiplayer.is_server():
		return
	for slot in slots:
		slot["ready"] = false
	sync_lobby()

func can_start_match() -> bool:
	var nomads := 0
	var monsters := 0
	for slot in slots:
		if int(slot["peer_id"]) == 0:
			continue
		if int(slot["team_id"]) == 2:
			continue
		if not bool(slot["ready"]):
			return false
		if int(slot["team_id"]) == 0:
			nomads += 1
		else:
			monsters += 1
	return nomads > 0 and monsters > 0

func sync_lobby() -> void:
	if not multiplayer.is_server():
		return
	_receive_lobby.rpc(slots.duplicate(true))

@rpc("authority", "call_remote", "reliable")
func _receive_lobby(new_slots: Array) -> void:
	slots.clear()
	for slot in new_slots:
		slots.append(slot.duplicate(true))
	lobby_updated.emit()
