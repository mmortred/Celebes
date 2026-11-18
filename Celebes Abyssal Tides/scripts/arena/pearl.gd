extends Node2D

# the pearl, only the host decides who has it

const RETURN_DELAY = 5.0 # seconds before it goes back to the clam after a capture

@onready var collect_area = $CollectArea
@onready var sprite = $PearlSprite

var carrier_name = "" # who has it, "" = on the ground
var home_position = Vector2.ZERO # the clam
var last_carrier_position = Vector2.ZERO # host: where to drop it if the carrier leaves
var respawning = false # captured and waiting to come back
var t = 0.0


func _ready():
	add_to_group("pearl") # so the players and wells can find it
	home_position = global_position
	collect_area.body_entered.connect(_on_body_entered)


func _process(delta):
	t += delta
	sprite.position.y = sin(t * 3.0) * 3.0

	if multiplayer.is_server() and carrier_name != "":
		var carrier = find_player(carrier_name)
		if carrier == null:
			dropped.rpc(last_carrier_position) # carrier left the game
		else:
			last_carrier_position = carrier.global_position


func find_player(player_name):
	for player in get_tree().get_nodes_in_group("players"):
		if str(player.name) == player_name:
			return player
	return null


func _on_body_entered(body):
	if not multiplayer.is_server():
		return # only the host decides so 2 players cant both get it
	if carrier_name != "" or not visible:
		return
	if not body.is_in_group("players") or body.is_dead:
		return
	collected.rpc(str(body.name))


# host tells everyone who got it
@rpc("authority", "call_local", "reliable")
func collected(player_name):
	carrier_name = player_name
	visible = false
	collect_area.set_deferred("monitoring", false) # nobody else can grab it
	var carrier = find_player(player_name)
	if carrier:
		carrier.set_has_pearl(true)
		SFXManager.play_at("pearl_pickup", carrier.global_position)
		last_carrier_position = carrier.global_position
		GameManager.announcement.emit("%s took the pearl!" % carrier.label.text, carrier.team)


# host tells everyone where it fell
@rpc("authority", "call_local", "reliable")
func dropped(drop_position: Vector2):
	var carrier = find_player(carrier_name)
	if carrier:
		carrier.set_has_pearl(false)
	carrier_name = ""
	global_position = drop_position
	visible = true
	collect_area.set_deferred("monitoring", true)
	GameManager.announcement.emit("PEARL DROPPED!", -1)


# host: the well calls this when the carrier walks in
func try_capture(player, well):
	if not multiplayer.is_server():
		return
	if str(player.name) != carrier_name:
		return
	GameManager.add_score(player.team)
	captured.rpc(player.team, well.get_path())
	await get_tree().create_timer(RETURN_DELAY).timeout
	if is_inside_tree() and carrier_name == "":
		back_home.rpc()


@rpc("authority", "call_local", "reliable")
func captured(team: int, well_path: NodePath):
	var carrier = find_player(carrier_name)
	if carrier:
		carrier.set_has_pearl(false)
	carrier_name = ""
	respawning = true
	var well = get_node_or_null(well_path)
	if well:
		well.play_capture()
		SFXManager.play_at("score", well.global_position)
	if team == 0:
		GameManager.announcement.emit("SEA NOMADS CAPTURED THE PEARL!", team)
	else:
		GameManager.announcement.emit("GARBAGE MONSTERS CAPTURED THE PEARL!", team)


@rpc("authority", "call_local", "reliable")
func back_home():
	carrier_name = ""
	respawning = false
	global_position = home_position
	visible = true
	collect_area.set_deferred("monitoring", true)
	GameManager.announcement.emit("The pearl is back in the clam", -1)
