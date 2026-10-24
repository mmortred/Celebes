extends Node2D
## intro cutscene: calm sea -> pollution -> rise to surface -> title.
## first key/click skips straight to the title, the next one goes to next_scene.
##
## Everything that moves is keyed, open these in the editor to see or change it:
##   $AnimationPlayer
##     "intro"  0-2s calm push-in, 2-10s the pollution wave rolls in (fish flee,
##              trash rides the wave front and sinks), 10-17s rise to the surface
##     "title"  logo, PRESS START and credits fade in, the leviathan swims past
##     "blink"  PRESS START keeps blinking (loops, queued after "title")
##   $AmbientPlayer
##     "ambient" loops the whole time: floating trash bobs, clouds drift, bags
##               breathe, and the clocks for fish tails, star twinkle and serpent sway
## This script only skips and fades into next_scene.

signal pollution_finished # emitted by "intro" at 10s
signal title_shown

@export_file("*.tscn") var next_scene := "res://Celebes Abyssal Tides/scenes/MainMenu.tscn"
@export var fade_time := 0.8 # each half of the fade into next_scene

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var camera: Camera2D = $Camera2D
@onready var logo: Control = $Title/Logo
@onready var press_start: Control = $Title/PressStart
@onready var credit: Control = $Title/Credit
@onready var nstw_logo: Control = $Title/NstwLogo

var at_title := false


func _ready():
	logo.modulate.a = 0.0
	press_start.modulate.a = 0.0
	credit.modulate.a = 0.0
	nstw_logo.modulate.a = 0.0
	anim.animation_finished.connect(_on_animation_finished)
	anim.play("intro")
	anim.seek(0.0, true) # apply the 0s keys now (trash hidden, fish in place) before the first frame


func _on_animation_finished(anim_name: StringName):
	if anim_name == &"intro" and not at_title:
		_show_title()


func _show_title():
	at_title = true
	anim.play("title")
	anim.queue("blink")
	title_shown.emit()


## jump to the end state of the intro
func _skip_to_title():
	# every animated value (camera, wave, fish, trash...) lands on its last key
	anim.seek(anim.current_animation_length, true)
	anim.pause()
	_show_title()


func _unhandled_input(event):
	var skip := (event is InputEventKey or event is InputEventMouseButton or event is InputEventJoypadButton)
	if not (skip and event.is_pressed() and not event.is_echo()):
		return
	if at_title:
		_finish()
	else:
		_skip_to_title()


## zoom in and fade to black, swap scenes, then fade the black away over next_scene.
## the fader lives on the root so it survives the scene change.
func _finish():
	set_process_unhandled_input(false)
	anim.pause() # hold the title and the leviathan still during the fade

	var layer := CanvasLayer.new()
	layer.layer = 100
	var fader := ColorRect.new()
	fader.color = Color(0, 0, 0, 0)
	fader.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fader.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(fader)
	get_tree().root.add_child(layer)

	var tw := layer.create_tween()
	tw.tween_property(fader, "color:a", 1.0, fade_time)
	tw.parallel().tween_property(camera, "zoom", camera.zoom * 1.5, fade_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property($Title, "offset", Vector2(-160, -90), fade_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property($Title, "scale", Vector2(1.5, 1.5), fade_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.tween_callback(get_tree().change_scene_to_file.bind(next_scene))
	tw.tween_property(fader, "color:a", 0.0, fade_time)
	tw.tween_callback(layer.queue_free)
