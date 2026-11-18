extends Control

var occupant_peer_id = -1 # -1 = nobody


func is_empty():
	return occupant_peer_id == -1


func occupy_slot(peer_id):
	occupant_peer_id = peer_id
	$SlotLayout/PlayerNameLabel.text = "Player " + str(peer_id)
	$SlotLayout/PlayerIcon.visible = true


func clear_slot():
	occupant_peer_id = -1
	$SlotLayout/PlayerNameLabel.text = "EMPTY"
	$SlotLayout/PlayerIcon.visible = false
