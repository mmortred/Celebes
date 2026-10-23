extends CharacterBody2D

##Public 
@export_category("Stats")
@export var move_speed = 200.0
@export var dash_speed = 700.0
@export var dash_duration = 0.15
@export var dash_cooldown = 2.0
@export var player_index = 0
@export var attack_damage = 10.0 #+
@export var swing_hit_frames = {"top_swing": 2, "bottom_swing": 2, "right_swing": 3, "left_swing": 3} #+ SWING frame where each swing's hit lands (count from 0)
@export var attack_offset = 24.0 #+ how far in front of the player the hitbox sits
@export var body_center = Vector2(0, -32) #+ SWING middle of the body, the hitbox is placed around this
@export var respawn_time = 3.0 #+ seconds dead before respawning
@export var hit_slow_percent = 0.10 #+ SLOW getting hit cuts walk speed by this much
@export var hit_slow_duration = 0.5 #+ SLOW seconds the slow lasts, another hit restarts it

##Private
@onready var camera = $Camera2D
@onready var primary_ability: Node = $PrimaryAbility
@onready var ultimate_ability: Node = $UltAbility
@onready var label: Label = $Label
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D #+
@onready var attack_range: Area2D = $AttackRange #+
@onready var health = $HealthComponent #+
@onready var death_dust = get_node_or_null("DeathDust") #+ optional particles, null if you didn't add it
@onready var pearl_indicator: Sprite2D = $PearlIndicator #+ PEARL icon above the head
@onready var launch_fx = $LaunchFX #+ LAUNCH dash effect, code lives in launch_fx.gd


#kelp stuff
var kelp_tile_count = 0
var is_hidden_in_kelp = false
var is_revealed_from_attack = false

var print_timer = 0.0 #This is for the console to avoid print spam
var move_direction = Vector2.ZERO
var facing_direction = Vector2.DOWN
var is_dashing = false
var dash_timer = 0.0
var dash_cooldown_timer = 0.0
var slow_timer = 0.0 #+ SLOW time left on the hit slow

#animatioon stuff so others can see the animation
@export var anim_name = "walk_down" #+ NEW exported so it shows in the synchronizer picker
@export var anim_frozen = true #+ NEW exported. true = standing still, hold the current frame
var is_swinging = false #+
var hit_tween = null #+ so rapid hits restart the flash instead of stacking
var is_dead = false #+
var has_pearl = false #+ PEARL set on every peer by the pearl's collected() rpc
var team = 0 #+ SPAWN 0 = Sea Nomads (left spawns), 1 = Garbage Monsters (right). set by the arena when spawning

func _enter_tree():
	var id = str(name).to_int() #+
	if id == 0: #+ name isn't a peer id (scene run alone), so use offline id 1
		id = 1 #+
	set_multiplayer_authority(id) #+
	add_to_group("players")

func _ready():
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING #+ NEW top-down: no "floor", so you can't ride other players
	label.text = LobbyManager.get_player_name(get_multiplayer_authority()) #+ NAME the username from settings
	camera.enabled = is_multiplayer_authority() # only enable camera for the owning client
	sprite.sprite_frames.set_animation_loop("top_swing", false) #+ swings must play once
	sprite.sprite_frames.set_animation_loop("bottom_swing", false) #+
	sprite.sprite_frames.set_animation_loop("right_swing", false) #+ swings must play once
	sprite.sprite_frames.set_animation_loop("left_swing", false) #+
	sprite.frame_changed.connect(_on_frame_changed) #+ used to time the hit to a frame
	health.knocked_out.connect(_on_knocked_out) #+ react when HP hits 0
	sprite.play(anim_name) #+
	pearl_indicator.visible = has_pearl #+ PEARL hidden at spawn even if left visible in the editor
	if is_multiplayer_authority(): #+ only MY player connects to MY screen's HUD
		var hud = get_tree().get_first_node_in_group("hud") #+
		if hud: #+
			hud.set_player(self) #+

func _process(_delta): #+ runs on every peer, plays whatever the owner set
	if sprite.animation != anim_name: #+
		sprite.play(anim_name) #+
	if anim_frozen: #+
		sprite.pause() #+ standing still: freeze on the current frame
	elif not sprite.is_playing() and sprite.sprite_frames.get_animation_loop(anim_name): #+
		sprite.play() #+ started moving again: resume the paused walk

func _physics_process(delta):
	if not is_multiplayer_authority():
		return  # non-owners skip input AND physics entirely — position comes from sync instead
	if is_dead: #+ dead players can't move, attack, or dash
		return #+
	
	# Reduce the dash cooldown every frame.
	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta
	if slow_timer > 0: #+ SLOW
		slow_timer -= delta #+

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
				print("up")
			elif move_direction.y > 0:
				print("DOWN")
			elif move_direction.x < 0:
				print("LEFT")
			elif move_direction.x > 0:
				print("RIGHT")

			print_timer = 1.0 #one second delay after any direction.
	else:
		print_timer = 0.0 #Reset when no key is pressed.
	
	## Basic Attack #+
	if Input.is_action_just_pressed("basic_attack"): #+ right click
		start_swing() #+
		reveal_from_attack() #+

	## Ability Controls
	if Input.is_action_just_pressed("primary"):
		primary_ability.request_use.rpc()
		reveal_from_attack()
	if Input.is_action_just_pressed("ultimate"):
		ultimate_ability.request_use.rpc()
		reveal_from_attack()

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

	update_animation() #+

##Movement
func move_player():
	var speed = move_speed #+ SLOW
	if slow_timer > 0: #+ SLOW
		speed *= 1.0 - hit_slow_percent #+ 10% slower while slowed
	velocity = move_direction * speed #+

##Animation #+
func update_animation(): #+
	if is_swinging: #+
		return #+ let the swing finish first

	anim_frozen = move_direction == Vector2.ZERO #+ no input = hold the frame

	# facing_direction = last direction moved, so standing still keeps that direction #+
	if abs(facing_direction.x) > abs(facing_direction.y): #+
		anim_name = "walk_left" if facing_direction.x < 0 else "walk_right" #+
	elif facing_direction.y < 0: #+
		anim_name = "walk_up" #+
	else: #+
		anim_name = "walk_down" #+

func start_swing(): #+
	if is_swinging: #+
		return #+
	is_swinging = true #+
	anim_frozen = false #+ swings always play, even when standing still
	var swing_dir = get_swing_direction() #+ SWING snap facing to up/down/left/right
	attack_range.position = body_center + swing_dir * attack_offset #+ SWING hitbox in front of you
	attack_range.rotation = 0.0 if swing_dir.x != 0 else PI / 2 #+ SWING tall box for left/right, lay it flat for up/down
	if swing_dir == Vector2.UP: #+ SWING
		anim_name = "top_swing" #+
	elif swing_dir == Vector2.DOWN: #+ SWING
		anim_name = "bottom_swing" #+
	elif swing_dir == Vector2.RIGHT: #+ SWING
		anim_name = "right_swing" #+ SWING
	else: #+ SWING
		anim_name = "left_swing" #+ SWING

	# End the swing after the animation's length, instead of waiting for a signal #+ NEW
	var frames = sprite.sprite_frames #+ NEW
	var swing_length = frames.get_frame_count(anim_name) / frames.get_animation_speed(anim_name) #+ NEW frames ÷ FPS = seconds
	await get_tree().create_timer(swing_length).timeout #+ NEW
	is_swinging = false #+ NEW

func get_swing_direction() -> Vector2: #+ SWING same rule as update_animation, so the swing matches the walk direction
	if abs(facing_direction.x) > abs(facing_direction.y): #+ SWING
		return Vector2.RIGHT if facing_direction.x > 0 else Vector2.LEFT #+ SWING
	return Vector2.UP if facing_direction.y < 0 else Vector2.DOWN #+ SWING

##Combat #+
func _on_frame_changed(): #+
	if not is_multiplayer_authority(): #+ only the attacker checks for hits
		return #+
	if is_dead or not is_swinging: #+
		return #+
	if sprite.frame != swing_hit_frames.get(str(sprite.animation), 2): #+ SWING each swing has its own hit frame (2 if missing)
		return #+
	for area in attack_range.get_overlapping_areas(): #+ only HurtBoxes, thanks to layer 3
		var target = area.get_parent() #+
		if target == self: #+ don't hit yourself
			continue #+
		if target.has_method("receive_hit"): #+
			target.receive_hit.rpc(attack_damage, str(name)) #+ send my name so the victim knows who hit them

@rpc("any_peer", "call_local") #+ any_peer: the attacker isn't this player's owner
func receive_hit(amount, attacker_name): #+
	if is_dead: #+ no flash on a corpse
		return #+
	var attacker = null #+
	for player in get_tree().get_nodes_in_group("players"): #+ turn the name back into the player node
		if str(player.name) == attacker_name: #+
			attacker = player #+
	health.take_damage(amount, attacker) #+
	if not is_dead: #+ the killing hit starts the fade instead of a flash
		flash_hit() #+
		slow_timer = hit_slow_duration #+ SLOW refresh, not stack: 2 quick hits = still 0.5s

func flash_hit(): #+
	if hit_tween: #+
		hit_tween.kill() #+ stop the previous flash if hit again quickly
	sprite.self_modulate = Color(1, 0.3, 0.3) #+ red tint
	hit_tween = create_tween() #+
	hit_tween.tween_property(sprite, "self_modulate", Color.WHITE, 0.2) #+ fade back to normal over 0.2s

##Pearl #+
func set_has_pearl(value): #+ PEARL called on every peer, so everyone sees the icon
	has_pearl = value #+
	pearl_indicator.visible = value #+

##Death and Respawn #+
func _on_knocked_out(): #+ runs on every peer, because take_damage runs on every peer
	is_dead = true #+
	is_swinging = false #+
	is_dashing = false #+
	velocity = Vector2.ZERO #+
	label.visible = false #+
	if hit_tween: #+
		hit_tween.kill() #+ don't let the red flash fight the fade
	sprite.self_modulate = Color.WHITE #+
	var fade = create_tween() #+
	fade.tween_property(sprite, "self_modulate:a", 0.0, 0.6) #+ fade away like dust
	if death_dust: #+
		death_dust.restart() #+ puff of dust particles
	if has_pearl and multiplayer.is_server(): #+ PEARL server drops it where I died, for everyone
		var pearl = get_tree().get_first_node_in_group("pearl") #+
		if pearl: #+
			pearl.dropped.rpc(global_position) #+

	if is_multiplayer_authority(): #+ only the owner decides when and where to respawn
		await get_tree().create_timer(respawn_time).timeout #+
		respawn.rpc(pick_spawn_point()) #+

func pick_spawn_point() -> Vector2: #+
	var spawns = get_tree().current_scene.find_child("TeamLeftSpawns" if team == 0 else "TeamRightSpawns") #+ SPAWN my own team's side
	if spawns == null or spawns.get_child_count() == 0: #+
		print("No team spawns found, respawning in place") #+
		return global_position #+
	var spawn = spawns.get_child(randi() % spawns.get_child_count()) #+ random spawn point
	return spawn.global_position #+

@rpc("authority", "call_local") #+ only the owner can respawn itself
func respawn(spawn_position: Vector2): #+
	global_position = spawn_position #+
	health.reset_full() #+
	sprite.self_modulate = Color.WHITE #+ visible again
	label.visible = true #+
	slow_timer = 0.0 #+ SLOW don't come back slowed from a hit taken before dying
	is_dead = false #+


##Dash Logic
func start_dash():
	is_dashing = true
	dash_timer = dash_duration
	dash_cooldown_timer = dash_cooldown
	reveal_from_attack()
	play_launch_fx.rpc(facing_direction) #+ LAUNCH show the effect on every screen
	print("Dash started!")

func dash_player(delta):
	velocity = facing_direction * dash_speed
	dash_timer -= delta
	# Stop dashing after the dash duration finishes.
	if dash_timer <= 0:
		is_dashing = false
		print("Dash ended.")

##Launch FX #+
@rpc("authority", "call_local") #+ LAUNCH only the owner can trigger it, runs on every peer
func play_launch_fx(direction: Vector2): #+
	launch_fx.play(direction, dash_duration) #+

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
		is_hidden_in_kelp = should_be_hidden
		set_kelp_state.rpc(should_be_hidden)
		_apply_visibility()  # update own screen
		_refresh_other_players_visibility()

func _refresh_other_players_visibility():
	for player in get_tree().get_nodes_in_group("players"):
		if player != self:
			player._apply_visibility()

@rpc("any_peer", "call_local")
func set_kelp_state(is_concealed: bool):
	is_hidden_in_kelp = is_concealed
	_apply_visibility()

func _apply_visibility():
	print(name, " - authority: ", is_multiplayer_authority(), " - hidden: ", is_hidden_in_kelp)
	if not is_hidden_in_kelp:
		modulate.a = 1.0
		return

	if is_multiplayer_authority():
		modulate.a = 0.4  # you can always see urself 
		return

	#checl if enemy is also in kelp
	var local_player = _get_local_player()
	if local_player and local_player.is_hidden_in_kelp:
		modulate.a = 0.6  # visible to all in kelp
	else:
		modulate.a = 0.0  # fully invisible to anyone not in kelp

func _get_local_player() -> Node:
	for player in get_tree().get_nodes_in_group("players"):
		if player.is_multiplayer_authority():
			return player
	return null

func reveal_from_attack():
	is_revealed_from_attack = true
	_update_kelp_state()
	await get_tree().create_timer(1.5).timeout
	is_revealed_from_attack = false
	_update_kelp_state()

@rpc("any_peer", "call_local")
func set_kelp_visibility(is_concealed: bool):
	modulate.a = 0.2 if is_concealed else 1.0
