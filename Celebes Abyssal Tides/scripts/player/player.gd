extends CharacterBody2D # controls a player that can move and collide.

@export var move_speed := 200.0 # Normal movement speed.
@export var dash_speed := 700.0 # Faster speed used while dashing.
@export var dash_duration := 0.15 # How long the dash lasts.
@export var dash_cooldown := 2.0 # Wait time before another dash.

var desired_move_direction := Vector2.ZERO # The direction the player wants to move.
var facing_direction := Vector2.DOWN # The last direction the player moved.

var is_dashing := false # Checks if player is currently dashing.
var dash_timer := 0.0 
var dash_cooldown_timer := 0.0 

func _physics_process(delta: float) -> void:
	dash_cooldown_timer = maxf(0.0, dash_cooldown_timer - delta) 

	read_input() # Check keyboard input.

	if is_dashing: # Use dash movement when dashing.
		do_dash_movement(delta)
	else: # Otherwise, use normal movement.
		do_normal_movement()

	move_and_slide() # Move the player and stop at walls.

func read_input() -> void:
	var input_vector := Input.get_vector(
		"move_up", # W
		"move_left", # A
		"move_down", # S
		"move_right" # D
	)

	desired_move_direction = input_vector # Save the movement direction.

	if input_vector != Vector2.ZERO: # Only update direction if moving.
		facing_direction = input_vector # Remember where the player faces.

	if Input.is_action_just_pressed("dash"): # Check if Space was pressed.
		if dash_cooldown_timer <= 0.0 and not is_dashing: # Dash only when ready.
			start_dash() # Begin the dash.

func do_normal_movement() -> void:
	velocity = desired_move_direction * move_speed # Move at normal speed.

func start_dash() -> void:
	is_dashing = true # Mark the player as dashing.
	dash_timer = dash_duration # Set dash time.
	dash_cooldown_timer = dash_cooldown # Start dash cooldown.
	velocity = facing_direction * dash_speed # Set fast dash movement.

func do_dash_movement(delta: float) -> void:
	velocity = facing_direction * dash_speed # Keep moving quickly.
	dash_timer -= delta # Reduce remaining dash time.

	if dash_timer <= 0.0: # Stop once time runs out.
		is_dashing = false # Return to normal movement.
