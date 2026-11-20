extends CanvasLayer

# serpent rising cutscene: the arena shakes, everyone stops and the serpent eye opens

signal finished

const LID_FEATHER = 0.15 # the faded bottom part of the lids, they overlap by this much

@onready var anim = $AnimationPlayer
@onready var root = $Root
@onready var eye = $Root/Eye
@onready var top_lid = $Root/TopLid
@onready var bottom_lid = $Root/BottomLid
@onready var curtain = $Curtain # black screen fade

# the animation changes these
var camera_shake = 0.0 # px
var eye_shake = 0.0 # px
var lid = 1.0: set = set_lid # 1 = closed, 0 = open

var camera = null # my camera
var camera_offset = Vector2.ZERO # to put it back after shaking


func _ready():
	root.hide()
	curtain.modulate.a = 0.0
	eye.pivot_offset = eye.size / 2.0 # zoom from the middle
	set_lid(1.0)
	camera = get_viewport().get_camera_2d()
	if camera:
		camera_offset = camera.offset
	GameManager.match_paused = true # timer and border stop during the cutscene
	anim.animation_finished.connect(_on_animation_finished)
	anim.play("awakening")


func _process(_delta):
	if is_instance_valid(camera):
		camera.offset = camera_offset + Vector2(randf_range(-1, 1), randf_range(-1, 1)) * camera_shake
	eye.position = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * eye_shake


# done, back to playing
func _on_animation_finished(_anim_name):
	set_players_frozen(false)
	GameManager.match_paused = false
	finished.emit()
	queue_free()


func set_lid(value):
	lid = value
	if not is_node_ready():
		return
	var middle = root.size.y / 2.0
	var overlap = top_lid.size.y * LID_FEATHER
	top_lid.position.y = lerpf(-top_lid.size.y, middle + overlap - top_lid.size.y, value)
	bottom_lid.position.y = lerpf(root.size.y, middle - overlap, value)


# called by the animation, everyone respawns on the ENEMY side (sorted by name so every pc agrees)
# so whoever gets the pearl has to fight through the other team to get home
# only this one respawn is swapped, after this you respawn on your own side again
func send_players_home():
	var arena = get_tree().current_scene
	if not arena.has_method("get_swapped_spawn_position"):
		return
	for team in [0, 1]:
		var teammates = []
		for player in get_tree().get_nodes_in_group("players"):
			if player.team == team:
				teammates.append(player)
		teammates.sort_custom(_sort_by_name)

		for i in teammates.size():
			if teammates[i].is_multiplayer_authority():
				teammates[i].respawn.rpc(arena.get_swapped_spawn_position(team, i))


func _sort_by_name(a, b):
	return str(a.name) < str(b.name)


func set_players_frozen(value):
	for player in get_tree().get_nodes_in_group("players"):
		player.cutscene_frozen = value


func _exit_tree():
	# just in case the arena closes in the middle of the cutscene
	set_players_frozen(false)
	GameManager.match_paused = false
	if is_instance_valid(camera):
		camera.offset = camera_offset
