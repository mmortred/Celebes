extends Node

# the lobby slots, the host changes them and sends them to everyone

signal lobby_updated

const MAX_PLAYERS = 8

var slots = [] # 8 slots, each one is {peer_id, player_name, team_id, character_id, ready}


func _ready():
	reset_lobby()


func reset_lobby():
	slots.clear()
	for i in MAX_PLAYERS:
		slots.append(_make_slot(i, 0, "", false))
	lobby_updated.emit()


func _make_slot(index, peer_id, player_name, is_ready):
	return {"peer_id": peer_id, "player_name": player_name, "team_id": get_default_team_for_slot(index), "character_id": -1, "ready": is_ready}


# 0-2 sea nomads, 3-5 garbage monsters, 6-7 spectators
func get_default_team_for_slot(index):
	if index <= 2:
		return 0
	if index <= 5:
		return 1
	return 2


# the name of a player (the username from settings)
func get_player_name(peer_id):
	var index = find_slot_by_peer(peer_id)
	if index != -1 and str(slots[index].get("player_name", "")) != "":
		return str(slots[index]["player_name"])
	if multiplayer.multiplayer_peer == null or peer_id == multiplayer.get_unique_id():
		return PlayerProfile.username
	return "Player %d" % peer_id


func find_slot_by_peer(peer_id):
	for i in slots.size():
		if int(slots[i].get("peer_id", 0)) == peer_id:
			return i
	return -1


func set_slot_player(index, peer_id, player_name = ""):
	if multiplayer.multiplayer_peer == null or not multiplayer.is_server():
		return
	if index < 0 or index >= MAX_PLAYERS or peer_id <= 0:
		return
	if slots.size() != MAX_PLAYERS:
		reset_lobby()

	# remove from the old slot first
	var old_index = find_slot_by_peer(peer_id)
	if old_index != -1 and old_index != index:
		clear_slot(old_index)
	slots[index] = _make_slot(index, peer_id, player_name, false)
	sync_lobby()


# host: copy the slots from the lobby screen (keeps who was ready)
func apply_host_snapshot(assigned_slots, names):
	if multiplayer.multiplayer_peer == null or not multiplayer.is_server():
		return

	var was_ready = {}
	for slot in slots:
		var id = int(slot.get("peer_id", 0))
		if id > 0:
			was_ready[id] = bool(slot.get("ready", false))

	reset_lobby()
	for index in assigned_slots:
		var slot_index = int(index)
		var id = int(assigned_slots[index])
		if slot_index < 0 or slot_index >= MAX_PLAYERS or id <= 0:
			continue
		var player_name = str(names.get(id, "Player " + str(id)))
		slots[slot_index] = _make_slot(slot_index, id, player_name, bool(was_ready.get(id, false)))
	sync_lobby()


func clear_slot(index):
	if index < 0 or index >= MAX_PLAYERS:
		return
	slots[index] = _make_slot(index, 0, "", false)
	lobby_updated.emit()


func remove_player(peer_id):
	if not multiplayer.is_server():
		return
	var index = find_slot_by_peer(peer_id)
	if index != -1:
		clear_slot(index)
		sync_lobby()


func reset_ready_states():
	if not multiplayer.is_server():
		return
	for slot in slots:
		slot["ready"] = false
	sync_lobby()


func sync_lobby():
	if not multiplayer.is_server():
		return
	_receive_lobby.rpc(slots.duplicate(true))


@rpc("authority", "call_remote", "reliable")
func _receive_lobby(new_slots: Array):
	slots.clear()
	for slot in new_slots:
		slots.append(slot.duplicate(true))
	lobby_updated.emit()
