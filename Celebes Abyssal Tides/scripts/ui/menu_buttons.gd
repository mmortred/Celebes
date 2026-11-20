extends Control

# main menu buttons (PVP, HOST, JOIN, settings)

const LOBBY_PATH = "res://Celebes Abyssal Tides/scenes/ui/lobby/PvPLobby.tscn"
const SETTINGS_SCENE = preload("res://Celebes Abyssal Tides/scenes/ui/menus/SettingsPanel.tscn")
const JOIN_PANEL_SCRIPT = preload("res://Celebes Abyssal Tides/scripts/ui/join_panel.gd")

@onready var anim = $AnimationPlayer
@onready var ip_input = $IPInput

var connecting = false
var settings_panel = null
var join_panel = null

# for _wait_for_connection
var connect_done = false
var connect_ok = false


func _ready():
	if has_node("OptionsButton"):
		$OptionsButton.pressed.connect(_open_settings)
	if has_node("QuitButton"):
		$QuitButton.pressed.connect(_on_quit_button_pressed)
	# sent back by the host (lobby full, kicked), show why
	if NetworkManager.join_error != "":
		_set_status(NetworkManager.join_error)
		NetworkManager.join_error = ""


# closes the game
func _on_quit_button_pressed():
	get_tree().quit()


func _on_pvp_button_pressed():
	anim.play("menu")
	await anim.animation_finished
	anim.play("play")


func _on_back_button_pressed():
	ip_input.visible = false
	anim.play_backwards("play")
	await anim.animation_finished
	anim.play_backwards("menu")


# opens the join popup (lobbies on the network + ip box)
func _on_join_button_pressed():
	if connecting or is_instance_valid(join_panel):
		return
	ip_input.visible = false
	join_panel = Control.new()
	join_panel.set_script(JOIN_PANEL_SCRIPT)
	join_panel.join_requested.connect(_on_ip_input_text_submitted)
	add_child(join_panel)


func _on_ip_input_text_submitted(new_text):
	if connecting:
		return
	var ip = new_text.strip_edges()
	if ip.is_empty():
		ip = "127.0.0.1"
	if not ip.is_valid_ip_address():
		_set_status("Invalid IP. Try 127.0.0.1")
		return

	connecting = true
	_set_status("Connecting to %s ..." % ip)
	if not NetworkManager.join_game(ip):
		connecting = false
		_set_status("Could not start connection; check Output")
		return

	var success = await _wait_for_connection()
	connecting = false
	if not is_inside_tree():
		return
	if success:
		_set_status("Connected! Opening lobby...")
		var err = get_tree().change_scene_to_file(LOBBY_PATH)
		if err != OK:
			push_error("Could not load lobby: " + error_string(err))
	else:
		NetworkManager.close_connection()
		_set_status("Connection failed. Make sure Window 1 is HOST")


# waits up to 8 seconds for the host to answer
func _wait_for_connection():
	connect_done = false
	connect_ok = false
	multiplayer.connected_to_server.connect(_on_connect_ok, CONNECT_ONE_SHOT)
	multiplayer.connection_failed.connect(_on_connect_failed, CONNECT_ONE_SHOT)

	var elapsed = 0.0
	while not connect_done and elapsed < 8.0:
		await get_tree().process_frame
		elapsed += get_process_delta_time()

	if multiplayer.connected_to_server.is_connected(_on_connect_ok):
		multiplayer.connected_to_server.disconnect(_on_connect_ok)
	if multiplayer.connection_failed.is_connected(_on_connect_failed):
		multiplayer.connection_failed.disconnect(_on_connect_failed)

	if connect_done and connect_ok:
		return true
	return false


func _on_connect_ok():
	connect_done = true
	connect_ok = true


func _on_connect_failed():
	connect_done = true


func _on_host_button_pressed():
	if NetworkManager.host_game():
		_set_status("Hosting on UDP 7777")
		var err = get_tree().change_scene_to_file(LOBBY_PATH)
		if err != OK:
			push_error("Could not load lobby: " + error_string(err))
	else:
		_set_status("HOST failed. Port 7777 may already be in use")


func _set_status(message):
	var status = get_node_or_null("ConnectionStatus")
	if status != null:
		status.text = message
	if is_instance_valid(join_panel):
		join_panel.set_status(message)


func _open_settings():
	if is_instance_valid(settings_panel):
		return
	settings_panel = SETTINGS_SCENE.instantiate()
	add_child(settings_panel)
