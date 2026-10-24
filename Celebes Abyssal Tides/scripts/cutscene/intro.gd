extends Node2D
## intro cutscene: calm sea -> pollution -> rise to surface -> title.
## first key/click skips straight to the title, the next one goes to next_scene.
##
## The timing lives in $AnimationPlayer, open it in the editor to see or change it:
##   "intro"  0-2s calm push-in, 2-10s the pollution wave rolls in, 10-17s rise to the surface
##   "title"  logo, PRESS START and credits fade in, the leviathan swims past
##   "blink"  PRESS START blinks (loops, queued after "title")
## This script only does what an animation can't: trash riding the wave front,
## skipping, and the fade into next_scene.

signal pollution_finished # emitted by "intro" at 10s
signal title_shown

@export_file("*.tscn") var next_scene := "res://Celebes Abyssal Tides/scenes/MainMenu.tscn"
@export var fade_time := 0.8 # each half of the fade into next_scene
# wave progress (pollution_wave.gdshader) at 10s in "intro", when the rise begins.
# change both together: trash drop spots are worked out from this
@export var wave_at_rise := 0.8

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var pollution: ColorRect = $Pollution
@onready var camera: Camera2D = $Camera2D
@onready var logo: Control = $Title/Logo
@onready var press_start: Control = $Title/PressStart
@onready var credit: Control = $Title/Credit
@onready var nstw_logo: Control = $Title/NstwLogo
@onready var serpent: Node2D = $Surface/Leviathan/Serpent

var at_title := false
var polluting := false # switched on by "intro" at 2s, trash starts riding the wave
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

	anim.animation_finished.connect(_on_animation_finished)
	anim.play("intro")


func _on_animation_finished(anim_name: StringName):
	if anim_name == &"intro" and not at_title:
		_show_title()


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
	anim.play("title") # also sends the leviathan past, once the camera has stopped
	anim.queue("blink")
	title_shown.emit()


## jump to the end state of the intro
func _skip_to_title():
	# every animated value lands on its last key (method keys on the way are skipped)
	anim.seek(anim.current_animation_length, true)
	anim.pause()
	# trash that hadn't arrived yet: put it straight on the seabed
	polluting = false
	waiting_trash.clear()
	for trash in $Trash.get_children():
		trash.position.y = trash.rest_y
		trash.show()
	_show_title()


# called by "intro": the fish in that group bolt
func _flee(group: NodePath, speed: float):
	for f in get_node(group).get_children():
		f.flee(speed)


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
	anim.pause() # stop the blink
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
