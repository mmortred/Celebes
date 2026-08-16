extends Node2D

@onready var team_left_spawns = $TeamLeftSpawns
@onready var team_right_spawns = $TeamRightSpawns

func _ready() -> void:
	print("Arena loaded!")

	var left_spawn = get_random_spawn_position("left")
	var right_spawn = get_random_spawn_position("right")

	print("Left spawn: ", left_spawn)
	print("Right spawn: ", right_spawn)

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
