extends Node

# Stage 5 multiplayer character-selection authority.
# Character IDs: 0-2 Sea Nomads, 3-5 Garbage Monsters.
# Slots: 0-2 Sea Nomads, 3-5 Garbage Monsters, 6-7 spectators.

signal state_changed
signal selection_rejected(reason: String)
signal match_loading_requested

# Characters that can be picked. Bajau and Minahasan stay locked "?" for now.
const PLAYABLE := [0, 3, 4, 5] # Bugis, Plastic Hoard, Rusty Leviathan, Toxic Sludge

# Picked characters without art yet play as another one in the arena
# (sprite and HUD icon) until theirs is made.
const STAND_INS := {3: 5, 4: 5} # Plastic Hoard, Rusty Leviathan -> Toxic Sludge

func play_as(character_id: int) -> int:
	return int(STAND_INS.get(character_id, character_id))

# Portrait icons, shared by character select and the arena HUD: zoomed-in crops
# of each character's first walk-down frame. Not listed = not made yet ("?").
const ICONS := {
	0: {"sheet": "res://Celebes Abyssal Tides/assets/sprite/SeaNomad1/walk down_spear.png", "face": Rect2(20, 12, 24, 24)},
	5: {"sheet": "res://Celebes Abyssal Tides/assets/sprite/GMonster3/monster/sludge walk_down.png", "face": Rect2(10, 2, 44, 44)},
}

func get_icon(character_id: int) -> Texture2D:
	if not ICONS.has(character_id):
		return null
	var icon := AtlasTexture.new()
	icon.atlas = load(ICONS[character_id].sheet)
	icon.region = ICONS[character_id].face
	return icon

# The arena every match loads (loading screen + transition). MainArena has the
# full map: tile layers, kelp, clam zone, HUD and spawns.
const ARENA_SCENE := "res://Celebes Abyssal Tides/scenes/arena/MainArena.tscn"

var selections: Dictionary = {} # peer_id -> character_id
var locked: Dictionary = {}     # peer_id -> bool

func reset_local() -> void:
	selections.clear()
	locked.clear()
	loading_started = false
	loading_peers.clear()
	set_meta("peer_slots", {})
	state_changed.emit()

func request_character(character_id: int) -> void:
	if multiplayer.multiplayer_peer == null:
		# F6/offline preview mode.
		selections[1] = character_id
		state_changed.emit()
		return
	if multiplayer.is_server():
		_host_try_select(multiplayer.get_unique_id(), character_id)
	else:
		request_character_rpc.rpc_id(1, character_id)

func request_character_ready(value: bool) -> void:
	if multiplayer.multiplayer_peer == null:
		locked[1] = value
		state_changed.emit()
		return
	if multiplayer.is_server():
		_host_set_ready(multiplayer.get_unique_id(), value)
	else:
		request_ready_rpc.rpc_id(1, value)

func character_owner(character_id: int) -> int:
	for peer_id in selections:
		if int(selections[peer_id]) == character_id:
			return int(peer_id)
	return 0

func selected_by(peer_id: int) -> int:
	return int(selections.get(peer_id, -1))

func is_locked(peer_id: int) -> bool:
	return bool(locked.get(peer_id, false))

func _slot_for_peer(peer_id: int) -> int:
	# The host's authoritative LobbyManager is the source of truth.
	if multiplayer.multiplayer_peer != null and multiplayer.is_server():
		return LobbyManager.find_slot_by_peer(peer_id)
	var peer_slots: Dictionary = get_meta("peer_slots", {})
	return int(peer_slots.get(peer_id, -1))

func register_my_slot(slot: int) -> void:
	if multiplayer.multiplayer_peer == null:
		return
	if multiplayer.is_server():
		_host_register_slot(multiplayer.get_unique_id(), slot)
	else:
		register_slot_rpc.rpc_id(1, slot)

func _host_register_slot(peer_id: int, slot: int) -> void:
	if slot < 0 or slot >= LobbyManager.MAX_PLAYERS:
		return
	# Never trust a client-supplied slot: validate against host lobby ownership.
	if multiplayer.is_server() and LobbyManager.find_slot_by_peer(peer_id) != slot:
		return
	var peer_slots: Dictionary = get_meta("peer_slots", {})
	peer_slots[peer_id] = slot
	set_meta("peer_slots", peer_slots)

@rpc("any_peer", "call_remote", "reliable")
func register_slot_rpc(slot: int) -> void:
	if not multiplayer.is_server(): return
	_host_register_slot(multiplayer.get_remote_sender_id(), slot)

@rpc("any_peer", "call_remote", "reliable")
func request_character_rpc(character_id: int) -> void:
	if not multiplayer.is_server(): return
	_host_try_select(multiplayer.get_remote_sender_id(), character_id)

@rpc("any_peer", "call_remote", "reliable")
func request_ready_rpc(value: bool) -> void:
	if not multiplayer.is_server(): return
	_host_set_ready(multiplayer.get_remote_sender_id(), value)

func _host_try_select(peer_id: int, character_id: int) -> void:
	if is_locked(peer_id):
		_reject(peer_id, "Unlock before changing character.")
		return
	var slot := _slot_for_peer(peer_id)
	if slot < 0 or slot >= 6:
		_reject(peer_id, "Spectators cannot select characters.")
		return
	if character_id not in PLAYABLE:
		_reject(peer_id, "That character isn't available yet.")
		return
	var valid_team := (slot <= 2 and character_id >= 0 and character_id <= 2) or (slot >= 3 and slot <= 5 and character_id >= 3 and character_id <= 5)
	if not valid_team:
		_reject(peer_id, "That character belongs to the other team.")
		return
	var current_owner := character_owner(character_id)
	if current_owner != 0 and current_owner != peer_id:
		_reject(peer_id, "Character already taken by %s." % LobbyManager.get_player_name(current_owner))
		return
	selections[peer_id] = character_id
	locked[peer_id] = false
	_sync_state()

func _host_set_ready(peer_id: int, value: bool) -> void:
	if _slot_for_peer(peer_id) < 0 or _slot_for_peer(peer_id) >= 6:
		_reject(peer_id, "You are not assigned to an active player slot.")
		return
	if value and selected_by(peer_id) < 0:
		_reject(peer_id, "Select a character first.")
		return
	locked[peer_id] = value
	_sync_state()

func _sync_state() -> void:
	sync_state.rpc(selections, locked)
	state_changed.emit()
	_check_all_ready()

@rpc("authority", "call_remote", "reliable")
func sync_state(new_selections: Dictionary, new_locked: Dictionary) -> void:
	selections = new_selections.duplicate(true)
	locked = new_locked.duplicate(true)
	state_changed.emit()

func _reject(peer_id: int, reason: String) -> void:
	if peer_id == multiplayer.get_unique_id():
		selection_rejected.emit(reason)
	else:
		reject_selection.rpc_id(peer_id, reason)

@rpc("authority", "call_remote", "reliable")
func reject_selection(reason: String) -> void:
	selection_rejected.emit(reason)

# Stage 6: host alone authorizes the transition, after every connected
# playing peer has selected and locked a unique character.
var loading_started := false

func _check_all_ready() -> void:
	if loading_started or multiplayer.multiplayer_peer == null or not multiplayer.is_server():
		return
	var peers: Array[int] = [multiplayer.get_unique_id()]
	for id in multiplayer.get_peers():
		peers.append(id)
	var active_count := 0
	for id in peers:
		var slot := _slot_for_peer(id)
		if slot < 0:
			return # Wait until every connected peer has an assigned slot.
		if slot >= 6:
			continue # Spectator.
		active_count += 1
		if selected_by(id) < 0 or not is_locked(id):
			return
	if active_count == 0:
		return
	loading_started = true
	loading_peers.clear()
	begin_loading.rpc()

@rpc("authority", "call_local", "reliable")
func begin_loading() -> void:
	loading_started = true
	match_loading_requested.emit()
	get_tree().change_scene_to_file("res://Celebes Abyssal Tides/scenes/ui/HUD/LoadingScreen.tscn")

# Host signals clients only after all of them confirm that LoadingScreen is ready.
var loading_peers: Dictionary = {}
func report_loading_ready() -> void:
	if multiplayer.multiplayer_peer == null:
		get_tree().change_scene_to_file(ARENA_SCENE)
	elif multiplayer.is_server():
		_record_loading_ready(multiplayer.get_unique_id())
	else:
		loading_ready_rpc.rpc_id(1)

@rpc("any_peer", "call_remote", "reliable")
func loading_ready_rpc() -> void:
	if multiplayer.is_server():
		_record_loading_ready(multiplayer.get_remote_sender_id())

func _record_loading_ready(id: int) -> void:
	if not loading_started or multiplayer.multiplayer_peer == null or not multiplayer.is_server():
		return
	if id != multiplayer.get_unique_id() and id not in multiplayer.get_peers():
		return
	loading_peers[id] = true
	for peer in multiplayer.get_peers():
		if not loading_peers.has(peer):
			return
	if not loading_peers.has(multiplayer.get_unique_id()):
		return
	loading_started = false # Avoid sending the arena transition more than once.
	enter_arena.rpc()

# Anyone pressing BACK in character select sends EVERY player back to the lobby
# together (keeping their slots), so nobody is left waiting on a half-empty select.
func request_back_to_lobby() -> void:
	if multiplayer.multiplayer_peer == null:
		get_tree().change_scene_to_file(LOBBY_SCENE)
	elif multiplayer.is_server():
		back_to_lobby.rpc()
	else:
		back_to_lobby_request.rpc_id(1)

@rpc("any_peer", "call_remote", "reliable")
func back_to_lobby_request() -> void:
	if multiplayer.is_server():
		back_to_lobby.rpc()

@rpc("authority", "call_local", "reliable")
func back_to_lobby() -> void:
	reset_local()
	if multiplayer.is_server():
		LobbyManager.reset_ready_states() # everyone readies up again
	get_tree().change_scene_to_file(LOBBY_SCENE)

const LOBBY_SCENE := "res://Celebes Abyssal Tides/scenes/ui/lobby/PvPLobby.tscn"


@rpc("authority", "call_local", "reliable")
func enter_arena() -> void:
	arena_peers.clear()
	get_tree().change_scene_to_file(ARENA_SCENE)


# Stage 7: the host spawns players only once every peer has the arena loaded,
# otherwise a slower peer would miss the spawn. Lives here (not in the arena)
# so a peer that loads faster than the host can't lose its "I'm in" message.
signal everyone_in_arena # host only
var arena_peers: Dictionary = {}

func report_arena_ready() -> void:
	if multiplayer.is_server():
		_record_arena_ready(multiplayer.get_unique_id())
	else:
		arena_ready_rpc.rpc_id(1)

@rpc("any_peer", "call_remote", "reliable")
func arena_ready_rpc() -> void:
	if multiplayer.is_server():
		_record_arena_ready(multiplayer.get_remote_sender_id())

func _record_arena_ready(id: int) -> void:
	arena_peers[id] = true
	if not arena_peers.has(multiplayer.get_unique_id()):
		return # the host's own arena isn't loaded yet; it reports last
	for peer in multiplayer.get_peers():
		if not arena_peers.has(peer):
			return
	everyone_in_arena.emit()
