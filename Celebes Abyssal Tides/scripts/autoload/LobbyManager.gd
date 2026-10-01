extends Node

signal lobby_updated

const MAX_PLAYERS = 8

var slots = []

func _ready():
	reset_lobby()

func reset_lobby():
	slots.clear()

	for i in range(MAX_PLAYERS):
		slots.append({
			"peer_id": 0,
			"player_name": "",
			"team_id": get_default_team_for_slot(i),
			"character_id": -1,
			"ready": false
		})

func get_default_team_for_slot(index):
	if index <= 2:
		return 0              # Sea Nomads

	if index <= 5:
		return 1              # Garbage Monsters

	return 2        
