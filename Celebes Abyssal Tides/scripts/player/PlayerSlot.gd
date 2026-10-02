extends Control

var occupant_peer_id: int = -1

func is_empty() -> bool:
	return occupant_peer_id == -1

func occupy_slot(peer_id: int) -> void:
	occupant_peer_id = peer_id
	$SlotLayout/PlayerNameLabel.text = "Player " + str(peer_id)
	$SlotLayout/PlayerIcon.visible = true

func clear_slot() -> void:
	occupant_peer_id = -1
	$SlotLayout/PlayerNameLabel.text = "EMPTY"
	$SlotLayout/PlayerIcon.visible = false
