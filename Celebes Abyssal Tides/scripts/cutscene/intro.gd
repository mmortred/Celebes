extends Node2D
## intro cutscene: calm sea -> pollution -> rise to surface -> title.
## first key/click skips straight to the title, the next one goes to next_scene.

signal pollution_finished
signal title_shown

@export_file("*.tscn") var next_scene := "res://Celebes Abyssal Tides/scenes/MainMenu.tscn"
@export var calm_time := 2.0 # seconds of peaceful sea before pollution
@export var calm_zoom := 1.2 # slow push-in on the fish during the calm
@export var fade_time := 0.8 # each half of the fade into next_scene
@export var pollution_time := 4.0 # how long the wave takes to cover the screen
@export var rise_time := 7.0 # camera trip up through the deep to the surface
@export var rise_zoom := 0.6 # how far the camera pulls back mid-rise
@export var surface_y := -1080.0 # camera y when looking at the horizon
@export var murk_tint := Color(0.85, 0.86, 0.7) # whole-scene tint once polluted
@export var dead_weed_color := Color(0.7, 0.6, 0.38)

@onready var pollution: ColorRect = $Pollution
@onready var murk: CanvasModulate = $Murk
@onready var grime: CPUParticles2D = $Grime
@onready var camera: Camera2D = $Camera2D
@onready var logo: Control = $Title/Logo
@onready var press_start: Control = $Title/PressStart
@onready var serpent: Node2D = $Surface/Leviathan/Serpent
@onready var speed_lines: ColorRect = $SpeedLines/Lines

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

	# long rise through the deep: pull way back, rush up with speed lines, settle at the surface
	var lines := speed_lines.material
	timeline.tween_property(camera, "position:y", surface_y, rise_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	timeline.parallel().tween_property(camera, "zoom", Vector2.ONE * rise_zoom, rise_time * 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	timeline.parallel().tween_property(camera, "zoom", Vector2.ONE, rise_time * 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT).set_delay(rise_time * 0.55)
	timeline.parallel().tween_property(lines, "shader_parameter/intensity", 1.0, rise_time * 0.2).set_delay(rise_time * 0.1)
	timeline.parallel().tween_property(lines, "shader_parameter/intensity", 0.0, rise_time * 0.2).set_delay(rise_time * 0.7)
	timeline.parallel().tween_property(murk, "color", Color.WHITE, rise_time * 0.6)
	timeline.tween_callback(_show_title)


func _start_pollution():
	grime.emitting = true
	# fish bolt once the wave gets close, far fish first
	_after(pollution_time * 0.15, _flee.bind($FarFish, 120.0))
	_after(pollution_time * 0.3, _flee.bind($School, 180.0))
	# no more bubbles, the sea is choking
	_after(pollution_time * 0.5, $Bubbles.set_emitting.bind(false))
	# trash sinks in one piece at a time
	var trash := $Trash.get_children()
	for i in trash.size():
		_after(pollution_time * 0.8 * i / trash.size(), trash[i].release)


func _show_title():
	at_title = true
	# the leviathan passes under the surface once, after the camera has stopped
	serpent.swim_past()
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
	speed_lines.material.set_shader_parameter("intensity", 0.0)
	murk.color = Color.WHITE
	# trash that hadn't dropped yet would hang in view, so settle it on the seabed
	for trash in $Trash.get_children():
		trash.position.y = trash.rest_y
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
	serpent.process_mode = Node.PROCESS_MODE_DISABLED # hold still during the fade

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
