extends Node

const PORT = 7777
@onready var player_scene = preload("res://scenes/player/player.tscn")

func _ready(): ##remove later, just for quick LAN testing
	multiplayer.peer_connected.connect(func(id): print("Peer connected: ", id))
	multiplayer.peer_disconnected.connect(func(id): print("Peer disconnected: ", id))
	multiplayer.peer_connected.connect(_on_peer_connected)

func _on_peer_connected(id):
	if not multiplayer.is_server():
		return  # only the server ever spawns players
	if not get_tree().current_scene.get_node("Players").has_node("1"):
		_spawn_player(1)
	_spawn_player(id)

func host_game():
	var peer = ENetMultiplayerPeer.new()
	peer.create_server(PORT)
	multiplayer.multiplayer_peer = peer
	print("Hosting on port ", PORT)

func join_game(ip: String):
	var peer = ENetMultiplayerPeer.new()
	peer.create_client(ip, PORT)
	multiplayer.multiplayer_peer = peer
	print("Joining ", ip)

func _spawn_player(id):
	if not multiplayer.is_server():
		return
	var player = player_scene.instantiate()
	player.name = str(id)
	var players_container = get_tree().current_scene.get_node("Players")
	players_container.add_child(player)
