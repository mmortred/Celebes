extends Node2D
## intro cutscene: calm sea -> pollution -> rise to surface -> title.
## first key/click skips straight to the title, the next one goes to next_scene.

signal pollution_finished
signal title_shown

@export_file("*.tscn") var next_scene := "res://Celebes Abyssal Tides/scenes/MainMenu.tscn"
@export var calm_time := 2.0 # seconds of peaceful sea before pollution
@export var calm_zoom := 1.2 # slow push-in on the fish during the calm
@export var fade_time := 0.8 # each half of the fade into next_scene
@export var pollution_time := 8.0 # how long the wave takes to cover the screen before the rise
# wave progress (pollution_wave.gdshader): 0.18 = front just off-screen right,
# 0.8 = the whole screen is covered, then the rise to the surface begins
@export var wave_start := 0.18
@export var wave_at_rise := 0.8
@export var wave_after_rise := 1.0 # it keeps rolling while the camera leaves
@export var rise_time := 7.0 # camera trip up through the deep to the surface
@export var rise_zoom := 0.6 # how far the camera pulls back mid-rise
@export var surface_y := -1080.0 # camera y when looking at the horizon
@export var murk_tint := Color(0.85, 0.86, 0.7) # whole-scene tint once polluted
@export var dead_weed_color := Color(0.7, 0.6, 0.38)
@export var bleached_coral := Color(0.72, 0.68, 0.68) # corals fade and grey out in the pollution

@onready var pollution: ColorRect = $Pollution
@onready var murk: CanvasModulate = $Murk
@onready var grime: CPUParticles2D = $Grime
@onready var camera: Camera2D = $Camera2D
@onready var logo: Control = $Title/Logo
@onready var press_start: Control = $Title/PressStart
@onready var credit: Control = $Title/Credit
@onready var nstw_logo: Control = $Title/NstwLogo
@onready var serpent: Node2D = $Surface/Leviathan/Serpent
@onready var speed_lines: ColorRect = $SpeedLines/Lines

var timeline: Tween
var title_tween: Tween
var at_title := false
var polluting := false
# trash still riding the wave front, rightmost first. each piece starts off-screen
# right, travels with the front, and drops off when the front reaches its spot
var waiting_trash: Array[Node2D] = []
var trash_drop_x: Dictionary = {} # piece -> x where it leaves the wave (its scene position)
var trash_lag: Dictionary = {}    # piece -> how far behind the front edge (inside the murk) it rides


func _ready():
	logo.modulate.a = 0.0
	press_start.modulate.a = 0.0
	credit.modulate.a = 0.0
	nstw_logo.modulate.a = 0.0

	# keep every drop spot (its x in the scene, 0-640) inside what the wave covers
	# before the rise and on screen (trash rides up to 130px behind the edge)
	var covered_from := maxf(pollution_front_x(wave_at_rise) + 130.0, 20.0)
	for trash in $Trash.get_children():
		trash.hide()
		waiting_trash.append(trash)
		trash_drop_x[trash] = lerpf(covered_from, 650.0, clampf(trash.position.x / 640.0, 0.0, 1.0))
		trash_lag[trash] = randf_range(45.0, 130.0)
	waiting_trash.sort_custom(func(a, b): return a.position.x > b.position.x)

	timeline = create_tween()
	timeline.tween_property(camera, "zoom", Vector2.ONE * calm_zoom, calm_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	timeline.tween_callback(_start_pollution)
	# slow, steady roll from the right edge until it covers the whole screen
	timeline.tween_property(pollution.material, "shader_parameter/progress", wave_at_rise, pollution_time).from(wave_start)
	# ease back out so the whole wave is in view
	timeline.parallel().tween_property(camera, "zoom", Vector2.ONE, pollution_time * 0.3).set_trans(Tween.TRANS_SINE)
	timeline.parallel().tween_property(murk, "color", murk_tint, pollution_time)
	timeline.parallel().tween_property($SeaweedBack, "modulate", dead_weed_color.darkened(0.25), pollution_time)
	timeline.parallel().tween_property($SeaweedFront, "modulate", dead_weed_color, pollution_time)
	timeline.parallel().tween_property($Corals, "modulate", bleached_coral, pollution_time)
	timeline.parallel().tween_property($LightRays, "modulate:a", 0.25, pollution_time)
	timeline.tween_callback(pollution_finished.emit)

	# long rise through the deep: pull way back, rush up with speed lines, settle at the surface
	var lines := speed_lines.material
	timeline.tween_property(camera, "position:y", surface_y, rise_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	timeline.parallel().tween_property(pollution.material, "shader_parameter/progress", wave_after_rise, rise_time)
	timeline.parallel().tween_property(camera, "zoom", Vector2.ONE * rise_zoom, rise_time * 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	timeline.parallel().tween_property(camera, "zoom", Vector2.ONE, rise_time * 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT).set_delay(rise_time * 0.55)
	timeline.parallel().tween_property(lines, "shader_parameter/intensity", 1.0, rise_time * 0.2).set_delay(rise_time * 0.1)
	timeline.parallel().tween_property(lines, "shader_parameter/intensity", 0.0, rise_time * 0.2).set_delay(rise_time * 0.7)
	timeline.parallel().tween_property(murk, "color", Color.WHITE, rise_time * 0.6)
	timeline.tween_callback(_show_title)


func _start_pollution():
	grime.emitting = true
	# fish bolt once the wave gets close, far fish first
	_after(pollution_time * 0.2, _flee.bind($FarFish, 90.0))
	_after(pollution_time * 0.4, _flee.bind($School, 140.0))
	# no more bubbles, the sea is choking
	_after(pollution_time * 0.6, $Bubbles.set_emitting.bind(false))
	# trash rides in on the wave, see _process
	polluting = true


func _process(delta: float) -> void:
	if not polluting or waiting_trash.is_empty():
		return
	var front_x := pollution_front_x()
	for trash in waiting_trash.duplicate():
		var ride_x: float = front_x + trash_lag[trash] # trails the edge so the murk arrives first
		if ride_x <= trash_drop_x[trash]:
			# the front reached this piece's spot: let go, it drifts on a little and sinks
			waiting_trash.erase(trash)
			trash.position.x = trash_drop_x[trash]
			trash.release(Vector2(-randf_range(8.0, 25.0), randf_range(-8.0, 8.0))) # small push, never outruns the wave
		else:
			# carried inside the wave just behind its edge, tumbling (starts off-screen right)
			trash.position.x = ride_x
			trash.rotation += delta * 2.0
			trash.show()


# World x of the pollution wave's front edge, matching pollution_wave.gdshader:
# front = 1 - progress * (1 + 2 * edge_width), plus a little noise we ignore.
func pollution_front_x(progress: float = -1.0) -> float:
	if progress < 0.0:
		progress = pollution.material.get_shader_parameter("progress")
	var edge_width: float = pollution.material.get_shader_parameter("edge_width")
	var front := 1.0 - progress * (1.0 + 2.0 * edge_width) + 0.015
	return pollution.position.x + front * pollution.size.x


func _show_title():
	at_title = true
	# the leviathan passes under the surface once, after the camera has stopped
	serpent.swim_past()
	title_tween = create_tween()
	title_tween.tween_property(logo, "modulate:a", 1.0, 1.5)
	title_tween.tween_property(press_start, "modulate:a", 1.0, 0.5)
	# studio credit sits under PRESS START and stays put while it blinks
	title_tween.tween_property(credit, "modulate:a", 1.0, 0.5)
	title_tween.parallel().tween_property(nstw_logo, "modulate:a", 1.0, 0.5)
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
	# trash that hadn't arrived yet: put it straight on the seabed
	polluting = false
	waiting_trash.clear()
	for trash in $Trash.get_children():
		trash.position.y = trash.rest_y
		trash.show()
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
