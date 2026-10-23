extends CanvasLayer
## Sudden death cutscene: the leviathan wakes up.
## The arena shakes, every player stops, then the serpent's eye fills the screen,
## opens, glares, closes (one slow blink), everyone respawns on their own side, and play
## goes on from each player's own camera.
## The arena adds one of these on every peer at the same moment (sudden death rpc),
## so it needs no networking of its own.

signal finished

@export var shake_time := 2.0 # arena shake before the players stop
@export var shake_strength := 6.0 # px the camera jumps around while shaking
@export var eye_time := 5.0 # the eye part, from fade-in to fade-out

@onready var root: Control = $Root
@onready var eye: TextureRect = $Root/Eye
@onready var top_lid: TextureRect = $Root/TopLid
@onready var bottom_lid: TextureRect = $Root/BottomLid
@onready var curtain: ColorRect = $Curtain # fades the arena to black and back, so the eye only shows on black

const LID_FEATHER = 0.15 # bottom part of each lid that fades out, the lids overlap by this when shut

var camera: Camera2D # my player's (or the spectator's) camera
var camera_offset := Vector2.ZERO # its offset before the shake, put back afterwards
var camera_shake := 0.0 # current arena shake, px
var eye_shake := 0.0 # current eye tremble, px


func _ready() -> void:
	root.hide()
	curtain.modulate.a = 0.0
	eye.pivot_offset = eye.size / 2.0 # zoom into the middle of the eye
	set_lid(1.0)
	camera = get_viewport().get_camera_2d()
	if camera:
		camera_offset = camera.offset
	GameManager.match_paused = true # sudden death timer and border wait for the whole cutscene
	play()


func _process(_delta: float) -> void:
	if is_instance_valid(camera):
		camera.offset = camera_offset + Vector2(randf_range(-1, 1), randf_range(-1, 1)) * camera_shake
	eye.position = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * eye_shake


func play() -> void:
	# 1. the arena rumbles, players can still move
	var rumble := create_tween()
	rumble.tween_property(self, "camera_shake", shake_strength, 0.3)
	rumble.tween_interval(shake_time - 0.6)
	rumble.tween_property(self, "camera_shake", 0.0, 0.3)
	await rumble.finished

	# 2. everyone stops, the eye takes the screen
	set_players_frozen(true)
	# every step below says when it starts and how long it lasts, in seconds out of 5
	var s := eye_time / 5.0 # keeps the steps in proportion if eye_time changes
	var t := create_tween().set_parallel(true)
	t.tween_property(curtain, "modulate:a", 1.0, 0.4 * s).from(0.0) # 0.0 fade to black
	t.tween_callback(swap_to_eye.bind(true)).set_delay(0.4 * s) # lids are shut, so the screen stays black
	t.tween_method(set_lid, 1.0, 0.0, 1.0 * s).set_delay(0.4 * s).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE) # 0.4 slowly opens
	t.tween_property(eye, "scale", Vector2.ONE * 1.08, 2.2 * s).set_delay(0.4 * s) # 0.4 creeping zoom
	t.tween_property(eye, "modulate", Color(1.35, 1.2, 1.1), 0.6 * s).set_delay(1.4 * s) # 1.4 the eye glows
	t.tween_property(eye, "modulate", Color.WHITE, 0.6 * s).set_delay(2.0 * s)
	t.tween_property(eye, "scale", Vector2.ONE * 1.22, 1.5 * s).set_delay(2.6 * s).set_ease(Tween.EASE_IN) # 2.6 leans in and glares
	t.tween_property(eye, "modulate", Color(1.5, 1.25, 1.1), 1.5 * s).set_delay(2.6 * s)
	t.tween_property(self, "eye_shake", 3.0, 1.5 * s).set_delay(2.6 * s)
	t.tween_method(set_lid, 0.0, 1.0, 0.5 * s).set_delay(4.1 * s).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE) # 4.1 narrows shut
	t.tween_property(self, "eye_shake", 0.0, 0.5 * s).set_delay(4.1 * s)
	t.tween_callback(send_players_home).set_delay(4.6 * s) # 4.6 still black: everyone to their side
	t.tween_callback(swap_to_eye.bind(false)).set_delay(4.6 * s) # 4.6 back to the arena, done at 5.0
	t.tween_property(curtain, "modulate:a", 0.0, 0.4 * s).from(1.0).set_delay(4.6 * s)
	await t.finished

	# 3. back to playing, each camera is still on its own player
	set_players_frozen(false)
	GameManager.match_paused = false
	finished.emit()
	queue_free()


# Swaps the black curtain for the eye (true) or back (false) while the screen is black.
func swap_to_eye(value: bool) -> void:
	root.visible = value
	curtain.modulate.a = 0.0 if value else 1.0


# Moves both eyelids: 1 = they meet in the middle, 0 = both off screen.
func set_lid(value: float) -> void:
	var middle := root.size.y / 2.0
	var overlap := top_lid.size.y * LID_FEATHER
	top_lid.position.y = lerpf(-top_lid.size.y, middle + overlap - top_lid.size.y, value)
	bottom_lid.position.y = lerpf(root.size.y, middle - overlap, value)


# Every player respawns (full HP, alive again) on their own team's side. Each machine
# moves only its own player, like a normal respawn. Teammates are sorted by name so
# every machine agrees on who takes which spawn point.
func send_players_home() -> void:
	var arena := get_tree().current_scene
	if not arena.has_method("get_respawn_position"):
		return
	for team in [0, 1]:
		var teammates := get_tree().get_nodes_in_group("players").filter(func(p): return p.team == team)
		teammates.sort_custom(func(a, b): return str(a.name) < str(b.name))
		for i in teammates.size():
			if teammates[i].is_multiplayer_authority():
				teammates[i].respawn.rpc(arena.get_respawn_position(team, i))


func set_players_frozen(value: bool) -> void:
	for player in get_tree().get_nodes_in_group("players"):
		player.cutscene_frozen = value


func _exit_tree() -> void:
	# never leave a player stuck, the clock stopped or a camera off-centre, even if the arena closes mid-cutscene
	set_players_frozen(false)
	GameManager.match_paused = false
	if is_instance_valid(camera):
		camera.offset = camera_offset
