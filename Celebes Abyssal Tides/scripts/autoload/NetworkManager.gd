extends Node

signal peer_joined(peer_id)
signal peer_left(peer_id)
signal connected_to_server
signal connection_failed
signal server_disconnected

const GAME_PORT = 7777

var peer: ENetMultiplayerPeer
var is_host := false

func host_game():
	peer = ENetMultiplayerPeer.new()

	var error = peer.create_server(GAME_PORT, 7)

	if error != OK:
		print("Failed to host.")
		return

	multiplayer.multiplayer_peer = peer
	is_host = true

func join_game(ip_address: String):
	peer = ENetMultiplayerPeer.new()

	var error = peer.create_client(ip_address, GAME_PORT)

	if error != OK:
		print("Failed to connect.")
		return

	multiplayer.multiplayer_peer = peer
	is_host = false

func disconnect_game():
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	peer = null
	is_host = false
