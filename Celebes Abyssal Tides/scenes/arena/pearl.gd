extends Node2D
## The pearl. Sits at the clam zone (its starting spot) until a living player touches it,
## then that player carries it. Drops where the carrier dies (or leaves the game).
## Bring it to your own team's well to score; it then goes back to the clam.
## The server decides everything and tells every peer with rpcs.

const RETURN_DELAY = 3.0 # seconds after a capture before the pearl is back at the clam

@onready var collect_area: Area2D = $CollectArea
@onready var sprite: Sprite2D = $PearlSprite

var carrier_name = "" # name of the player holding the pearl, "" = on the ground
var home_position := Vector2.ZERO # the clam zone
var last_carrier_position := Vector2.ZERO # server: where to drop it if the carrier vanishes
var t := 0.0


func _ready() -> void:
	add_to_group("pearl") # so carriers and wells can find me
	home_position = global_position
	collect_area.body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	t += delta
	sprite.position.y = sin(t * 3.0) * 3.0 # gentle bob so it reads as a pickup
	if multiplayer.is_server() and carrier_name != "":
		var carrier = find_player(carrier_name)
		if carrier == null:
			dropped.rpc(last_carrier_position) # carrier left the game
		else:
			last_carrier_position = carrier.global_position


func find_player(player_name: String) -> Node:
	for player in get_tree().get_nodes_in_group("players"):
		if str(player.name) == player_name:
			return player
	return null


func _on_body_entered(body):
	if not multiplayer.is_server(): # only the server decides who got it, so two players can't both grab it
		return
	if carrier_name != "" or not visible:
		return
	if not body.is_in_group("players") or body.is_dead:
		return
	collected.rpc(str(body.name))


@rpc("authority", "call_local", "reliable") # server tells every peer who picked it up
func collected(player_name):
	carrier_name = player_name
	visible = false
	collect_area.set_deferred("monitoring", false) # stop detecting while someone carries it
	var carrier = find_player(player_name)
	if carrier:
		carrier.set_has_pearl(true)
		last_carrier_position = carrier.global_position
		GameManager.announcement.emit("%s took the pearl!" % carrier.label.text, carrier.team)


@rpc("authority", "call_local", "reliable") # server tells every peer where it fell
func dropped(drop_position: Vector2):
	var carrier = find_player(carrier_name)
	if carrier:
		carrier.set_has_pearl(false)
	carrier_name = ""
	global_position = drop_position
	visible = true
	collect_area.set_deferred("monitoring", true) # can be picked up again (dead players are ignored)
	GameManager.announcement.emit("PEARL DROPPED!", -1)


# Server: called by a well when its team's carrier walks in.
func try_capture(player, well) -> void:
	if not multiplayer.is_server() or str(player.name) != carrier_name:
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
	var well = get_node_or_null(well_path)
	if well:
		well.play_capture()
	GameManager.announcement.emit("%s CAPTURED THE PEARL!" % ("SEA NOMADS" if team == 0 else "GARBAGE MONSTERS"), team)


@rpc("authority", "call_local", "reliable")
func back_home():
	carrier_name = ""
	global_position = home_position
	visible = true
	collect_area.set_deferred("monitoring", true)
	GameManager.announcement.emit("The pearl is back in the clam", -1)
