extends Control

const HOST_ID := 1
const SLOT_CONTAINER_NAMES := ["SeaNomads", "GarbageMonsters", "Spectators"]
const CHARACTER_SELECT := "res://Celebes Abyssal Tides/scenes/ui/menus/CharacterSelect.tscn"
const MAIN_MENU := "res://Celebes Abyssal Tides/scenes/ui/menus/MainMenu.tscn"

@onready var host_ip_label: Label = $TopBar/HostIpLabel
@onready var start_button: Button = $BottomBar/StartButton
@onready var ready_button: Button = $BottomBar/ReadyButton
@onready var back_button: Button = $BackButton
@onready var status_label: Label = $BottomBar/StatusLabel

var all_slots: Array[Button] = []

func _ready() -> void:
	_collect_slots()
	for i in all_slots.size():
		all_slots[i].pressed.connect(_on_slot_pressed.bind(i))

	LobbyManager.lobby_changed.connect(_refresh)
	LobbyManager.start_requested.connect(_open_character_select)
	start_button.pressed.connect(LobbyManager.request_start)
	ready_button.pressed.connect(_toggle_ready)
	back_button.pressed.connect(_leave)

	if multiplayer.is_server():
		LobbyManager.setup_host()
		host_ip_label.text = "HOST IP: " + NetworkManager.get_local_ipv4()
	else:
		host_ip_label.text = "CONNECTED TO HOST"
		LobbyManager.request_join()

	_refresh()

func _collect_slots() -> void:
	for container_name in SLOT_CONTAINER_NAMES:
		var container := get_node(container_name)
		for child in container.get_children():
			if child is Button:
				all_slots.append(child)

func _refresh() -> void:
	for slot_index in all_slots.size():
		var button := all_slots[slot_index]
		var peer_id := LobbyManager.player_in_slot(slot_index)
		var name_label: Label = button.get_node("SlotLayout/PlayerNameLabel")
		var state_label: Label = button.get_node("SlotLayout/StateLabel")

		if peer_id == 0:
			name_label.text = "Empty"
			state_label.text = "CLICK TO JOIN"
			button.disabled = false
		else:
			var data: Dictionary = LobbyManager.players[peer_id]
			name_label.text = str(data.name)
			if LobbyManager.team_for_slot(slot_index) == LobbyManager.TEAM_SPECTATOR:
				state_label.text = "SPECTATOR"
			elif peer_id == HOST_ID:
				state_label.text = "HOST"
			elif bool(data.ready):
				state_label.text = "READY"
			else:
				state_label.text = "NOT READY"
			button.disabled = peer_id != multiplayer.get_unique_id()

	var local := LobbyManager.local_player_data()
	var is_spectator := not local.is_empty() and LobbyManager.team_for_slot(int(local.slot)) == LobbyManager.TEAM_SPECTATOR
	ready_button.visible = not multiplayer.is_server() and not is_spectator
	if not local.is_empty():
		ready_button.text = "UNREADY" if bool(local.ready) else "READY"

	start_button.visible = multiplayer.is_server()
	start_button.disabled = multiplayer.is_server() and not LobbyManager.can_host_start()
	status_label.text = "Waiting for players..." if start_button.disabled else "All players ready."

func _on_slot_pressed(slot: int) -> void:
	LobbyManager.request_slot(slot)

func _toggle_ready() -> void:
	var data := LobbyManager.local_player_data()
	if data.is_empty():
		return
	LobbyManager.set_player_ready

func _leave() -> void:
	NetworkManager.close_connection()
	LobbyManager.reset()
	if ResourceLoader.exists(MAIN_MENU):
		get_tree().change_scene_to_file(MAIN_MENU)

func _open_character_select() -> void:
	if ResourceLoader.exists(CHARACTER_SELECT):
		get_tree().change_scene_to_file(CHARACTER_SELECT)
	else:
		status_label.text = "CharacterSelect.tscn is not implemented yet."
