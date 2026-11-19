extends Node

# hosting, joining, and finding lobbies on the same network (LAN)

const PORT = 7777

# for finding lobbies on the same network
const DISCOVERY_PORT = 7778
const DISCOVERY_ASK = "CELEBES_LOBBY?"

const MAIN_MENU = "res://Celebes Abyssal Tides/scenes/MainMenu.tscn"
const LOBBY = "res://Celebes Abyssal Tides/scenes/ui/lobby/PvPLobby.tscn"

var discovery_responder = null # host only, while the lobby is open
var lobby_id = "" # random number for each lobby so the joiner doesnt list it twice
var join_error = "" # why i got sent back to the main menu (lobby full, kicked), the main menu shows it


func _ready():
	# load the saved keys (same as settings_panel.gd)
	var config = ConfigFile.new()
	if config.load("user://keybinds.cfg") == OK:
		for action in ["move_up", "move_down", "move_left", "move_right", "dash"]:
			var saved = config.get_value("hotkeys", action, [])
			if not saved.is_empty():
				InputMap.action_erase_events(action)
				for event in saved:
					InputMap.action_add_event(action, event)

	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


# client: the host left after the lobby (character select, loading, arena)
# so go back to the main menu. the lobby handles this by itself
func _on_server_disconnected():
	var scene = get_tree().current_scene
	if scene != null and scene.name == "PvPLobby":
		return
	print("Host disconnected, back to main menu")
	close_connection()
	get_tree().change_scene_to_file(MAIN_MENU)


func _on_peer_connected(id):
	print("Peer connected: ", id)
	if multiplayer.multiplayer_peer == null or not multiplayer.is_server():
		return
	# host: nobody can come in if the lobby is full or the match already started
	var scene = get_tree().current_scene
	if scene == null or scene.name != "PvPLobby":
		send_away(id, "The match already started.")
	elif multiplayer.get_peers().size() > LobbyManager.MAX_PLAYERS - 1: # -1 because the host has a slot too
		send_away(id, "The lobby is full.")


# host: tell them why, then disconnect them (lobby full, match started, kicked)
func send_away(id, reason):
	print("Sending away peer ", id, ": ", reason)
	leave_with_message.rpc_id(id, reason)
	await get_tree().create_timer(0.5).timeout # so the message gets there first
	if multiplayer.multiplayer_peer != null and id in multiplayer.get_peers():
		multiplayer.multiplayer_peer.disconnect_peer(id)


# host -> one client: you have to leave, back to the main menu with the reason
@rpc("authority", "call_remote", "reliable")
func leave_with_message(reason: String):
	join_error = reason
	close_connection()
	get_tree().change_scene_to_file(MAIN_MENU)


# the new host after a host transfer (see pvp_lobby.gd move_host)
func become_host_after(delay):
	await get_tree().create_timer(delay).timeout
	LobbyManager.reset_lobby() # the old slots are from the old host
	if host_game():
		get_tree().change_scene_to_file(LOBBY)
	else:
		join_error = "Could not become the host (port %d busy)." % PORT
		get_tree().change_scene_to_file(MAIN_MENU)


# everyone else after a host transfer: wait for the new host to open the lobby, then join it
func rejoin_after(ip, delay):
	await get_tree().create_timer(delay).timeout
	if not join_game(ip):
		join_error = "Could not join the new host."
		get_tree().change_scene_to_file(MAIN_MENU)
		return
	var waited = 0.0
	while waited < 8.0:
		if multiplayer.multiplayer_peer == null:
			break
		if multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
			get_tree().change_scene_to_file(LOBBY)
			return
		await get_tree().create_timer(0.25).timeout
		waited += 0.25
	close_connection()
	join_error = "Could not join the new host."
	get_tree().change_scene_to_file(MAIN_MENU)


func _on_peer_disconnected(id):
	print("Peer disconnected: ", id)
	if multiplayer.multiplayer_peer == null or not multiplayer.is_server():
		return
	# remove them from the lobby and from character select
	LobbyManager.remove_player(id)
	CharacterSelectManager.selections.erase(id)
	CharacterSelectManager.locked.erase(id)
	var peer_slots = CharacterSelectManager.get_meta("peer_slots", {})
	peer_slots.erase(id)
	CharacterSelectManager.set_meta("peer_slots", peer_slots)
	CharacterSelectManager._sync_state()


func host_game():
	close_connection()
	var peer = ENetMultiplayerPeer.new()
	var err = peer.create_server(PORT, 8)
	if err != OK:
		push_error("HOST failed (port %d): %s" % [PORT, error_string(err)])
		return false
	multiplayer.multiplayer_peer = peer
	print("Hosting on port ", PORT)
	start_discovery_responder()
	return true


func join_game(ip):
	var address = ip.strip_edges()
	if address.is_empty() or address.to_lower() == "localhost":
		address = "127.0.0.1"
	if address.contains(":"):
		push_error("JOIN: Enter an IP only (no :port): [%s]" % address)
		return false
	if not address.is_valid_ip_address():
		push_error("JOIN: Invalid IP address: [%s]. For two windows on this PC use 127.0.0.1" % address)
		return false

	close_connection()
	var peer = ENetMultiplayerPeer.new()
	print("JOIN: Connecting to [%s] on UDP port %d" % [address, PORT])
	var err = peer.create_client(address, PORT)
	if err != OK:
		push_error("JOIN failed: %s (IP [%s], port %d)" % [error_string(err), address, PORT])
		return false
	multiplayer.multiplayer_peer = peer
	return true


func close_connection():
	stop_discovery_responder()
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null


# host: start answering the joiners while the lobby is open
func start_discovery_responder():
	stop_discovery_responder()
	lobby_id = str(randi())
	discovery_responder = PacketPeerUDP.new()
	var err = discovery_responder.bind(DISCOVERY_PORT)
	if err != OK:
		push_warning("LAN discovery off, port %d busy: %s" % [DISCOVERY_PORT, error_string(err)])
		discovery_responder = null


func stop_discovery_responder():
	if discovery_responder != null:
		discovery_responder.close()
		discovery_responder = null


func _process(_delta):
	if discovery_responder == null:
		return
	while discovery_responder.get_available_packet_count() > 0:
		var message = discovery_responder.get_packet().get_string_from_utf8()
		var ip = discovery_responder.get_packet_ip()
		var port = discovery_responder.get_packet_port()
		if message != DISCOVERY_ASK or multiplayer.multiplayer_peer == null:
			continue
		var info = {
			"game": "celebes",
			"id": lobby_id,
			"name": PlayerProfile.username,
			"players": multiplayer.get_peers().size() + 1,
			"max": LobbyManager.MAX_PLAYERS,
		}
		discovery_responder.set_dest_address(ip, port)
		discovery_responder.put_packet(JSON.stringify(info).to_utf8_buffer())
