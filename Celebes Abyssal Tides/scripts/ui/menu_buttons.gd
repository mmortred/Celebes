extends Control
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var ip_input: LineEdit = $IPInput

func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


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
	$IPInput.visible = true


func _on_ip_input_text_submitted(new_text: String) -> void:
	var ip = ip_input.text
	if ip == "":
		ip = "127.0.0.1"  #change later
	NetworkManager.join_game(ip)
	get_tree().change_scene_to_file("res://Celebes Abyssal Tides/scenes/arena/Arena.tscn")


func _on_host_button_pressed() -> void:
	NetworkManager.host_game()
	get_tree().change_scene_to_file("res://Celebes Abyssal Tides/scenes/arena/Arena.tscn")
