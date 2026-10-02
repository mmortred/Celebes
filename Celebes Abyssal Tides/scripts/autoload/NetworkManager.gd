extends Node

signal host_started
signal connected_to_host
signal connection_failed
signal connection_closed

const PORT := 7777
const MAX_CLIENTS := 7 # host + 7 = 8 total lobby positions

func _ready() -> void:
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func host_game() -> Error:
	close_connection()
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(PORT, MAX_CLIENTS)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = peer
	host_started.emit()
	return OK

func join_game(ip: String) -> Error:
	close_connection()
	var clean_ip := ip.strip_edges()
	if clean_ip.is_empty():
		return ERR_INVALID_PARAMETER
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(clean_ip, PORT)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = peer
	return OK

func close_connection() -> void:
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = null

func get_local_ipv4() -> String:
	for address in IP.get_local_addresses():
		if address.contains(".") and not address.begins_with("127.") and not address.begins_with("169.254."):
			return address
	return "127.0.0.1"

func _on_connected_to_server() -> void:
	connected_to_host.emit()

func _on_connection_failed() -> void:
	close_connection()
	connection_failed.emit()

func _on_server_disconnected() -> void:
	close_connection()
	connection_closed.emit()
