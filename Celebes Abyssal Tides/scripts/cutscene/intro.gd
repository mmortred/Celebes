extends Node2D

# intro cutscene: calm sea -> pollution -> going up to the surface -> title

signal pollution_finished 
signal title_shown

@export_file("*.tscn") var next_scene = "res://Celebes Abyssal Tides/scenes/MainMenu.tscn"
@export var fade_time = 0.8 # each half of the fade

@onready var anim = $AnimationPlayer
@onready var camera = $Camera2D
@onready var logo = $Title/Logo
@onready var press_start = $Title/PressStart
@onready var credit = $Title/Credit

var at_title = false


func _ready():
	logo.modulate.a = 0.0
	press_start.modulate.a = 0.0
	credit.modulate.a = 0.0
	anim.animation_finished.connect(_on_animation_finished)
	anim.play("intro")
	anim.seek(0.0, true) # apply the first keys right away (trash hidden, fish in place)


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


# zoom in, fade to black, then change scene
func _finish():
	set_process_unhandled_input(false)
	anim.pause() # freeze the title and serpent during the fade

	var layer = CanvasLayer.new()
	layer.layer = 100
	var fader = ColorRect.new()
	fader.color = Color(0, 0, 0, 0)
	fader.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fader.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(fader)
	get_tree().root.add_child(layer)

	var tw = layer.create_tween()
	tw.tween_property(fader, "color:a", 1.0, fade_time)
	tw.parallel().tween_property(camera, "zoom", camera.zoom * 1.5, fade_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property($Title, "offset", Vector2(-160, -90), fade_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property($Title, "scale", Vector2(1.5, 1.5), fade_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.tween_callback(get_tree().change_scene_to_file.bind(next_scene))
	tw.tween_property(fader, "color:a", 0.0, fade_time)
	tw.tween_callback(layer.queue_free)
