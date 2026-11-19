extends Control

# JOIN popup, lists the lobbies on the network and has a box to type the ip

signal join_requested(ip)
signal closed

const PIXEL_FONT = preload("res://Celebes Abyssal Tides/assets/fonts/PixelifySans-VariableFont_wght.ttf")
const ASK_INTERVAL = 1.0 # seconds between each search
const LOBBY_TIMEOUT = 3.5 # remove a lobby if it didnt answer for this long
const ACCENT = Color(0.21, 0.91, 0.91)

var finder = PacketPeerUDP.new()
var lobbies = {} # lobby id -> {ip, name, players, max, seen}
var ask_timer = 0.0
var list_box = null
var empty_label = null
var ip_input = null
var status_label = null


func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var my_theme = Theme.new()
	my_theme.default_font = PIXEL_FONT
	my_theme.default_font_size = 11
	theme = my_theme
	_build_ui()

	# port 0 = any free port, the hosts answer here
	finder.set_broadcast_enabled(true)
	if finder.bind(0) != OK:
		set_status("LAN search unavailable, use the IP field")
	_ask_for_lobbies()


func _exit_tree():
	finder.close()


func _build_ui():
	var shade = ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.01, 0.04, 0.09, 0.9)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(shade)

	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var frame = PanelContainer.new()
	frame.custom_minimum_size = Vector2(330, 0)
	var frame_style = StyleBoxFlat.new()
	frame_style.bg_color = Color(0.015, 0.035, 0.06, 0.97)
	frame_style.border_color = ACCENT
	frame_style.set_border_width_all(1)
	frame_style.set_corner_radius_all(3)
	frame_style.set_content_margin_all(10)
	frame.add_theme_stylebox_override("panel", frame_style)
	center.add_child(frame)

	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	frame.add_child(box)

	var title = _label("JOIN A LOBBY", 16, ACCENT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	box.add_child(_label("Lobbies on your network", 11, Color(0.8, 0.9, 0.95)))
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(310, 96)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	list_box = VBoxContainer.new()
	list_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_box.add_theme_constant_override("separation", 3)
	scroll.add_child(list_box)
	empty_label = _label("Searching...", 11, Color(0.6, 0.7, 0.75))
	list_box.add_child(empty_label)

	box.add_child(HSeparator.new())
	box.add_child(_label("Or type the host's IP", 11, Color(0.8, 0.9, 0.95)))
	var row = HBoxContainer.new()
	box.add_child(row)
	ip_input = LineEdit.new()
	ip_input.placeholder_text = "e.g. 192.168.1.15"
	ip_input.text = "127.0.0.1"
	ip_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ip_input.text_submitted.connect(_on_ip_submitted)
	row.add_child(ip_input)
	var connect_button = Button.new()
	connect_button.text = "CONNECT"
	connect_button.pressed.connect(_on_connect_pressed)
	row.add_child(connect_button)

	status_label = _label("", 10, Color(1.0, 0.85, 0.5))
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(status_label)

	var back = Button.new()
	back.text = "BACK"
	back.pressed.connect(close)
	box.add_child(back)


func _on_ip_submitted(text):
	join_requested.emit(text)


func _on_connect_pressed():
	join_requested.emit(ip_input.text)


func _on_lobby_pressed(ip):
	join_requested.emit(ip)


func close():
	closed.emit()
	queue_free()


func set_status(message):
	if status_label != null:
		status_label.text = message


func _process(delta):
	ask_timer += delta
	if ask_timer >= ASK_INTERVAL:
		ask_timer = 0.0
		_ask_for_lobbies()
	_read_replies()
	_drop_stale_lobbies()


# ask every pc on the network (and this pc) for lobbies
func _ask_for_lobbies():
	if not finder.is_bound():
		return
	var targets = ["255.255.255.255", "127.0.0.1"]
	for address in IP.get_local_addresses():
		var parts = address.split(".")
		if parts.size() != 4:
			continue
		if address.begins_with("127.") or address.begins_with("169.254."):
			continue
		targets.append("%s.%s.%s.255" % [parts[0], parts[1], parts[2]])

	var ask = NetworkManager.DISCOVERY_ASK.to_utf8_buffer()
	for target in targets:
		finder.set_dest_address(target, NetworkManager.DISCOVERY_PORT)
		finder.put_packet(ask)


func _read_replies():
	var changed = false
	while finder.get_available_packet_count() > 0:
		var data = JSON.parse_string(finder.get_packet().get_string_from_utf8())
		var ip = finder.get_packet_ip()
		if typeof(data) != TYPE_DICTIONARY or data.get("game", "") != "celebes":
			continue # not our game

		var id = str(data.get("id", ip))
		# the same host can answer from 127.0.0.1 and from its real ip, use the real one
		if lobbies.has(id) and ip.begins_with("127.") and not str(lobbies[id].ip).begins_with("127."):
			ip = lobbies[id].ip

		lobbies[id] = {
			"ip": ip,
			"name": str(data.get("name", "Host")),
			"players": int(data.get("players", 1)),
			"max": int(data.get("max", 8)),
			"seen": Time.get_ticks_msec(),
		}
		changed = true

	if changed:
		_rebuild_list()


func _drop_stale_lobbies():
	var now = Time.get_ticks_msec()
	for id in lobbies.keys():
		if now - int(lobbies[id].seen) > LOBBY_TIMEOUT * 1000.0:
			lobbies.erase(id)
			_rebuild_list()


func _rebuild_list():
	for child in list_box.get_children():
		if child != empty_label:
			child.queue_free()
	empty_label.visible = lobbies.is_empty()

	for id in lobbies:
		var lobby = lobbies[id]
		var button = Button.new()
		button.text = "%s's lobby   %d/%d   %s" % [lobby.name, lobby.players, lobby.max, lobby.ip]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.disabled = int(lobby.players) >= int(lobby.max) # full
		if button.disabled:
			button.text += "   FULL"
		button.pressed.connect(_on_lobby_pressed.bind(str(lobby.ip)))
		list_box.add_child(button)


func _label(text, font_size, color):
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label
