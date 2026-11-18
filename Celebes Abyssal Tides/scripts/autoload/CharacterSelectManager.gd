extends Node

# character select for everyone, the host decides everything

signal state_changed
signal selection_rejected(reason)
signal match_loading_requested
signal everyone_in_arena # host only

# characters you can pick. Bajau and Minahasan are still "?"
const PLAYABLE = [0, 3, 4, 5] # Bugis, Plastic Hoard, Rusty Leviathan, Toxic Sludge

# characters without art yet use Toxic Sludge in the arena for now
const STAND_INS = {3: 5, 4: 5} # Plastic Hoard, Rusty Leviathan -> Toxic Sludge

# face icons for character select and the hud (not here = no art yet)
const ICONS = {
	0: {"sheet": "res://Celebes Abyssal Tides/assets/sprite/SeaNomad1/walk down_spear.png", "face": Rect2(20, 12, 24, 24)},
	5: {"sheet": "res://Celebes Abyssal Tides/assets/sprite/GMonster3/monster/sludge walk_down.png", "face": Rect2(10, 2, 44, 44)},
}

const ARENA_SCENE = "res://Celebes Abyssal Tides/scenes/arena/MainArena.tscn"
const LOBBY_SCENE = "res://Celebes Abyssal Tides/scenes/ui/lobby/PvPLobby.tscn"

var selections = {} # peer id -> character id
var locked = {} # peer id -> true if ready
var loading_started = false
var loading_peers = {} # peers that have the loading screen open
var arena_peers = {} # peers that have the arena loaded


func play_as(character_id):
	return int(STAND_INS.get(character_id, character_id))


func get_icon(character_id):
	if not ICONS.has(character_id):
		return null
	var icon = AtlasTexture.new()
	icon.atlas = load(ICONS[character_id].sheet)
	icon.region = ICONS[character_id].face
	return icon


func reset_local():
	selections.clear()
	locked.clear()
	loading_started = false
	loading_peers.clear()
	set_meta("peer_slots", {})
	state_changed.emit()


func request_character(character_id):
	if multiplayer.multiplayer_peer == null:
		# offline test (F6)
		selections[1] = character_id
		state_changed.emit()
		return
	if multiplayer.is_server():
		_host_try_select(multiplayer.get_unique_id(), character_id)
	else:
		request_character_rpc.rpc_id(1, character_id)


func request_character_ready(value):
	if multiplayer.multiplayer_peer == null:
		locked[1] = value
		state_changed.emit()
		return
	if multiplayer.is_server():
		_host_set_ready(multiplayer.get_unique_id(), value)
	else:
		request_ready_rpc.rpc_id(1, value)


# who picked this character, 0 if nobody
func character_owner(character_id):
	for peer_id in selections:
		if int(selections[peer_id]) == character_id:
			return int(peer_id)
	return 0


# what character this peer picked, -1 if none
func selected_by(peer_id):
	return int(selections.get(peer_id, -1))


func is_locked(peer_id):
	if locked.get(peer_id, false):
		return true
	return false


func _slot_for_peer(peer_id):
	# the host uses LobbyManager because thats the real one
	if multiplayer.multiplayer_peer != null and multiplayer.is_server():
		return LobbyManager.find_slot_by_peer(peer_id)
	var peer_slots = get_meta("peer_slots", {})
	return int(peer_slots.get(peer_id, -1))


func register_my_slot(slot):
	if multiplayer.multiplayer_peer == null:
		return
	if multiplayer.is_server():
		_host_register_slot(multiplayer.get_unique_id(), slot)
	else:
		register_slot_rpc.rpc_id(1, slot)


func _host_register_slot(peer_id, slot):
	if slot < 0 or slot >= LobbyManager.MAX_PLAYERS:
		return
	# dont trust the client, check it with the lobby
	if multiplayer.is_server() and LobbyManager.find_slot_by_peer(peer_id) != slot:
		return
	var peer_slots = get_meta("peer_slots", {})
	peer_slots[peer_id] = slot
	set_meta("peer_slots", peer_slots)


@rpc("any_peer", "call_remote", "reliable")
func register_slot_rpc(slot: int):
	if not multiplayer.is_server():
		return
	_host_register_slot(multiplayer.get_remote_sender_id(), slot)


@rpc("any_peer", "call_remote", "reliable")
func request_character_rpc(character_id: int):
	if not multiplayer.is_server():
		return
	_host_try_select(multiplayer.get_remote_sender_id(), character_id)


@rpc("any_peer", "call_remote", "reliable")
func request_ready_rpc(value: bool):
	if not multiplayer.is_server():
		return
	_host_set_ready(multiplayer.get_remote_sender_id(), value)


# checks if the character is on the same team as the slot
func _is_right_team(slot, character_id):
	if slot <= 2 and character_id >= 0 and character_id <= 2:
		return true
	if slot >= 3 and slot <= 5 and character_id >= 3 and character_id <= 5:
		return true
	return false


func _host_try_select(peer_id, character_id):
	if is_locked(peer_id):
		_reject(peer_id, "Unlock before changing character.")
		return
	var slot = _slot_for_peer(peer_id)
	if slot < 0 or slot >= 6:
		_reject(peer_id, "Spectators cannot select characters.")
		return
	if character_id not in PLAYABLE:
		_reject(peer_id, "That character isn't available yet.")
		return
	if not _is_right_team(slot, character_id):
		_reject(peer_id, "That character belongs to the other team.")
		return
	var current_owner = character_owner(character_id)
	if current_owner != 0 and current_owner != peer_id:
		_reject(peer_id, "Character already taken by %s." % LobbyManager.get_player_name(current_owner))
		return

	selections[peer_id] = character_id
	locked[peer_id] = false
	_sync_state()


func _host_set_ready(peer_id, value):
	if _slot_for_peer(peer_id) < 0 or _slot_for_peer(peer_id) >= 6:
		_reject(peer_id, "You are not assigned to an active player slot.")
		return
	if value and selected_by(peer_id) < 0:
		_reject(peer_id, "Select a character first.")
		return
	locked[peer_id] = value
	_sync_state()


func _sync_state():
	sync_state.rpc(selections, locked)
	state_changed.emit()
	_check_all_ready()


@rpc("authority", "call_remote", "reliable")
func sync_state(new_selections: Dictionary, new_locked: Dictionary):
	selections = new_selections.duplicate(true)
	locked = new_locked.duplicate(true)
	state_changed.emit()


func _reject(peer_id, reason):
	if peer_id == multiplayer.get_unique_id():
		selection_rejected.emit(reason)
	else:
		reject_selection.rpc_id(peer_id, reason)


@rpc("authority", "call_remote", "reliable")
func reject_selection(reason: String):
	selection_rejected.emit(reason)


# host only: start loading once every player picked and locked a character
func _check_all_ready():
	if loading_started:
		return
	if multiplayer.multiplayer_peer == null or not multiplayer.is_server():
		return

	var peers = [multiplayer.get_unique_id()]
	for id in multiplayer.get_peers():
		peers.append(id)

	var active_count = 0
	for id in peers:
		var slot = _slot_for_peer(id)
		if slot < 0:
			return # someone has no slot yet, wait
		if slot >= 6:
			continue # spectator
		active_count += 1
		if selected_by(id) < 0 or not is_locked(id):
			return # not ready yet

	if active_count == 0:
		return
	loading_started = true
	loading_peers.clear()
	begin_loading.rpc()


@rpc("authority", "call_local", "reliable")
func begin_loading():
	loading_started = true
	match_loading_requested.emit()
	get_tree().change_scene_to_file("res://Celebes Abyssal Tides/scenes/ui/HUD/LoadingScreen.tscn")


# the loading screen calls this when its ready
func report_loading_ready():
	if multiplayer.multiplayer_peer == null:
		get_tree().change_scene_to_file(ARENA_SCENE)
	elif multiplayer.is_server():
		_record_loading_ready(multiplayer.get_unique_id())
	else:
		loading_ready_rpc.rpc_id(1)


@rpc("any_peer", "call_remote", "reliable")
func loading_ready_rpc():
	if multiplayer.is_server():
		_record_loading_ready(multiplayer.get_remote_sender_id())


# host only: when everyone has the loading screen, everyone goes to the arena
func _record_loading_ready(id):
	if not loading_started:
		return
	if multiplayer.multiplayer_peer == null or not multiplayer.is_server():
		return
	if id != multiplayer.get_unique_id() and id not in multiplayer.get_peers():
		return

	loading_peers[id] = true
	for peer in multiplayer.get_peers():
		if not loading_peers.has(peer):
			return
	if not loading_peers.has(multiplayer.get_unique_id()):
		return

	loading_started = false # so it only sends once
	enter_arena.rpc()


# if anyone presses BACK, everyone goes back to the lobby (and keeps their slots)
func request_back_to_lobby():
	if multiplayer.multiplayer_peer == null:
		get_tree().change_scene_to_file(LOBBY_SCENE)
	elif multiplayer.is_server():
		back_to_lobby.rpc()
	else:
		back_to_lobby_request.rpc_id(1)


@rpc("any_peer", "call_remote", "reliable")
func back_to_lobby_request():
	if multiplayer.is_server():
		back_to_lobby.rpc()


@rpc("authority", "call_local", "reliable")
func back_to_lobby():
	reset_local()
	if multiplayer.is_server():
		LobbyManager.reset_ready_states() # everyone has to ready again
	get_tree().change_scene_to_file(LOBBY_SCENE)


# winner screen: the one who pressed a key goes back to the lobby alone
func leave_match_to_lobby():
	ScoreboardManager._clear_local()
	GameManager.set_state(GameManager.MatchState.LOBBY)
	back_to_lobby()


@rpc("authority", "call_local", "reliable")
func enter_arena():
	arena_peers.clear()
	get_tree().change_scene_to_file(ARENA_SCENE)


# the host only spawns players when every peer has the arena loaded
func report_arena_ready():
	if multiplayer.is_server():
		_record_arena_ready(multiplayer.get_unique_id())
	else:
		arena_ready_rpc.rpc_id(1)


@rpc("any_peer", "call_remote", "reliable")
func arena_ready_rpc():
	if multiplayer.is_server():
		_record_arena_ready(multiplayer.get_remote_sender_id())


func _record_arena_ready(id):
	arena_peers[id] = true
	if not arena_peers.has(multiplayer.get_unique_id()):
		return # host arena not loaded yet
	for peer in multiplayer.get_peers():
		if not arena_peers.has(peer):
			return
	everyone_in_arena.emit()
