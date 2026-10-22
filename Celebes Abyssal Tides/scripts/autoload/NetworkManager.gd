extends Node

const PORT := 7777
const PLAYER_SCENE = preload("res://Celebes Abyssal Tides/scenes/player/player.tscn")

# LAN lobby discovery: joiners broadcast DISCOVERY_ASK to DISCOVERY_PORT and an open
# lobby's host answers with a small JSON description of itself.
const DISCOVERY_PORT := 7778
const DISCOVERY_ASK := "CELEBES_LOBBY?"
var discovery_responder: PacketPeerUDP = null # host only, while its lobby is open
var lobby_id := "" # random per hosted lobby, lets joiners merge duplicate replies

func _ready() -> void:
	var config := ConfigFile.new()
	if config.load("user://keybinds.cfg") == OK:
		for action in ["move_up", "move_down", "move_left", "move_right", "dash"]:
			var saved: Array = config.get_value("hotkeys", action, [])
			if not saved.is_empty():
				InputMap.action_erase_events(action)
				for event in saved:
					InputMap.action_add_event(action, event)
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

func _on_peer_connected(id: int) -> void:
	print("Peer connected: ", id)
	# Player spawning belongs to Stage 7, inside Arena only.
	# Never spawn while the current scene is the Main Menu or PvP Lobby.
	if not multiplayer.is_server():
		return
	var scene := get_tree().current_scene
	if scene == null or scene.name != "Arena":
		return
	var container := scene.get_node_or_null("Players")
	if container == null:
		return
	# Arena player spawning is Stage 7 work; do not spawn from a global callback
	# until scene replication and player authority are implemented.

func _on_peer_disconnected(id: int) -> void:
	print("Peer disconnected: ", id)
	if multiplayer.multiplayer_peer != null and multiplayer.is_server():
		LobbyManager.remove_player(id)
		CharacterSelectManager.selections.erase(id)
		CharacterSelectManager.locked.erase(id)
		var peer_slots: Dictionary = CharacterSelectManager.get_meta("peer_slots", {})
		peer_slots.erase(id)
		CharacterSelectManager.set_meta("peer_slots", peer_slots)
		CharacterSelectManager._sync_state()

func host_game() -> bool:
	close_connection()
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(PORT, 8)
	if err != OK:
		push_error("HOST failed (port %d): %s" % [PORT, error_string(err)])
		return false
	multiplayer.multiplayer_peer = peer
	print("Hosting on port ", PORT)
	start_discovery_responder()
	return true

func join_game(ip: String) -> bool:
	var address := ip.strip_edges()
	# Reject placeholder text, accidental port suffixes, and malformed addresses.
	if address.is_empty() or address.to_lower() == "localhost":
		address = "127.0.0.1"
	if address.contains(":"):
		push_error("JOIN: Enter an IP only (no :port): [%s]" % address)
		return false
	if not address.is_valid_ip_address():
		push_error("JOIN: Invalid IP address: [%s]. For two windows on this PC use 127.0.0.1" % address)
		return false
	close_connection()
	var peer := ENetMultiplayerPeer.new()
	print("JOIN: Connecting to [%s] on UDP port %d" % [address, PORT])
	var err := peer.create_client(address, PORT)
	if err != OK:
		push_error("JOIN failed: %s (IP [%s], port %d)" % [error_string(err), address, PORT])
		return false
	multiplayer.multiplayer_peer = peer
	return true

func close_connection() -> void:
	stop_discovery_responder()
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null

# LAN DISCOVERY (host side)
# The host listens while its lobby is open so joiners can list it.
# Stopped when the match leaves the lobby or the connection closes.
func start_discovery_responder() -> void:
	stop_discovery_responder()
	lobby_id = str(randi())
	discovery_responder = PacketPeerUDP.new()
	var err := discovery_responder.bind(DISCOVERY_PORT)
	if err != OK:
		push_warning("LAN discovery off, port %d busy: %s" % [DISCOVERY_PORT, error_string(err)])
		discovery_responder = null


func stop_discovery_responder() -> void:
	if discovery_responder != null:
		discovery_responder.close()
		discovery_responder = null


func _process(_delta: float) -> void:
	if discovery_responder == null:
		return
	while discovery_responder.get_available_packet_count() > 0:
		var message := discovery_responder.get_packet().get_string_from_utf8()
		var ip := discovery_responder.get_packet_ip()
		var port := discovery_responder.get_packet_port()
		if message != DISCOVERY_ASK or multiplayer.multiplayer_peer == null:
			continue
		var info := {
			"game": "celebes",
			"id": lobby_id,
			"name": PlayerProfile.username,
			"players": multiplayer.get_peers().size() + 1,
			"max": LobbyManager.MAX_PLAYERS,
		}
		discovery_responder.set_dest_address(ip, port)
		discovery_responder.put_packet(JSON.stringify(info).to_utf8_buffer())


func _spawn_player(id: int, container: Node) -> void:
	if container.has_node(str(id)):
		return
	var player := PLAYER_SCENE.instantiate()
	player.name = str(id)
	container.add_child(player, true)
