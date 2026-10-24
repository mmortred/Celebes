extends CanvasLayer
## Leviathan rising cutscene: the leviathan wakes up.
## The arena shakes, every player stops, then the serpent's eye fills the screen,
## opens, glares, closes (one slow blink), everyone respawns on their own side, and play
## goes on from each player's own camera.
## The arena adds one of these on every peer at the same moment (leviathan rising rpc),
## so it needs no networking of its own.
##
## The timing lives in $AnimationPlayer ("awakening", 7s), open it in the editor to see or change it:
##   0.0  the arena rumbles (camera_shake), players can still move
##   2.0  everyone stops, fade to black
##   2.4  the eye shows behind shut lids, they slowly open (lid 1 -> 0)
##   3.4  the eye glows, 4.6 leans in and glares, trembling (eye_shake)
##   6.1  the lids narrow shut
##   6.6  still black: everyone respawns on their side, back to the arena by 7.0

signal finished

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var root: Control = $Root
@onready var eye: TextureRect = $Root/Eye
@onready var top_lid: TextureRect = $Root/TopLid
@onready var bottom_lid: TextureRect = $Root/BottomLid
@onready var curtain: ColorRect = $Curtain # fades the arena to black and back, so the eye only shows on black

const LID_FEATHER = 0.15 # bottom part of each lid that fades out, the lids overlap by this when shut

# animated by "awakening"
var camera_shake := 0.0 # current arena shake, px
var eye_shake := 0.0 # current eye tremble, px
var lid := 1.0: set = set_lid # 1 = the lids meet in the middle, 0 = both off screen

var camera: Camera2D # my player's (or the spectator's) camera
var camera_offset := Vector2.ZERO # its offset before the shake, put back afterwards


func _ready() -> void:
	root.hide()
	curtain.modulate.a = 0.0
	eye.pivot_offset = eye.size / 2.0 # zoom into the middle of the eye
	set_lid(1.0)
	camera = get_viewport().get_camera_2d()
	if camera:
		camera_offset = camera.offset
	GameManager.match_paused = true # leviathan rising timer and border wait for the whole cutscene
	anim.animation_finished.connect(_on_animation_finished)
	anim.play("awakening")


func _process(_delta: float) -> void:
	if is_instance_valid(camera):
		camera.offset = camera_offset + Vector2(randf_range(-1, 1), randf_range(-1, 1)) * camera_shake
	eye.position = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * eye_shake


# back to playing, each camera is still on its own player
func _on_animation_finished(_anim_name: StringName) -> void:
	set_players_frozen(false)
	GameManager.match_paused = false
	finished.emit()
	queue_free()


func set_lid(value: float) -> void:
	lid = value
	if not is_node_ready():
		return
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
