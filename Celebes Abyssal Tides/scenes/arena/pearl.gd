extends Node2D

@onready var collect_area: Area2D = $CollectArea

var carrier_name = "" # name of the player holding the pearl, "" = still on the ground


func _ready() -> void:
	add_to_group("pearl") # so the carrier can find me when they die
	collect_area.body_entered.connect(_on_body_entered)


func _on_body_entered(body):
	if not multiplayer.is_server(): # only the server decides who got it, so two players can't both grab it
		return
	if carrier_name != "":
		return
	if not body.is_in_group("players") or body.is_dead:
		return
	collected.rpc(str(body.name))


@rpc("authority", "call_local", "reliable") # server tells every peer who picked it up
func collected(player_name):
	carrier_name = player_name
	visible = false
	collect_area.set_deferred("monitoring", false) # stop detecting while someone carries it
	for player in get_tree().get_nodes_in_group("players"): # turn the name back into the player node
		if str(player.name) == player_name:
			player.set_has_pearl(true)


@rpc("authority", "call_local", "reliable") # server tells every peer where it fell
func dropped(drop_position: Vector2):
	for player in get_tree().get_nodes_in_group("players"):
		if str(player.name) == carrier_name:
			player.set_has_pearl(false)
	carrier_name = ""
	global_position = drop_position
	visible = true
	collect_area.set_deferred("monitoring", true) # can be picked up again (dead players are ignored)


func scored():
	pass
