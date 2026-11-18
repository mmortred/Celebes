extends Node2D

# tuna run: a school of tuna swims across a random lane, the first one to touch it gets the tuna rush
# only the host decides when it comes, which lane and who caught it, like the pearl
# move the markers in Lanes to change where the lanes are

const RUN_TIMES = [210.0, 90.0] # when the timer shows 3:30 and 1:30
const LANE_NAMES = ["top", "middle", "bottom"] # same order as the markers in Lanes

@onready var anim = $AnimationPlayer
@onready var touch_area = $School/TouchArea
@onready var school = $School
@onready var lanes = $Lanes

var runs_done = 0
var caught = true # true = nobody can catch it right now


func _ready():
	touch_area.body_entered.connect(_on_body_entered)
	anim.animation_finished.connect(_on_animation_finished)


func _process(_delta):
	if not multiplayer.is_server():
		return
	if GameManager.state != GameManager.MatchState.IN_PROGRESS or GameManager.match_paused:
		return
	if runs_done >= RUN_TIMES.size():
		return
	if GameManager.time_remaining <= RUN_TIMES[runs_done]:
		start_run.rpc(runs_done, randi() % lanes.get_child_count())
		runs_done += 1


# host tells everyone the tuna are coming and in which lane
@rpc("authority", "call_local", "reliable")
func start_run(run_number: int, lane: int):
	caught = false
	school.position.y = lanes.get_child(lane).position.y # the animation only moves x
	# first one goes left to right, the next one right to left so its fair for both teams
	if run_number % 2 == 0:
		anim.play("run_right")
	else:
		anim.play("run_left")
	GameManager.announcement.emit("A school of tuna is passing through the %s lane!" % LANE_NAMES[lane], -1)


func _on_body_entered(body):
	if not multiplayer.is_server():
		return # only the host decides so 2 players cant both get it
	if caught:
		return
	if not body.is_in_group("players") or body.is_dead:
		return
	caught = true
	tuna_caught.rpc(str(body.name))


# host tells everyone who caught it
@rpc("authority", "call_local", "reliable")
func tuna_caught(player_name: String):
	caught = true
	anim.play("scatter")
	for player in get_tree().get_nodes_in_group("players"):
		if str(player.name) == player_name:
			player.start_tuna_rush()
			GameManager.announcement.emit("%s caught the Tuna Rush!" % player.label.text, player.team)


# nobody caught it before it swam away
func _on_animation_finished(_anim_name):
	caught = true
