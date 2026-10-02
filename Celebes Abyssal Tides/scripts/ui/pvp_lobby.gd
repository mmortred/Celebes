extends Control
## res://Celebes Abyssal Tides/scripts/ui/pvp_lobby.gd
## Scene: scenes/ui/lobby/PvPLobby.tscn  (root must sit at /root/PvPLobby on every peer)
##
## STANDALONE: depends on no autoload and no other script.
## The lobby never creates a peer. MainMenu does that (NetworkManager.host_game / join_game).
## F6 on this scene alone -> OfflineMultiplayerPeer -> acts as a UI-only host.

# --------------------------------------------------------------------------- config
const MAX_SLOTS := 8                       # 0-2 Sea Nomads, 3-5 Monsters, 6-7 Spectators
const HOST_ID := 1
const MAX_NAME_LEN := 24

const MAIN_MENU_PATH := "res://Celebes Abyssal Tides/scenes/ui/menus/MainMenu.tscn"
const CHARACTER_SELECT_PATH := "res://Celebes Abyssal Tides/scenes/ui/menus/CharacterSelect.tscn"

const SLOT_PATHS := [
	"SeaNomads/SeaNomadSlot_0",
	"SeaNomads/SeaNomadSlot_1",
	"SeaNomads/SeaNomadSlot_2",
	"GarbageMonsters/MonsterSlot_3",
	"GarbageMonsters/MonsterSlot_4",
	"GarbageMonsters/MonsterSlot_5",
	"Spectators/Spectator_6",
	"Spectators/Spectator_7",
]
const BUTTON_PATHS := ["ReadyButton", "UnreadyButton", "StartButton", "BackButton"]
const HOST_IP_LABEL_PATH := "Spectators/HostIpLabel"
## Decorative nodes: only checked for existence (warning), NEVER modified.
const DECORATIVE_PATHS := [
	"Transition", "LobbyBackground",
	"SeaNomads/NomadsBanner", "SeaNomads/SeaNomadLabel",
	"GarbageMonsters/MonstersBanner", "GarbageMonsters/MonstersLabel",
	"Spectators/SpectatorLabel",
]

const ICON_ACTIVE := Color(1, 1, 1, 1.0)       # host, or ready client
const ICON_NOT_READY := Color(1, 1, 1, 0.5)    # client who is not ready
const ICON_EMPTY := Color(1, 1, 1, 0.2)        # empty slot

# --------------------------------------------------------------------------- state
## slot index (int) -> { "peer_id": int, "name": String, "ready": bool }
## Authoritative on the server, mirrored to clients via sync_all_slots.
var slots: Dictionary = {}
var _leaving := false

var _slot_nodes: Array[Control] = []
var _name_labels: Array[Label] = []
var _icons: Array[CanvasItem] = []
var _ready_btn: BaseButton
var _unready_btn: BaseButton
var _start_btn: BaseButton
var _back_btn: BaseButton
var _host_ip_label: Label


# =========================================================================== setup
func _ready() -> void:
	if not _validate_scene():
		_disable_buttons()
		return
	_cache_nodes()
	_connect_ui()

	if multiplayer.multiplayer_peer == null:
		multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()

	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)

	if multiplayer.is_server():
		_assign(HOST_ID, _local_name())
		# Peers that connected while MainMenu was still the active scene.
		for id in multiplayer.get_peers():
			if not _assign(id, ""):
				multiplayer.multiplayer_peer.disconnect_peer(id)
		_broadcast()
	elif multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		_on_connected_to_server()

	_update_ip_label()
	_refresh_ui()


func _validate_scene() -> bool:
	var ok := true

	for p in BUTTON_PATHS:
		var n := get_node_or_null(p)
		if n == null:
			_err("Missing node: %s" % p); ok = false
		elif not (n is BaseButton):
			_err("%s must be a Button type, is %s" % [p, n.get_class()]); ok = false

	var ip := get_node_or_null(HOST_IP_LABEL_PATH)
	if ip == null:
		_err("Missing node: %s" % HOST_IP_LABEL_PATH); ok = false
	elif not (ip is Label):
		_err("%s must be a Label, is %s" % [HOST_IP_LABEL_PATH, ip.get_class()]); ok = false

	for p in SLOT_PATHS:
		var raw := get_node_or_null(p)
		if raw == null:
			_err("Missing slot: %s" % p); ok = false; continue
		if not (raw is Control):
			_err("Slot %s must be a Control, is %s" % [p, raw.get_class()]); ok = false; continue

		var name_lbl := raw.find_child("PlayerNameLabel", true, false)
		if name_lbl == null:
			_err("Slot %s has no PlayerNameLabel" % p); ok = false
		elif not (name_lbl is Label):
			_err("Slot %s: PlayerNameLabel must be a Label, is %s" % [p, name_lbl.get_class()]); ok = false

		var icon := raw.find_child("PlayerIcon", true, false)
		if icon == null:
			_err("Slot %s has no PlayerIcon" % p); ok = false
		elif not (icon is CanvasItem):
			_err("Slot %s: PlayerIcon must be a CanvasItem, is %s" % [p, icon.get_class()]); ok = false

		var slot_ctrl := raw as Control
		if slot_ctrl.mouse_filter == Control.MOUSE_FILTER_IGNORE:
			_err("Slot %s has mouse_filter = Ignore, so it can never be clicked" % p); ok = false
		if not (raw is BaseButton):
			_warn("Slot %s root is %s, not a button. Using gui_input fallback." % [p, raw.get_class()])
		var blockers: Array[Control] = []
		_collect_stop_controls(raw, blockers)
		for b in blockers:
			_warn("Slot %s: child '%s' has mouse_filter = Stop and may swallow clicks (set Pass or Ignore)" % [p, raw.get_path_to(b)])

	for p in DECORATIVE_PATHS:
		if get_node_or_null(p) == null:
			_warn("Decorative node not found: %s" % p)

	if ok:
		print("[PvPLobby] Scene validation passed.")
	return ok


func _collect_stop_controls(node: Node, out: Array[Control]) -> void:
	for c in node.get_children():
		var ctrl := c as Control
		if ctrl != null and ctrl.mouse_filter == Control.MOUSE_FILTER_STOP:
			out.append(ctrl)
		_collect_stop_controls(c, out)


func _cache_nodes() -> void:
	_ready_btn = get_node("ReadyButton") as BaseButton
	_unready_btn = get_node("UnreadyButton") as BaseButton
	_start_btn = get_node("StartButton") as BaseButton
	_back_btn = get_node("BackButton") as BaseButton
	_host_ip_label = get_node(HOST_IP_LABEL_PATH) as Label
	for p in SLOT_PATHS:
		var slot: Control = get_node(p) as Control
		_slot_nodes.append(slot)
		_name_labels.append(slot.find_child("PlayerNameLabel", true, false) as Label)
		_icons.append(slot.find_child("PlayerIcon", true, false) as CanvasItem)


func _connect_ui() -> void:
	_ready_btn.pressed.connect(_on_ready_pressed)
	_unready_btn.pressed.connect(_on_unready_pressed)
	_start_btn.pressed.connect(_on_start_pressed)
	_back_btn.pressed.connect(_on_back_pressed)
	for i in _slot_nodes.size():
		var slot := _slot_nodes[i]
		if slot is BaseButton:
			(slot as BaseButton).pressed.connect(_on_slot_clicked.bind(i))
		else:
			slot.gui_input.connect(_on_slot_gui_input.bind(i))


func _disable_buttons() -> void:
	for p in BUTTON_PATHS:
		var b := get_node_or_null(p) as BaseButton
		if b != null:
			b.disabled = true


# =========================================================================== helpers
func _err(msg: String) -> void:
	push_error("[PvPLobby] " + msg)


func _warn(msg: String) -> void:
	push_warning("[PvPLobby] " + msg)


## LATER: return GameManager.player_name once GameManager exists.
func _local_name() -> String:
	return ""


func _clean_name(raw: String) -> String:
	return raw.strip_edges().left(MAX_NAME_LEN)


func _display_name(entry: Dictionary) -> String:
	var n: String = entry["name"]
	if n != "":
		return n
	return "Player " + str(entry["peer_id"])


func _slot_of(id: int) -> int:
	for k in slots:
		if int(slots[k]["peer_id"]) == id:
			return int(k)
	return -1


func _first_empty() -> int:
	for i in MAX_SLOTS:
		if not slots.has(i):
			return i
	return -1


func _has_remote_peers() -> bool:
	return not multiplayer.get_peers().is_empty()


## LATER: move to NetworkManager.
func _get_local_ip() -> String:
	var fallback := ""
	for a in IP.get_local_addresses():
		if a.contains(":"):
			continue  # skip IPv6
		if a.begins_with("127.") or a.begins_with("169.254."):
			continue
		if a.begins_with("192.168.") or a.begins_with("10."):
			return a
		if a.begins_with("172."):
			var parts := a.split(".")
			if parts.size() > 1 and parts[1].is_valid_int():
				var second := int(parts[1])
				if second >= 16 and second <= 31:
					return a
		if fallback == "":
			fallback = a
	return fallback if fallback != "" else "127.0.0.1"


func _get_server_address() -> String:
	var enet := multiplayer.multiplayer_peer as ENetMultiplayerPeer
	if enet != null:
		var pp := enet.get_peer(HOST_ID)
		if pp != null:
			return pp.get_remote_address()
	return ""


func _update_ip_label() -> void:
	if multiplayer.is_server():
		_host_ip_label.text = "IP: " + _get_local_ip()
	else:
		var addr := _get_server_address()
		_host_ip_label.text = "CONNECTED TO " + (addr if addr != "" else "HOST")


# =========================================================================== UI refresh
func _refresh_ui() -> void:
	for i in MAX_SLOTS:
		if slots.has(i):
			var e: Dictionary = slots[i]
			_name_labels[i].text = _display_name(e)
			var dim: bool = int(e["peer_id"]) != HOST_ID and not bool(e["ready"])
			_icons[i].modulate = ICON_NOT_READY if dim else ICON_ACTIVE
		else:
			_name_labels[i].text = "Empty"
			_icons[i].modulate = ICON_EMPTY

	var is_host := multiplayer.is_server()
	_start_btn.visible = is_host
	_back_btn.visible = true

	if is_host:
		_ready_btn.visible = false
		_unready_btn.visible = false
		_start_btn.disabled = _leaving or not _can_start()
	else:
		var my_slot := _slot_of(multiplayer.get_unique_id())
		var am_ready := false
		if my_slot != -1:
			am_ready = bool(slots[my_slot]["ready"])
		_ready_btn.visible = not am_ready
		_unready_btn.visible = am_ready
		_ready_btn.disabled = my_slot == -1 or _leaving
		_unready_btn.disabled = my_slot == -1 or _leaving


## Start needs every non-host player ready. Host alone -> allowed.
func _can_start() -> bool:
	for k in slots:
		var e: Dictionary = slots[k]
		if int(e["peer_id"]) != HOST_ID and not bool(e["ready"]):
			return false
	return true


# =========================================================================== input
func _on_slot_gui_input(event: InputEvent, index: int) -> void:
	var mb := event as InputEventMouseButton
	if mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		_on_slot_clicked(index)


func _on_slot_clicked(index: int) -> void:
	if _leaving or slots.has(index):
		return  # only empty slots are clickable
	if multiplayer.is_server():
		_server_move(HOST_ID, index, _clean_name(_local_name()))
	else:
		request_slot_change.rpc_id(HOST_ID, index, multiplayer.get_unique_id(), _local_name())


func _on_ready_pressed() -> void:
	request_ready.rpc_id(HOST_ID, true)


func _on_unready_pressed() -> void:
	request_ready.rpc_id(HOST_ID, false)


func _on_start_pressed() -> void:
	if not multiplayer.is_server() or not _can_start():
		return
	if _has_remote_peers():
		start_game.rpc()
	else:
		start_game()


func _on_back_pressed() -> void:
	_leave(true)


# =========================================================================== multiplayer signals
func _on_peer_connected(id: int) -> void:
	if not multiplayer.is_server() or _leaving:
		return
	if _assign(id, ""):
		_broadcast()
	else:
		multiplayer.multiplayer_peer.disconnect_peer(id)  # lobby full


func _on_peer_disconnected(id: int) -> void:
	if not multiplayer.is_server() or _leaving:
		return
	var s := _slot_of(id)
	if s != -1:
		slots.erase(s)
		_broadcast()


func _on_connected_to_server() -> void:
	request_join.rpc_id(HOST_ID, _local_name())
	_update_ip_label()
	_refresh_ui()


func _on_server_disconnected() -> void:
	_leave()


# =========================================================================== server logic
## Returns false if the lobby is full. Idempotent: a peer that already has a slot keeps it.
func _assign(id: int, player_name: String) -> bool:
	var s := _slot_of(id)
	if s != -1:
		if player_name != "":
			slots[s]["name"] = player_name
		return true
	var free := _first_empty()
	if free == -1:
		return false
	slots[free] = {"peer_id": id, "name": player_name, "ready": false}
	return true


func _server_move(id: int, target: int, new_name: String) -> void:
	if target < 0 or target >= MAX_SLOTS or slots.has(target):
		return
	var old := _slot_of(id)
	if old == -1:
		return
	var entry: Dictionary = slots[old]
	if new_name != "":
		entry["name"] = new_name
	slots.erase(old)       # clear old slot first -> strictly one slot per player
	slots[target] = entry
	_broadcast()


func _broadcast() -> void:
	_refresh_ui()
	if multiplayer.is_server() and _has_remote_peers():
		sync_all_slots.rpc(slots)


# =========================================================================== RPCs
## LATER: move this block to LobbyManager.

## Client -> server. Fixes the race where the server's first sync arrives before this scene exists.
@rpc("any_peer", "call_remote", "reliable")
func request_join(player_name: String) -> void:
	if not multiplayer.is_server() or _leaving:
		return
	var id := multiplayer.get_remote_sender_id()
	if _assign(id, _clean_name(player_name)):
		_broadcast()
	else:
		multiplayer.multiplayer_peer.disconnect_peer(id)


@rpc("any_peer", "call_remote", "reliable")
func request_slot_change(target_slot: int, peer_id: int, player_name: String) -> void:
	if not multiplayer.is_server() or _leaving:
		return
	var sender := multiplayer.get_remote_sender_id()
	if peer_id != sender:
		return  # spoofed id
	_server_move(sender, target_slot, _clean_name(player_name))


@rpc("any_peer", "call_remote", "reliable")
func request_ready(value: bool) -> void:
	if not multiplayer.is_server() or _leaving:
		return
	var id := multiplayer.get_remote_sender_id()
	var s := _slot_of(id)
	if s == -1 or id == HOST_ID:
		return
	slots[s]["ready"] = value
	_broadcast()


## Server -> clients: full slot map (late joiners get the exact lobby state).
@rpc("authority", "call_remote", "reliable")
func sync_all_slots(data: Dictionary) -> void:
	slots = data
	_refresh_ui()


@rpc("authority", "call_remote", "reliable")
func host_closed_lobby() -> void:
	_leave.call_deferred()


@rpc("authority", "call_local", "reliable")
func start_game() -> void:
	print("[PvPLobby] start_game received (scene change not linked yet).")
	# LINK POINT: uncomment once CharacterSelect.tscn exists.
	# get_tree().change_scene_to_file("res://Celebes Abyssal Tides/scenes/ui/menus/CharacterSelect.tscn")


# =========================================================================== leaving
func _leave(notify_peers: bool = false) -> void:
	if _leaving:
		return
	_leaving = true
	_disable_buttons()

	if notify_peers and multiplayer.is_server() and _has_remote_peers():
		host_closed_lobby.rpc()
		await get_tree().create_timer(0.25).timeout  # let the reliable packet flush

	## LATER: move to NetworkManager.close_connection().
	var peer := multiplayer.multiplayer_peer
	if peer != null and not (peer is OfflineMultiplayerPeer):
		peer.close()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	_go_to_main_menu()


func _go_to_main_menu() -> void:
	# LINK POINT: uncomment once MainMenu.tscn exists, and delete the quit line.
	# get_tree().change_scene_to_file("res://Celebes Abyssal Tides/scenes/ui/menus/MainMenu.tscn")
	get_tree().quit()
