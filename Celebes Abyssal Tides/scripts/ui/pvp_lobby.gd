extends Control

@onready var ip_line_edit = $VBoxContainer/IPLineEdit

func _ready():
	$VBoxContainer/HostButton.pressed.connect(_on_host_pressed)
	$VBoxContainer/JoinButton.pressed.connect(_on_join_pressed)

func _on_host_pressed():
	NetworkManager.host_game()
	get_tree().change_scene_to_file("res://scenes/arena/Arena.tscn")

func _on_join_pressed():
	var ip = ip_line_edit.text.strip_edges()
	if ip == "":
		ip = "127.0.0.1"  #change later
	NetworkManager.join_game(ip)
	get_tree().change_scene_to_file("res://scenes/arena/Arena.tscn")
