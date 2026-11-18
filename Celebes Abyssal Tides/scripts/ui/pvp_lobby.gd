extends Control

# slot containers in order: SeaNomads 0-2, GarbageMonsters 3-5, Spectators 6-7
const SLOT_CONTAINER_NAMES = ["SeaNomads", "GarbageMonsters", "Spectators"]

const BORDER_FRAME_PATH = "SlotLayout/BorderFrame"
const NAME_LABEL_PATH = "SlotLayout/PlayerNameLabel"
const ICON_PATH = "SlotLayout/BorderFrame/PlayerIcon"

const SLOT_MINE = Color(0.45, 1.0, 0.95) # my slot, cyan
const SLOT_TAKEN = Color(1, 1, 1)
const SLOT_EMPTY = Color(1, 1, 1, 0.4) # faded
const NAME_READY = Color(0.55, 1.0, 0.55) # green name when ready

const HOST_PEER_ID = 1 # host is always id 1 in godot

@onready var host_ip_label = $HostIpLabel
@onready var start_button = $StartButton
@onready var ready_button = $ReadyButton
@onready var unready_button = $UnreadyButton
@onready var back_button = $BackButton

var all_slots = [] # all slot nodes, all_slots[0] is slot 0
var start_status = null # host only, text under START

# slot number -> peer id, empty slots are not in here
var slots = {}
var player_names = {} # peer id -> name

var got_slots_from_host = false


func _ready():
	collect_slot_nodes()
	connect_buttons()
	connect_slot_clicks()
	setup_role_ui()
	update_slot_labels()
	LobbyManager.lobby_updated.connect(update_slot_labels) # ready flags are in LobbyManager

	if multiplayer.multiplayer_peer == null:
		push_warning("PvP Lobby opened without a network connection")
		return

	if multiplayer.is_server():
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)
		restore_slots_from_lobby_manager() # coming back from character select
		assign_peer_to_first_free_slot(HOST_PEER_ID)
		player_names[HOST_PEER_ID] = PlayerProfile.username
		PlayerProfile.username_changed.connect(_on_local_username_changed)
		NetworkManager.start_discovery_responder() # show the lobby on the network again
		host_send_slots_to_everyone()
	else:
		multiplayer.server_disconnected.connect(_on_server_disconnected)
		ask_host_for_slot()


# host only: put back the players that are still connected in their old slots
func restore_slots_from_lobby_manager():
	var connected = multiplayer.get_peers()
	var count = LobbyManager.slots.size()
	if all_slots.size() < count:
		count = all_slots.size()
	for index in count:
		var peer_id = int(LobbyManager.slots[index].get("peer_id", 0))
		if peer_id == HOST_PEER_ID or peer_id in connected:
			slots[index] = peer_id
			player_names[peer_id] = str(LobbyManager.slots[index].get("player_name", ""))


# client only: the host lobby might not be loaded yet, so ask a few times
func ask_host_for_slot():
	for attempt in 10:
		if got_slots_from_host:
			return
		if not is_inside_tree():
			return
		if multiplayer.multiplayer_peer == null:
			return
		request_join.rpc_id(HOST_PEER_ID, PlayerProfile.username)
		await get_tree().create_timer(0.5).timeout


func collect_slot_nodes():
	for container_name in SLOT_CONTAINER_NAMES:
		var container = get_node_or_null(container_name)
		if container == null:
			push_warning("Slot container not found: " + container_name)
			continue
		for child in container.get_children():
			# skip the banners and labels, real slots have a SlotLayout
			if child.has_node("SlotLayout"):
				all_slots.append(child)


func connect_buttons():
	start_button.pressed.connect(_on_start_button_pressed)
	ready_button.pressed.connect(_on_ready_button_pressed)
	unready_button.pressed.connect(_on_unready_button_pressed)
	back_button.pressed.connect(_on_back_button_pressed)


# make every slot clickable, bind(i) gives the slot number
func connect_slot_clicks():
	for i in all_slots.size():
		var border_frame = all_slots[i].get_node(BORDER_FRAME_PATH)
		border_frame.mouse_filter = Control.MOUSE_FILTER_STOP
		border_frame.gui_input.connect(_on_slot_gui_input.bind(i))


func setup_role_ui():
	if multiplayer.is_server():
		start_button.show()
		back_button.show()
		ready_button.hide()
		unready_button.hide()
		host_ip_label.text = "IP: " + get_local_ipv4()
		# the lobby is 1280x720 scaled to half so the numbers are big
		start_status = Label.new()
		start_status.position = Vector2(340, 612)
		start_status.size = Vector2(600, 28)
		start_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		start_status.add_theme_font_size_override("font_size", 20)
		start_status.add_theme_constant_override("outline_size", 6)
		start_status.add_theme_color_override("font_outline_color", Color.BLACK)
		start_status.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(start_status)
	else:
		start_button.hide()
		back_button.show()
		# ready and unready are on the same spot, only 1 shows at a time
		ready_button.show()
		unready_button.hide()
		host_ip_label.text = "CONNECTED TO HOST"


# get the ip of this pc like 192.168.1.15
func get_local_ipv4():
	for address in IP.get_local_addresses():
		if not address.contains("."):
			continue # ipv6
		if address.begins_with("127."):
			continue # this pc only
		if address.begins_with("169.254."):
			continue # no real network
		return address
	return "127.0.0.1"


# returns the slot of the peer or -1
func find_slot_of_peer(peer_id):
	for slot_number in slots:
		if slots[slot_number] == peer_id:
			return slot_number
	return -1


# returns the first empty slot or -1 if full
func find_first_free_slot():
	for slot_number in all_slots.size():
		if not slots.has(slot_number):
			return slot_number
	return -1


func assign_peer_to_first_free_slot(peer_id):
	if find_slot_of_peer(peer_id) != -1:
		return # 1 slot per player only

	var free_slot = find_first_free_slot()
	if free_slot == -1:
		print("Lobby is full, no slot for peer ", peer_id)
		return

	slots[free_slot] = peer_id


func get_player_name(peer_id):
	return str(player_names.get(peer_id, "Player " + str(peer_id)))


# redraw all the slots (name, frame color, icon, ready)
func update_slot_labels():
	var my_id = 0
	if multiplayer.multiplayer_peer != null:
		my_id = multiplayer.get_unique_id()

	for slot_number in all_slots.size():
		var slot_node = all_slots[slot_number]
		var name_label = slot_node.get_node(NAME_LABEL_PATH)
		var frame = slot_node.get_node(BORDER_FRAME_PATH)
		var icon = slot_node.get_node_or_null(ICON_PATH)

		if not slots.has(slot_number):
			name_label.text = "Empty"
			frame.self_modulate = SLOT_EMPTY
			name_label.modulate = Color(1, 1, 1, 0.6)
			if icon:
				icon.visible = false
			continue

		var peer_id = slots[slot_number]
		if peer_id == my_id:
			name_label.text = get_player_name(peer_id) + " (YOU)"
			frame.self_modulate = SLOT_MINE
		else:
			name_label.text = get_player_name(peer_id)
			frame.self_modulate = SLOT_TAKEN
		if _is_lobby_ready(peer_id):
			name_label.modulate = NAME_READY
		else:
			name_label.modulate = Color.WHITE
		if icon:
			icon.visible = true

	update_start_state()
	update_ready_buttons()


# client only: READY when not ready yet, UNREADY when the host says im ready
func update_ready_buttons():
	if multiplayer.multiplayer_peer == null:
		return
	if multiplayer.is_server():
		return
	var me_ready = _is_lobby_ready(multiplayer.get_unique_id())
	ready_button.visible = not me_ready
	unready_button.visible = me_ready


# names of players that are not ready yet. host has no ready button so the host is always ready
func players_not_ready():
	var waiting = []
	for slot_number in slots:
		var peer_id = slots[slot_number]
		if peer_id != HOST_PEER_ID and not _is_lobby_ready(peer_id):
			waiting.append(get_player_name(peer_id))
	return waiting


func can_start_game():
	if slots.size() < 2:
		return false
	if not players_not_ready().is_empty():
		return false
	return true


# host only: START is faded until everyone is ready
func update_start_state():
	if start_status == null:
		return
	if multiplayer.multiplayer_peer == null or not multiplayer.is_server():
		return

	if can_start_game():
		start_button.disabled = false
		start_button.modulate = Color.WHITE
	else:
		start_button.disabled = true
		start_button.modulate = Color(1, 1, 1, 0.45)

	var waiting = players_not_ready()
	if slots.size() < 2:
		start_status.text = "Waiting for another player to join"
	elif not waiting.is_empty():
		start_status.text = "Waiting for: " + ", ".join(waiting)
	else:
		start_status.text = "Everyone is ready!"


func _is_lobby_ready(peer_id):
	var index = LobbyManager.find_slot_by_peer(peer_id)
	if index == -1:
		return false
	if LobbyManager.slots[index].get("ready", false):
		return true
	return false


# host only: send the slots to everyone then redraw my screen too
func host_send_slots_to_everyone():
	if multiplayer.multiplayer_peer == null or not multiplayer.is_server():
		return
	LobbyManager.apply_host_snapshot(slots, player_names) # character select checks this
	sync_all_slots.rpc(slots, player_names)
	update_slot_labels()


# move a player to another slot if its empty
func host_move_peer_to_slot(peer_id, new_slot):
	if new_slot < 0 or new_slot >= all_slots.size():
		return # not a real slot
	if slots.has(new_slot):
		return # taken

	# remove the old slot first so they only have 1
	var old_slot = find_slot_of_peer(peer_id)
	if old_slot != -1:
		slots.erase(old_slot)

	slots[new_slot] = peer_id
	host_send_slots_to_everyone()


# a client left
func _on_peer_disconnected(peer_id):
	var slot_number = find_slot_of_peer(peer_id)
	if slot_number != -1:
		slots.erase(slot_number)
	player_names.erase(peer_id)
	host_send_slots_to_everyone()


# client -> host: give me a slot
@rpc("any_peer", "call_remote", "reliable")
func request_join(requested_name: String):
	if not multiplayer.is_server():
		return
	var peer_id = multiplayer.get_remote_sender_id()
	assign_peer_to_first_free_slot(peer_id)
	player_names[peer_id] = PlayerProfile.sanitize(requested_name)
	host_send_slots_to_everyone()


# client -> host: i clicked an empty slot
@rpc("any_peer", "call_remote", "reliable")
func request_slot_change(new_slot: int):
	if not multiplayer.is_server():
		return
	var peer_id = multiplayer.get_remote_sender_id()
	host_move_peer_to_slot(peer_id, new_slot)


# host -> clients: here are the slots
@rpc("authority", "call_remote", "reliable")
func sync_all_slots(new_slots: Dictionary, new_names: Dictionary):
	got_slots_from_host = true
	# make sure the keys and values are ints
	slots.clear()
	for key in new_slots:
		slots[int(key)] = int(new_slots[key])
	player_names.clear()
	for key in new_names:
		player_names[int(key)] = str(new_names[key])
	update_slot_labels()


# host -> clients: host left so the lobby is closed
@rpc("authority", "call_remote", "reliable")
func host_closed_lobby():
	disconnect_from_network()
	go_to_main_menu()


# host -> everyone: game is starting
@rpc("authority", "call_local", "reliable")
func open_character_select(authoritative_slots: Dictionary):
	# the slots come with this rpc so we dont need to wait for another update
	var my_slot = int(authoritative_slots.get(multiplayer.get_unique_id(), -1))
	var team = "spectator"
	if my_slot >= 0 and my_slot <= 2:
		team = "sea"
	elif my_slot >= 3 and my_slot <= 5:
		team = "garbage"
	NetworkManager.set_meta("character_select_slot", my_slot)
	NetworkManager.set_meta("character_select_team", team)
	NetworkManager.stop_discovery_responder() # game started, hide the lobby
	CharacterSelectManager.reset_local()
	CharacterSelectManager.set_meta("peer_slots", authoritative_slots.duplicate(true))
	get_tree().change_scene_to_file("res://Celebes Abyssal Tides/scenes/ui/menus/CharacterSelect.tscn")


# peer id -> slot number (the other way around)
func _peer_slot_map():
	var result = {}
	for slot_number in slots:
		result[int(slots[slot_number])] = int(slot_number)
	return result


func _on_slot_gui_input(event, slot_number):
	# left click only
	if not event is InputEventMouseButton:
		return
	if not event.pressed or event.button_index != MOUSE_BUTTON_LEFT:
		return
	if slots.has(slot_number):
		return # taken

	if multiplayer.is_server():
		host_move_peer_to_slot(HOST_PEER_ID, slot_number)
	else:
		request_slot_change.rpc_id(HOST_PEER_ID, slot_number) # ask the host


func _on_start_button_pressed():
	if not multiplayer.is_server():
		return
	if not can_start_game():
		update_start_state()
		return
	open_character_select.rpc(_peer_slot_map())


func _on_ready_button_pressed():
	_request_lobby_ready(true)


func _on_unready_button_pressed():
	_request_lobby_ready(false)


func _request_lobby_ready(value):
	if multiplayer.multiplayer_peer == null:
		return
	if multiplayer.is_server():
		_host_set_lobby_ready(HOST_PEER_ID, value)
	else:
		request_lobby_ready.rpc_id(HOST_PEER_ID, value)


@rpc("any_peer", "call_remote", "reliable")
func request_lobby_ready(value: bool):
	if multiplayer.is_server():
		_host_set_lobby_ready(multiplayer.get_remote_sender_id(), value)


func _host_set_lobby_ready(peer_id, value):
	var index = find_slot_of_peer(peer_id)
	if index < 0:
		return
	if LobbyManager.find_slot_by_peer(peer_id) == -1:
		LobbyManager.set_slot_player(index, peer_id, get_player_name(peer_id))
	LobbyManager.slots[index]["ready"] = value
	LobbyManager.sync_lobby()
	update_slot_labels() # sync_lobby only goes to the clients so update mine
	print("Lobby ready: peer %s -> %s" % [peer_id, value])


func _on_back_button_pressed():
	if multiplayer.is_server():
		host_closed_lobby.rpc() # tell the clients first
		await get_tree().create_timer(0.3).timeout # wait a bit so the message gets there
	disconnect_from_network()
	go_to_main_menu()


# lost connection to the host
func _on_server_disconnected():
	disconnect_from_network()
	go_to_main_menu()


func disconnect_from_network():
	# disconnect the signals first so go_to_main_menu doesnt get called twice
	if multiplayer.server_disconnected.is_connected(_on_server_disconnected):
		multiplayer.server_disconnected.disconnect(_on_server_disconnected)
	if multiplayer.peer_disconnected.is_connected(_on_peer_disconnected):
		multiplayer.peer_disconnected.disconnect(_on_peer_disconnected)

	NetworkManager.stop_discovery_responder()
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = null


func go_to_main_menu():
	get_tree().change_scene_to_file("res://Celebes Abyssal Tides/scenes/MainMenu.tscn")


func _on_local_username_changed(new_name):
	if multiplayer.multiplayer_peer == null:
		return
	if multiplayer.is_server():
		player_names[HOST_PEER_ID] = PlayerProfile.sanitize(new_name)
		host_send_slots_to_everyone()
