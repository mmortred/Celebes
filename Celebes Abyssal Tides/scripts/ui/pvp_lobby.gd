extends Control

# SETTINGS
# Containers that hold the slot nodes. The ORDER here decides the slot numbers:
# SeaNomads = slots 0-2, 
#GarbageMonsters = slots 3-5, 
#Spectators = slots 6-7.
const SLOT_CONTAINER_NAMES = ["SeaNomads", "GarbageMonsters", "Spectators"]

const BORDER_FRAME_PATH = "SlotLayout/BorderFrame"
const NAME_LABEL_PATH = "SlotLayout/PlayerNameLabel"

# In Godot, the host (server) always has peer id 1.
const HOST_PEER_ID = 1

# NODES
@onready var host_ip_label: Label = $HostIpLabel
@onready var start_button: TextureButton = $StartButton
@onready var ready_button: TextureButton = $ReadyButton
@onready var unready_button: TextureButton = $UnreadyButton
@onready var back_button: TextureButton = $BackButton

# DATA
# Every slot node in the scene, in slot-number order. all_slots[0] is slot 0.
var all_slots: Array = []

# Who is sitting where. Key = slot number, value = peer id.
# Example: { 0: 1, 1: 54821 } means the host is in slot 0 and peer 54821 is in slot 1.
# A slot number that is NOT in this dictionary is empty.
# Only the host edits this. Clients just receive a copy from the host.
var slots: Dictionary = {}


# SETUP
func _ready() -> void:
	collect_slot_nodes()
	connect_buttons()
	connect_slot_clicks()
	setup_role_ui()

	if multiplayer.is_server():
		# HOST: put myself in the first slot and listen for players leaving.
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)
		assign_peer_to_first_free_slot(HOST_PEER_ID)
		update_slot_labels()
	else:
		# CLIENT: listen for the host disappearing, then ask the host for a slot.
		multiplayer.server_disconnected.connect(_on_server_disconnected)
		request_join.rpc_id(HOST_PEER_ID)


# Fill all_slots with the real slot nodes found inside the slot containers.
func collect_slot_nodes() -> void:
	for container_name in SLOT_CONTAINER_NAMES:
		var container = get_node_or_null(container_name)
		if container == null:
			push_warning("Slot container not found: " + container_name)
			continue
		for child in container.get_children():
			# The containers also hold banners and labels. Real slots are the
			# children that have a "SlotLayout" inside them, so skip the rest.
			if child.has_node("SlotLayout"):
				all_slots.append(child)


func connect_buttons() -> void:
	start_button.pressed.connect(_on_start_button_pressed)
	ready_button.pressed.connect(_on_ready_button_pressed)
	unready_button.pressed.connect(_on_unready_button_pressed)
	back_button.pressed.connect(_on_back_button_pressed)


# Make every slot clickable. We listen on the BorderFrame because it is the
# visible box that covers the slot. .bind(i) passes the slot number along.
func connect_slot_clicks() -> void:
	for i in all_slots.size():
		var border_frame: Control = all_slots[i].get_node(BORDER_FRAME_PATH)
		border_frame.mouse_filter = Control.MOUSE_FILTER_STOP  # make sure it receives clicks
		border_frame.gui_input.connect(_on_slot_gui_input.bind(i))

# Show/hide buttons and set the IP label depending on host or client.
func setup_role_ui() -> void:
	if multiplayer.is_server():
		start_button.show()
		back_button.show()
		ready_button.hide()
		unready_button.hide()
		host_ip_label.text = "IP: " + get_local_ipv4()
	else:
		start_button.hide()
		back_button.show()
		ready_button.show()
		unready_button.show()
		host_ip_label.text = "CONNECTED TO HOST"


# Return the first normal IPv4 address of this computer (like 192.168.1.15).
func get_local_ipv4() -> String:
	for address in IP.get_local_addresses():
		var is_ipv4 = address.contains(".")        # IPv6 addresses use ":" instead
		var is_loopback = address.begins_with("127.")  # 127.x.x.x is only "this PC"
		var is_auto = address.begins_with("169.254.")  # no real network connection
		if is_ipv4 and not is_loopback and not is_auto:
			return address
	return "127.0.0.1"  # fallback if nothing else was found


# SLOT HELPERS
# Returns the slot number a peer is in, or -1 if they have no slot.
func find_slot_of_peer(peer_id: int) -> int:
	for slot_number in slots:
		if slots[slot_number] == peer_id:
			return slot_number
	return -1


# Returns the first empty slot number, or -1 if every slot is taken.
func find_first_free_slot() -> int:
	for slot_number in all_slots.size():
		if not slots.has(slot_number):
			return slot_number
	return -1


# Put a peer in the first free slot (does nothing if they already have one).
func assign_peer_to_first_free_slot(peer_id: int) -> void:
	if find_slot_of_peer(peer_id) != -1:
		return  # rule: exactly 1 slot per player

	var free_slot = find_first_free_slot()
	if free_slot == -1:
		print("Lobby is full, no slot for peer ", peer_id)
		return

	slots[free_slot] = peer_id


func get_player_name(peer_id: int) -> String:
	return "Player " + str(peer_id)


# Redraw every slot's name label from the slots dictionary.
func update_slot_labels() -> void:
	for slot_number in all_slots.size():
		var name_label: Label = all_slots[slot_number].get_node(NAME_LABEL_PATH)
		if slots.has(slot_number):
			name_label.text = get_player_name(slots[slot_number])
		else:
			name_label.text = "Empty"


# HOST-ONLY LOGIC (only ever runs on the host)
# Send the slots dictionary to all clients, then redraw on the host too.
func host_send_slots_to_everyone() -> void:
	sync_all_slots.rpc(slots)  # goes to clients only (it is "call_remote")
	update_slot_labels()       # the host updates its own screen here


# Move a peer into a chosen slot, if that slot is empty.
func host_move_peer_to_slot(peer_id: int, new_slot: int) -> void:
	if new_slot < 0 or new_slot >= all_slots.size():
		return  # not a real slot
	if slots.has(new_slot):
		return  # someone is already there

	# Free the old slot first so the player only ever has 1 slot.
	var old_slot = find_slot_of_peer(peer_id)
	if old_slot != -1:
		slots.erase(old_slot)

	slots[new_slot] = peer_id
	host_send_slots_to_everyone()


# The host's built-in signal: a client dropped out or left.
func _on_peer_disconnected(peer_id: int) -> void:
	var slot_number = find_slot_of_peer(peer_id)
	if slot_number != -1:
		slots.erase(slot_number)
	host_send_slots_to_everyone()


# RPCs (functions that are called over the network)
# CLIENT -> HOST: "I just loaded the lobby, please give me a slot."
@rpc("any_peer", "call_remote", "reliable")
func request_join() -> void:
	if not multiplayer.is_server():
		return
	var peer_id = multiplayer.get_remote_sender_id()  # who sent this call
	assign_peer_to_first_free_slot(peer_id)
	host_send_slots_to_everyone()


# CLIENT -> HOST: "I clicked an empty slot, please move me there."
@rpc("any_peer", "call_remote", "reliable")
func request_slot_change(new_slot: int) -> void:
	if not multiplayer.is_server():
		return
	var peer_id = multiplayer.get_remote_sender_id()
	host_move_peer_to_slot(peer_id, new_slot)


# HOST -> CLIENTS: "Here is the current list of who is in which slot."
@rpc("authority", "call_remote", "reliable")
func sync_all_slots(new_slots: Dictionary) -> void:
	# Rebuild the dictionary from scratch and force every key (slot number)
	# and value (peer id) to be an int, in case they arrive as another type.
	slots.clear()
	for key in new_slots:
		slots[int(key)] = int(new_slots[key])
	update_slot_labels()


# HOST -> CLIENTS: "The host left, the lobby is closed."
@rpc("authority", "call_remote", "reliable")
func host_closed_lobby() -> void:
	disconnect_from_network()
	go_to_main_menu()


# HOST -> EVERYONE (including the host): "Game is starting."
@rpc("authority", "call_local", "reliable")
func open_character_select() -> void:
	# TODO: Load Character Select here
	# Later, replace the print below with something like:
	# get_tree().change_scene_to_file("res://scenes/ui/menus/CharacterSelect.tscn")
	print("Would load Character Select now")


# INPUT / BUTTONS

# Called when the mouse does anything over a slot. slot_number comes from .bind(i).
func _on_slot_gui_input(event: InputEvent, slot_number: int) -> void:
	# Only react to a left mouse button press.
	var is_left_click = event is InputEventMouseButton \
			and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT
	if not is_left_click:
		return

	if slots.has(slot_number):
		return  # slot is taken, nothing to do

	if multiplayer.is_server():
		host_move_peer_to_slot(HOST_PEER_ID, slot_number)  # host moves directly
	else:
		request_slot_change.rpc_id(HOST_PEER_ID, slot_number)  # client asks the host


func _on_start_button_pressed() -> void:
	open_character_select.rpc()


func _on_ready_button_pressed() -> void:
	# TODO: Tell the host this player is ready
	print("Ready pressed")


func _on_unready_button_pressed() -> void:
	# TODO: Tell the host this player is no longer ready
	print("Unready pressed")


func _on_back_button_pressed() -> void:
	if multiplayer.is_server():
		# Tell all clients to leave first...
		host_closed_lobby.rpc()
		# ...then wait a moment so the message has time to arrive before we hang up.
		await get_tree().create_timer(0.3).timeout
	disconnect_from_network()
	go_to_main_menu()


# The client's built-in signal: the connection to the host was lost.
func _on_server_disconnected() -> void:
	go_to_main_menu()


# LEAVING

func disconnect_from_network() -> void:
	# Stop listening first, so closing the connection can't trigger
	# _on_server_disconnected and call go_to_main_menu() a second time.
	# Each signal is only connected on one role (host or client),
	# so check before disconnecting.
	if multiplayer.server_disconnected.is_connected(_on_server_disconnected):
		multiplayer.server_disconnected.disconnect(_on_server_disconnected)
	if multiplayer.peer_disconnected.is_connected(_on_peer_disconnected):
		multiplayer.peer_disconnected.disconnect(_on_peer_disconnected)

	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = null


func go_to_main_menu() -> void:
	# TODO: Load Main Menu here
	# Later, replace the print below with something like:
	# get_tree().change_scene_to_file("res://scenes/ui/menus/MainMenu.tscn")
	print("Would load Main Menu now")
