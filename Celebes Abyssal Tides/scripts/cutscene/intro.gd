extends Node2D
## intro cutscene: calm sea -> pollution -> rise to surface -> title.
## first key/click skips straight to the title, the next one goes to next_scene.

signal pollution_finished
signal title_shown

@export_file("*.tscn") var next_scene := "res://Celebes Abyssal Tides/scenes/MainMenu.tscn"
@export var calm_time := 4.0 # seconds of peaceful sea before pollution
@export var calm_zoom := 1.2 # slow push-in on the fish during the calm
@export var fade_time := 0.8 # each half of the fade into next_scene
@export var pollution_time := 8.0 # how long the wave takes to cover the screen
@export var rise_time := 5.0 # camera trip up to the surface
@export var surface_y := -180.0 # camera y when looking at the horizon
@export var murk_tint := Color(0.85, 0.86, 0.7) # whole-scene tint once polluted
@export var dead_weed_color := Color(0.7, 0.6, 0.38)

@onready var pollution: ColorRect = $Pollution
@onready var murk: CanvasModulate = $Murk
@onready var grime: CPUParticles2D = $Grime
@onready var camera: Camera2D = $Camera2D
@onready var logo: Control = $Title/Logo
@onready var press_start: Control = $Title/PressStart
@onready var deep_serpent: Node2D = $DeepSerpent
@onready var surface_serpent: Node2D = $Surface/Serpent

var timeline: Tween
var title_tween: Tween
var at_title := false


func _ready():
	logo.modulate.a = 0.0
	press_start.modulate.a = 0.0

	timeline = create_tween()
	timeline.tween_property(camera, "zoom", Vector2.ONE * calm_zoom, calm_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	timeline.tween_callback(_start_pollution)
	timeline.tween_property(pollution.material, "shader_parameter/progress", 1.0, pollution_time).set_trans(Tween.TRANS_SINE)
	# ease back out so the whole wave is in view
	timeline.parallel().tween_property(camera, "zoom", Vector2.ONE, pollution_time * 0.3).set_trans(Tween.TRANS_SINE)
	timeline.parallel().tween_property(murk, "color", murk_tint, pollution_time)
	timeline.parallel().tween_property($SeaweedBack, "modulate", dead_weed_color.darkened(0.25), pollution_time)
	timeline.parallel().tween_property($SeaweedFront, "modulate", dead_weed_color, pollution_time)
	timeline.parallel().tween_property($LightRays, "modulate:a", 0.25, pollution_time)
	timeline.tween_callback(pollution_finished.emit)
	# serpent is already gliding under the surface when the camera arrives
	timeline.tween_callback(surface_serpent.appear.bind(360.0))

	# rise to the surface, pulling back a little on the way up
	var half := rise_time * 0.5
	timeline.tween_property(camera, "position:y", surface_y, rise_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	timeline.parallel().tween_property(camera, "zoom", Vector2(0.9, 0.9), half).set_trans(Tween.TRANS_SINE)
	timeline.parallel().tween_property(camera, "zoom", Vector2.ONE, half).set_trans(Tween.TRANS_SINE).set_delay(half)
	timeline.parallel().tween_property(murk, "color", Color.WHITE, rise_time)
	timeline.tween_callback(_show_title)


func _start_pollution():
	grime.emitting = true
	# fish bolt once the wave gets close, far fish first
	_after(pollution_time * 0.2, _flee.bind($FarFish, 50.0))
	_after(pollution_time * 0.35, _flee.bind($School, 90.0))
	# no more bubbles, the sea is choking
	_after(pollution_time * 0.5, $Bubbles.set_emitting.bind(false))
	# something big stirs in the murk once the fish are gone
	_after(pollution_time * 0.55, deep_serpent.appear)
	# trash sinks in one piece at a time
	var trash := $Trash.get_children()
	for i in trash.size():
		_after(pollution_time * 0.8 * i / trash.size(), trash[i].release)


func _show_title():
	at_title = true
	title_tween = create_tween()
	title_tween.tween_property(logo, "modulate:a", 1.0, 1.5)
	title_tween.tween_property(press_start, "modulate:a", 1.0, 0.5)
	title_tween.tween_callback(_blink_press_start)
	title_shown.emit()


func _blink_press_start():
	title_tween = create_tween().set_loops()
	title_tween.tween_property(press_start, "modulate:a", 0.2, 0.6)
	title_tween.tween_property(press_start, "modulate:a", 1.0, 0.6)


## jump to the end state of the intro
func _skip_to_title():
	timeline.kill()
	pollution.material.set_shader_parameter("progress", 1.0)
	camera.position.y = surface_y
	camera.zoom = Vector2.ONE
	murk.color = Color.WHITE
	surface_serpent.appear(420.0)
	_show_title()


func _flee(group: Node, speed: float):
	for f in group.get_children():
		f.flee(speed)


func _after(delay: float, fn: Callable):
	get_tree().create_timer(delay).timeout.connect(fn)


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
	if title_tween:
		title_tween.kill()

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
