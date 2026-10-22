extends Control

const LOBBY_PATH := "res://Celebes Abyssal Tides/scenes/ui/lobby/PvPLobby.tscn"
const SETTINGS_SCENE := preload("res://Celebes Abyssal Tides/scenes/ui/menus/SettingsPanel.tscn")
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var ip_input: LineEdit = $IPInput
var connecting := false
var settings_panel: Control

func _ready() -> void:
	if has_node("OptionsButton"):
		$OptionsButton.pressed.connect(_open_settings)

func _on_pvp_button_pressed() -> void:
	anim.play("menu")
	await anim.animation_finished
	anim.play("play")

func _on_back_button_pressed() -> void:
	ip_input.visible = false
	anim.play_backwards("play")
	await anim.animation_finished
	anim.play_backwards("menu")

func _on_join_button_pressed() -> void:
	# First click reveals the IP field. Second click submits it.
	print("JOIN button pressed")
	if connecting:
		return
	if not ip_input.visible:
		ip_input.visible = true
		ip_input.text = "127.0.0.1"
		ip_input.select_all()
		ip_input.grab_focus()
		_set_status("Enter an IP, press Enter or click JOIN again")
		return
	_on_ip_input_text_submitted(ip_input.text)

func _on_ip_input_text_submitted(new_text: String) -> void:
	print("JOIN submitted: [", new_text, "]")
	if connecting:
		return
	var ip := new_text.strip_edges()
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
	var success: bool = await _wait_for_connection()
	connecting = false
	if not is_inside_tree():
		return
	if success:
		_set_status("Connected! Opening lobby...")
		var err := get_tree().change_scene_to_file(LOBBY_PATH)
		if err != OK:
			push_error("Could not load lobby: " + error_string(err))
	else:
		NetworkManager.close_connection()
		_set_status("Connection failed. Make sure Window 1 is HOST")

func _wait_for_connection() -> bool:
	var state := {"completed": false, "success": false}
	var ok_callback := func() -> void:
		state["completed"] = true
		state["success"] = true
	var fail_callback := func() -> void:
		state["completed"] = true
	multiplayer.connected_to_server.connect(ok_callback, CONNECT_ONE_SHOT)
	multiplayer.connection_failed.connect(fail_callback, CONNECT_ONE_SHOT)
	var elapsed := 0.0
	while not state["completed"] and elapsed < 8.0:
		await get_tree().process_frame
		elapsed += get_process_delta_time()
	if multiplayer.connected_to_server.is_connected(ok_callback):
		multiplayer.connected_to_server.disconnect(ok_callback)
	if multiplayer.connection_failed.is_connected(fail_callback):
		multiplayer.connection_failed.disconnect(fail_callback)
	return state["completed"] and state["success"]

func _on_host_button_pressed() -> void:
	print("HOST button pressed")
	if NetworkManager.host_game():
		_set_status("Hosting on UDP 7777")
		var err := get_tree().change_scene_to_file(LOBBY_PATH)
		if err != OK:
			push_error("Could not load lobby: " + error_string(err))
	else:
		_set_status("HOST failed. Port 7777 may already be in use")

func _set_status(message: String) -> void:
	print("MENU: ", message)
	var status: Label = get_node_or_null("ConnectionStatus")
	if status != null:
		status.text = message

func _open_settings() -> void:
	if is_instance_valid(settings_panel):
		return
	settings_panel = SETTINGS_SCENE.instantiate()
	add_child(settings_panel)
