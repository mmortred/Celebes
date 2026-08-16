extends CharacterBody2D

##Public 
@export_category("Stats")
@export var move_speed = 200.0
@export var dash_speed = 700.0
@export var dash_duration = 0.15
@export var dash_cooldown = 2.0
@export var player_index = 0

##Private
@onready var camera = $Camera2D
@onready var primary_ability: Node = $PrimaryAbility
@onready var ultimate_ability: Node = $UltAbility
@onready var label: Label = $Label

var kelp_tile_count = 0 #important for overlapping kelp tiles if meron
var is_in_kelp = false
var is_revealed_from_attack = false

var print_timer = 0.0 #This is for the console to avoid print spam
var move_direction = Vector2.ZERO
var facing_direction = Vector2.DOWN
var is_dashing = false
var dash_timer = 0.0
var dash_cooldown_timer = 0.0

func _enter_tree():
	set_multiplayer_authority(int(str(name)))

func _ready():
	label.text = "Player " + str(name)          # testing player ids
	camera.enabled = is_multiplayer_authority() # only enable camera for the owning client

func _physics_process(delta):
	if not is_multiplayer_authority():
		return  # non-owners skip input AND physics entirely — position comes from sync instead

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

	print_timer -= delta # count down every frame.

	#remember the last direction the player moved.
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

			print_timer = 1.0 #one second delay after any direction.
	else:
		print_timer = 0.0 #Reset when no key is pressed.
	
	# Ability controls
	if Input.is_action_just_pressed("primary"):
		primary_ability.request_use.rpc()
	if Input.is_action_just_pressed("ultimate"):
		ultimate_ability.request_use.rpc()

	# Start a dash
	if Input.is_action_just_pressed("dash"):
		if dash_cooldown_timer <= 0 and is_dashing == false:
			start_dash()
		else:
			print("Dash is still cooling down.")

	
	if is_dashing:
		dash_player(delta)
	else:
		move_player()

	# Apply the movement and collision.
	move_and_slide()

##Movement
func move_player():
	velocity = move_direction * move_speed


##Dash Logic
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

##Kelp Logic
func enter_kelp():
	kelp_tile_count += 1
	_update_kelp_state()

func exit_kelp():
	kelp_tile_count -= 1
	_update_kelp_state()

func _update_kelp_state():
	var should_be_hidden = kelp_tile_count > 0 and not is_revealed_from_attack
	if is_multiplayer_authority():
		set_kelp_visibility.rpc(should_be_hidden)

@rpc("any_peer", "call_local")
func set_kelp_visibility(hidden: bool):
	modulate.a = 0.2 if hidden else 1.0

func reveal_from_attack():
	is_revealed_from_attack = true
	_update_kelp_state()
	await get_tree().create_timer(1.5).timeout
	is_revealed_from_attack = false
	_update_kelp_state()
