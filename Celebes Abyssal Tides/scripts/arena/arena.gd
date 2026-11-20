extends Node2D

const SPECTATOR_CAMERA = preload("res://Celebes Abyssal Tides/scripts/arena/spectator_camera.gd")
const SERPENT_AWAKENING = preload("res://Celebes Abyssal Tides/scenes/CutScene/SerpentAwakening/SerpentAwakening.tscn")

# character id -> scene. if its not here it uses the base player
const CHARACTER_SCENES = {
	0: preload("res://Celebes Abyssal Tides/scenes/player/SeaNomad/Bugis.tscn"),
	1: preload("res://Celebes Abyssal Tides/scenes/player/SeaNomad/Bajau.tscn"),
	2: preload("res://Celebes Abyssal Tides/scenes/player/SeaNomad/Minahasan.tscn"),
	3: preload("res://Celebes Abyssal Tides/scenes/player/Monsters/PlasticHoard.tscn"),
	4: preload("res://Celebes Abyssal Tides/scenes/player/Monsters/RustyLeviathan.tscn"),
	5: preload("res://Celebes Abyssal Tides/scenes/player/Monsters/ToxicSludge.tscn"),
}
const SETTINGS_SCENE = preload("res://Celebes Abyssal Tides/scenes/ui/menus/SettingsPanel.tscn")
const BASE_PLAYER = preload("res://Celebes Abyssal Tides/scenes/player/player.tscn")

# find_child because in MainArena they are inside ArenaUtil
@onready var team_left_spawns = find_child("TeamLeftSpawns")
@onready var team_right_spawns = find_child("TeamRightSpawns")
@onready var spawner = $MultiplayerSpawner

# the wall of the pearl carrier's team goes up so they have to go around
@onready var barrier_walls = {0: get_node_or_null("SeaNomadBarrierWall"), 1: get_node_or_null("GarbageBarrierWall")}

var players_spawned = false
var settings_panel = null # Esc opens the settings (music and sfx volume) in the arena
var late_phase = false # after 5 minutes: inner wells and spawns, border closes
var barrier_team = -2 # team whose wall is up, -1 = none, -2 = not set yet


func _ready():
	print("Arena loaded!")
	spawner.spawn_function = _build_player # every peer makes the players the same way
	GameManager.serpent_rising_started.connect(enter_late_phase) # the 5 minute mark
	GameManager.match_won.connect(_on_match_won)

	var scoreboard = CanvasLayer.new()
	scoreboard.set_script(preload("res://Celebes Abyssal Tides/scripts/ui/scoreboard_overlay.gd"))
	add_child(scoreboard)
	if multiplayer.multiplayer_peer != null and multiplayer.is_server():
		ScoreboardManager.begin_match()

	if NetworkManager.get_meta("character_select_team", "") == "spectator":
		add_spectator_camera()

	# host spawns everyone when all peers have the arena loaded
	if multiplayer.is_server():
		CharacterSelectManager.everyone_in_arena.connect(spawn_players)
	CharacterSelectManager.report_arena_ready()
	_set_barrier(-1) # both walls down


# Esc opens and closes the settings, the match keeps going behind it
func _unhandled_input(event):
	if not event is InputEventKey:
		return
	if not event.pressed or event.echo or event.keycode != KEY_ESCAPE:
		return
	if is_instance_valid(settings_panel):
		settings_panel.queue_free()
		return
	var layer = CanvasLayer.new()
	layer.layer = 100 # over the hud
	add_child(layer)
	settings_panel = SETTINGS_SCENE.instantiate()
	layer.add_child(settings_panel)
	settings_panel.tree_exited.connect(layer.queue_free)


# check the pearl every frame so all peers agree without rpcs
func _process(_delta):
	var pearl = get_tree().get_first_node_in_group("pearl")
	var carrier_team = -1
	if pearl and pearl.carrier_name != "":
		var carrier = pearl.find_player(pearl.carrier_name)
		if carrier:
			carrier_team = carrier.team
	_set_barrier(carrier_team)


func _set_barrier(team):
	if team == barrier_team:
		return
	barrier_team = team
	for wall_team in barrier_walls:
		var wall = barrier_walls[wall_team]
		if wall:
			# hidden is not enough, the collision has to be off too
			wall.visible = wall_team == team
			wall.collision_enabled = wall_team == team


# host only: spawns 1 player for each non spectator
func spawn_players():
	if players_spawned:
		return
	players_spawned = true

	var networked = multiplayer.multiplayer_peer != null and not multiplayer.multiplayer_peer is OfflineMultiplayerPeer
	var spawn_count = {0: 0, 1: 0}
	var everyone = [multiplayer.get_unique_id()]
	everyone.append_array(multiplayer.get_peers())

	for peer_id in everyone:
		var slot = LobbyManager.find_slot_by_peer(peer_id)
		var team = 0
		if slot >= 6:
			continue # spectator
		elif slot >= 3:
			team = 1
		elif slot < 0 and networked:
			continue # not in the lobby (shouldnt happen)

		var character = CharacterSelectManager.selected_by(peer_id)
		if character < 0:
			# F6 test, no character select
			if team == 0:
				character = 0
			else:
				character = 5

		spawner.spawn({
			"peer": peer_id,
			"character": character,
			"team": team,
			"position": get_spawn_position(team, spawn_count[team]),
		})
		spawn_count[team] += 1


func _build_player(data):
	var look = CharacterSelectManager.play_as(int(data.character)) # stand in if no art yet
	var scene = CHARACTER_SCENES.get(look, BASE_PLAYER)
	var player = scene.instantiate()
	player.name = str(data.peer) # the name decides who controls it (see player.gd _enter_tree)
	player.team = int(data.team)
	player.character = int(data.character) # for the hud icon
	player.position = data.position
	return player


# 5 minute mark: inner wells, inner spawns, the border closes
func enter_late_phase():
	if late_phase:
		return
	late_phase = true
	for well in get_tree().get_nodes_in_group("wells"):
		well.set_active(well.late)
	var border = find_child("ArenaBorder")
	if border:
		border.start()
	GameManager.announcement.emit("SERPENT RISING! You start on the enemy side - fight your way home!", -1)
	add_child(SERPENT_AWAKENING.instantiate())


# match is over (every peer): freeze everyone and move the camera so all players fit
func _on_match_won(_winner, _reason):
	var players = get_tree().get_nodes_in_group("players")
	for player in players:
		player.cutscene_frozen = true

	var current = get_viewport().get_camera_2d()
	var camera = Camera2D.new()
	camera.name = "WinnerCamera"
	add_child(camera)
	if current:
		camera.global_position = current.get_screen_center_position()
		camera.zoom = current.zoom
	camera.make_current()

	# box around all the players (middle of the arena if theres nobody)
	var area = Rect2(get_arena_bounds().get_center(), Vector2.ZERO)
	for i in players.size():
		var body = players[i].global_position + Vector2(0, -32) # middle of the body
		if i == 0:
			area = Rect2(body, Vector2.ZERO)
		else:
			area = area.expand(body)
	area = area.grow(120.0)

	# players go on the top half, the hud shows the winner on the bottom half
	var view = get_viewport_rect().size
	var zoom = view.x / area.size.x
	if view.y * 0.5 / area.size.y < zoom:
		zoom = view.y * 0.5 / area.size.y
	zoom = clampf(zoom, 0.35, 2.0)
	var target = area.get_center() + Vector2(0, view.y * 0.18 / zoom)

	var tween = create_tween().set_parallel().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(camera, "global_position", target, 1.8)
	tween.tween_property(camera, "zoom", Vector2.ONE * zoom, 1.8)


# where a dead player respawns (index -1 = random spawn)
func get_respawn_position(team, index = -1):
	var folder = null
	if late_phase:
		if team == 0:
			folder = find_child("TeamLeftSpawnsLate")
		else:
			folder = find_child("TeamRightSpawnsLate")
	if folder == null or folder.get_child_count() == 0:
		if team == 0:
			folder = team_left_spawns
		else:
			folder = team_right_spawns
	if folder == null or folder.get_child_count() == 0:
		return Vector2.ZERO

	if index < 0:
		index = randi()
	return folder.get_child(index % folder.get_child_count()).global_position


# the serpent cutscene uses this: you start on the other team's late spawns
func get_swapped_spawn_position(team, index):
	if team == 0:
		return get_respawn_position(1, index)
	return get_respawn_position(0, index)


# team 0 = left spawns, team 1 = right spawns. teammates take turns on the spawn points
func get_spawn_position(team, index):
	var folder = team_right_spawns
	if team == 0:
		folder = team_left_spawns
	if folder == null or folder.get_child_count() == 0:
		return Vector2.ZERO
	return folder.get_child(index % folder.get_child_count()).global_position


func add_spectator_camera():
	var camera = Camera2D.new()
	camera.name = "SpectatorCamera"
	camera.set_script(SPECTATOR_CAMERA)
	camera.bounds = get_arena_bounds()
	camera.position = camera.bounds.get_center()
	add_child(camera)

	# no player so hide the hp and portrait card (scoreboard and timer stay)
	var hud = find_child("ArenaHUD", true, false)
	if hud == null:
		return
	var player_stats = hud.get_node_or_null("PlayerStats")
	if player_stats == null:
		return
	for part in player_stats.get_children():
		part.visible = false


# the size of the arena for the spectator camera
func get_arena_bounds():
	var tiles = Rect2()
	for layer in get_children():
		if not layer is TileMapLayer:
			continue
		if not layer.tile_set or layer.get_used_rect().size == Vector2i.ZERO:
			continue
		var used = layer.get_used_rect()
		var tile = Vector2(layer.tile_set.tile_size)
		var rect = layer.global_transform * Rect2(Vector2(used.position) * tile, Vector2(used.size) * tile)
		if tiles.size == Vector2.ZERO:
			tiles = rect
		else:
			tiles = tiles.merge(rect)
	if tiles.size != Vector2.ZERO:
		return tiles

	for child in get_children():
		if child is Sprite2D and child.texture and child.z_index < 0: # background picture
			return child.global_transform * child.get_rect()

	var bounds = Rect2()
	for spawn_folder in [team_left_spawns, team_right_spawns]:
		if spawn_folder == null:
			continue
		for spawn in spawn_folder.get_children():
			if bounds.size == Vector2.ZERO and bounds.position == Vector2.ZERO:
				bounds = Rect2(spawn.global_position, Vector2.ZERO)
			else:
				bounds = bounds.expand(spawn.global_position)
	return bounds.grow(160)
