extends Node2D

const SPECTATOR_CAMERA = preload("res://Celebes Abyssal Tides/scripts/arena/spectator_camera.gd")

@onready var team_left_spawns = $TeamLeftSpawns
@onready var team_right_spawns = $TeamRightSpawns

func _ready() -> void:
	print("Arena loaded!")

	var left_spawn = get_random_spawn_position("left")
	var right_spawn = get_random_spawn_position("right")

	print("Left spawn: ", left_spawn)
	print("Right spawn: ", right_spawn)

	# spectators get no player, just a camera they can pan around the arena
	if NetworkManager.get_meta("character_select_team", "") == "spectator":
		add_spectator_camera()


func add_spectator_camera() -> void:
	var camera := Camera2D.new()
	camera.name = "SpectatorCamera"
	camera.set_script(SPECTATOR_CAMERA)
	camera.bounds = get_arena_bounds()
	camera.position = camera.bounds.get_center()
	add_child(camera)
	# no player of their own, so no HP / portrait card; scoreboard and timer stay.
	# hide what's inside the card: the HUD's intro animation turns the card itself back on
	var player_stats := get_node_or_null("HUDLayer/ArenaHUD/PlayerStats")
	if player_stats:
		for part in player_stats.get_children():
			part.visible = false


# World rect of what is actually drawn, used to keep the spectator camera in:
# the painted tiles, else the background picture, else the spawn points.
func get_arena_bounds() -> Rect2:
	var tilemap: TileMapLayer = get_node_or_null("TileMap")
	if tilemap and tilemap.tile_set and tilemap.get_used_rect().size != Vector2i.ZERO:
		var used := tilemap.get_used_rect()
		var tile := Vector2(tilemap.tile_set.tile_size)
		return tilemap.global_transform * Rect2(Vector2(used.position) * tile, Vector2(used.size) * tile)
	for child in get_children():
		if child is Sprite2D and child.texture and child.z_index < 0: # background picture
			return child.global_transform * child.get_rect()
	var bounds := Rect2()
	for spawn_folder in [team_left_spawns, team_right_spawns]:
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
