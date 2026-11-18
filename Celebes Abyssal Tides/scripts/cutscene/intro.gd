extends Node2D

# intro cutscene: calm sea -> pollution -> lit studios logo -> going up to the surface -> title
# all the moving stuff is in the AnimationPlayers, this script just picks what plays next

signal pollution_finished
signal title_shown

@export_file("*.tscn") var next_scene = "res://Celebes Abyssal Tides/scenes/MainMenu.tscn"

@onready var anim = $AnimationPlayer
@onready var fade_layer = $FadeLayer

var at_title = false


func _ready():
	anim.animation_finished.connect(_on_animation_finished)
	anim.play("intro")
	anim.seek(0.0, true) # apply the first keys right away (title hidden, trash hidden, fish in place)


func _on_animation_finished(anim_name):
	if anim_name == &"intro" and not at_title:
		_show_title()


func _show_title():
	at_title = true
	anim.play("title")
	anim.queue("blink")
	title_shown.emit()


# jump to the end of the intro
func _skip_to_title():
	anim.seek(anim.current_animation_length, true) # everything goes to its last key
	anim.pause()
	_show_title()


func _unhandled_input(event):
	var is_button = event is InputEventKey or event is InputEventMouseButton or event is InputEventJoypadButton
	if not is_button:
		return
	if not event.is_pressed() or event.is_echo():
		return
	if at_title:
		_finish()
	else:
		_skip_to_title()


# zoom in and fade to black, the outro animation calls _change_scene at the end
func _finish():
	set_process_unhandled_input(false)
	anim.clear_queue()
	anim.play("outro")


func _change_scene():
	# move the black screen to the root so it stays on top of the next scene, then it fades out by itself
	fade_layer.reparent(get_tree().root)
	fade_layer.get_node("FadePlayer").play("fade_out")
	get_tree().change_scene_to_file(next_scene)
