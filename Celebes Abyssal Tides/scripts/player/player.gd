extends CharacterBody2D

var move_speed = 200.0
var dash_speed = 700.0
var dash_duration = 0.15
var dash_cooldown = 2.0

var print_timer = 0.0 #This is for the console to avoid print spam

var move_direction = Vector2.ZERO
var facing_direction = Vector2.DOWN

var is_dashing = false
var dash_timer = 0.0
var dash_cooldown_timer = 0.0

func _physics_process(delta):
	# Reduce the dash cooldown every frame.
	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta

	# Get movement from the Input Map.
	move_direction = Input.get_vector(
		"move_left",
		"move_right",
		"move_up",
		"move_down"
	)
	print_timer -= delta # Count down every frame.

	# Remember the last direction the player moved.
# Remember the last direction the player moved.
	if move_direction != Vector2.ZERO:
		facing_direction = move_direction
	
		if print_timer <= 0:
			if move_direction.y < 0:
				print("UP")
			elif move_direction.y > 0:
				print("DOWN")
			elif move_direction.x < 0:
				print("LEFT")
			elif move_direction.x > 0:
				print("RIGHT")
	
			print_timer = 1.0 # One-second delay after any direction.
	else:
		print_timer = 0.0 # Reset when no key is pressed.

	# Start a dash when Space is pressed and dash is ready.
	if Input.is_action_just_pressed("dash"):
		if dash_cooldown_timer <= 0 and is_dashing == false:
			start_dash()
		else:
			print("Dash is still cooling down.")

	# Choose dash movement or normal movement.
	if is_dashing:
		dash_player(delta)
	else:
		move_player()

	# Apply the movement and collision.
	move_and_slide()

func move_player():
	velocity = move_direction * move_speed

func start_dash():
	is_dashing = true
	dash_timer = dash_duration
	dash_cooldown_timer = dash_cooldown
	print("Dash started!")

func dash_player(delta):
	velocity = facing_direction * dash_speed
	dash_timer -= delta

	# Stop dashing after the dash duration finishes.
	if dash_timer <= 0:
		is_dashing = false
		print("Dash ended.")
