extends Node2D

const SPECTATOR_CAMERA = preload("res://Celebes Abyssal Tides/scripts/arena/spectator_camera.gd")
const LEVIATHAN_AWAKENING = preload("res://Celebes Abyssal Tides/scenes/CutScene/LeviathanAwakening/LeviathanAwakening.tscn")

# Character id (CharacterSelectManager) -> scene. Anything not listed uses the base player.
const CHARACTER_SCENES := {
	0: preload("res://Celebes Abyssal Tides/scenes/player/SeaNomad/Bugis.tscn"),
	5: preload("res://Celebes Abyssal Tides/scenes/player/Monsters/ToxicSludge.tscn"),
}
const BASE_PLAYER = preload("res://Celebes Abyssal Tides/scenes/player/player.tscn")

# spawn folders may sit deeper (MainArena keeps them under ArenaUtil) or be missing
@onready var team_left_spawns = find_child("TeamLeftSpawns")
@onready var team_right_spawns = find_child("TeamRightSpawns")
@onready var spawner: MultiplayerSpawner = $MultiplayerSpawner

var players_spawned := false
var late_phase := false # after the 5-minute mark: inner wells and spawns, closing border
# Pearl-carrier barriers: the carrier's own team wall goes up in front of their outer
# well, so they have to go around their base instead of running straight in.
@onready var barrier_walls := {0: get_node_or_null("SeaNomadBarrierWall"), 1: get_node_or_null("GarbageBarrierWall")}
var barrier_team := -2 # team whose wall is up, -1 = none (-2 = not set yet)

func _ready() -> void:
	print("Arena loaded!")
	# every peer builds spawned players the same way from the host's spawn data
	spawner.spawn_function = _build_player
	# GameManager announces the 5-minute mark (leviathan rising) on every peer
	GameManager.leviathan_rising_started.connect(enter_late_phase)
	GameManager.match_won.connect(_on_match_won) # winner screen: freeze and frame everyone
	var scoreboard := CanvasLayer.new()
	scoreboard.set_script(preload("res://Celebes Abyssal Tides/scripts/ui/scoreboard_overlay.gd"))
	add_child(scoreboard)
	if multiplayer.multiplayer_peer != null and multiplayer.is_server():
		ScoreboardManager.begin_match()

	# spectators get no player, just a camera they can pan around the arena
	if NetworkManager.get_meta("character_select_team", "") == "spectator":
		add_spectator_camera()

	# the host spawns everyone once all peers have this arena loaded
	if multiplayer.is_server():
		CharacterSelectManager.everyone_in_arena.connect(spawn_players)
	CharacterSelectManager.report_arena_ready()
	_set_barrier(-1) # both walls down (a hidden TileMapLayer would still block)


# Reads the pearl every frame, like the clam does, so every peer agrees without rpcs.
func _process(_delta: float) -> void:
	var pearl = get_tree().get_first_node_in_group("pearl")
	var carrier_team := -1
	if pearl and pearl.carrier_name != "":
		var carrier = pearl.find_player(pearl.carrier_name)
		if carrier:
			carrier_team = carrier.team
	_set_barrier(carrier_team)


func _set_barrier(team: int) -> void:
	if team == barrier_team:
		return
	barrier_team = team
	for wall_team in barrier_walls:
		var wall: TileMapLayer = barrier_walls[wall_team]
		if wall:
			wall.visible = wall_team == team
			wall.collision_enabled = wall_team == team


# HOST: one player per non-spectator, with their picked character, at their team's spawns.
# The MultiplayerSpawner recreates each one on every peer through _build_player.
func spawn_players() -> void:
	if players_spawned:
		return
	players_spawned = true
	var networked := multiplayer.multiplayer_peer != null and not multiplayer.multiplayer_peer is OfflineMultiplayerPeer
	var spawn_count := {0: 0, 1: 0}
	var everyone: Array[int] = [multiplayer.get_unique_id()]
	everyone.append_array(multiplayer.get_peers())
	for peer_id in everyone:
		var slot := LobbyManager.find_slot_by_peer(peer_id)
		var team := 0
		if slot >= 6:
			continue # spectator
		elif slot >= 3:
			team = 1
		elif slot < 0 and networked:
			continue # not in the lobby (shouldn't happen)
		var character := CharacterSelectManager.selected_by(peer_id)
		if character < 0:
			character = 0 if team == 0 else 5 # F6 test run: no character select
		spawner.spawn({
			"peer": peer_id,
			"character": character,
			"team": team,
			"position": get_spawn_position(team, spawn_count[team]),
		})
		spawn_count[team] += 1


func _build_player(data: Dictionary) -> Node:
	var look := CharacterSelectManager.play_as(int(data.character)) # stand-in while art is missing
	var scene: PackedScene = CHARACTER_SCENES.get(look, BASE_PLAYER)
	var player := scene.instantiate()
	player.name = str(data.peer) # the name sets who controls it (player.gd _enter_tree)
	player.team = int(data.team)
	player.character = int(data.character) # the HUD shows this character's icon
	player.position = data.position
	return player


# The 5-minute mark: the outer wells stop counting and the inner ("late") ones
# start, respawns move to the inner spawn points, and the border closes in.
func enter_late_phase() -> void:
	if late_phase:
		return
	late_phase = true
	for well in get_tree().get_nodes_in_group("wells"):
		well.set_active(well.late)
	var border := find_child("ArenaBorder")
	if border:
		border.start()
	GameManager.announcement.emit("LEVIATHAN RISING! New wells - the border is closing in!", -1)
	add_child(LEVIATHAN_AWAKENING.instantiate()) # shake, freeze everyone, the serpent's eye, then play on


# Match decided (every peer): everyone stops where they are and the view glides to the
# middle of all the players, zoomed so they all fit. The HUD draws the winner on top.
func _on_match_won(_winner: int, _reason: String) -> void:
	var players := get_tree().get_nodes_in_group("players")
	for player in players:
		player.cutscene_frozen = true
	var current := get_viewport().get_camera_2d()
	var camera := Camera2D.new()
	camera.name = "WinnerCamera"
	add_child(camera)
	if current:
		camera.global_position = current.get_screen_center_position()
		camera.zoom = current.zoom
	camera.make_current()
	var area := Rect2(get_arena_bounds().get_center(), Vector2.ZERO) # nobody left: the arena's middle
	for i in players.size():
		var body: Vector2 = players[i].global_position + Vector2(0, -32) # middle of the body
		area = Rect2(body, Vector2.ZERO) if i == 0 else area.expand(body)
	area = area.grow(120.0) # room around them
	# players fill the top half of the screen; the HUD puts the result in the bottom half
	var view := get_viewport_rect().size
	var zoom := clampf(minf(view.x / area.size.x, view.y * 0.5 / area.size.y), 0.35, 2.0)
	var target := area.get_center() + Vector2(0, view.y * 0.18 / zoom) # moves the players up on screen
	var tween := create_tween().set_parallel().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(camera, "global_position", target, 1.8)
	tween.tween_property(camera, "zoom", Vector2.ONE * zoom, 1.8)


# Where a dead player comes back: their team's side, inner spawns after 5 minutes.
# index picks a spawn point in turn (so teammates don't stack), -1 = a random one.
func get_respawn_position(team: int, index := -1) -> Vector2:
	var folder_name := "TeamLeftSpawns" if team == 0 else "TeamRightSpawns"
	var folder: Node = find_child(folder_name + "Late") if late_phase else null
	if folder == null or folder.get_child_count() == 0:
		folder = team_left_spawns if team == 0 else team_right_spawns
	if folder == null or folder.get_child_count() == 0:
		return Vector2.ZERO
	if index < 0:
		index = randi()
	return folder.get_child(index % folder.get_child_count()).global_position


# Team 0 (Sea Nomads) uses the left spawns, team 1 (Garbage Monsters) the right.
# Players on one team take the spawn points in turn.
func get_spawn_position(team: int, index: int) -> Vector2:
	var folder: Node = team_left_spawns if team == 0 else team_right_spawns
	if folder == null or folder.get_child_count() == 0:
		return Vector2.ZERO
	return folder.get_child(index % folder.get_child_count()).global_position


func add_spectator_camera() -> void:
	var camera := Camera2D.new()
	camera.name = "SpectatorCamera"
	camera.set_script(SPECTATOR_CAMERA)
	camera.bounds = get_arena_bounds()
	camera.position = camera.bounds.get_center()
	add_child(camera)
	# no player of their own, so no HP / portrait card; scoreboard and timer stay.
	# hide what's inside the card: the HUD's intro animation turns the card itself back on
	var hud := find_child("ArenaHUD", true, false) # under MainArena's CanvasLayer
	var player_stats: Node = hud.get_node_or_null("PlayerStats") if hud else null
	if player_stats:
		for part in player_stats.get_children():
			part.visible = false


# World rect of what is actually drawn, used to keep the spectator camera in:
# all painted tile layers, else the background picture, else the spawn points.
func get_arena_bounds() -> Rect2:
	var tiles := Rect2()
	for layer in get_children():
		if layer is TileMapLayer and layer.tile_set and layer.get_used_rect().size != Vector2i.ZERO:
			var used: Rect2i = layer.get_used_rect()
			var tile := Vector2(layer.tile_set.tile_size)
			var rect: Rect2 = layer.global_transform * Rect2(Vector2(used.position) * tile, Vector2(used.size) * tile)
			tiles = rect if tiles.size == Vector2.ZERO else tiles.merge(rect)
	if tiles.size != Vector2.ZERO:
		return tiles
	for child in get_children():
		if child is Sprite2D and child.texture and child.z_index < 0: # background picture
			return child.global_transform * child.get_rect()
	var bounds := Rect2()
	for spawn_folder in [team_left_spawns, team_right_spawns]:
		if spawn_folder == null:
			continue
		for spawn in spawn_folder.get_children():
			bounds = Rect2(spawn.global_position, Vector2.ZERO) if bounds.size == Vector2.ZERO and bounds.position == Vector2.ZERO else bounds.expand(spawn.global_position)
	return bounds.grow(160)

func get_random_spawn_position(team_name: String) -> Vector2:
	var spawn_folder: Node2D = null

	if team_name.to_lower() == "left":
		spawn_folder = team_left_spawns
	elif team_name.to_lower() == "right":
		spawn_folder = team_right_spawns
	else:
		print("Team name must be left or right.")
		return Vector2.ZERO

	if spawn_folder == null or spawn_folder.get_child_count() == 0:
		print("No spawn points found for ", team_name)
		return Vector2.ZERO

	var spawn_points = spawn_folder.get_children()
	var random_spawn = spawn_points.pick_random()

	return random_spawn.global_position
