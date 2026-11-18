extends CharacterBody2D

@export_category("Stats")
@export var move_speed = 170.0
@export var dash_speed = 700.0
@export var dash_duration = 0.15
@export var dash_cooldown = 10.0
@export var player_index = 0
@export var attack_damage = 15.0 # the average hit
@export var damage_spread = 0.33 # so that the damge is 10 - 20 
@export var swing_hit_frames = {"top_swing": 2, "bottom_swing": 2, "right_swing": 3, "left_swing": 3} # what frame the hit lands (starts at 0)
@export var attack_offset = 24.0 # how far the hitbox is in front of the player
@export var body_center = Vector2(0, -32) # middle of the body
@export var respawn_time = 6.0
@export var serpent_respawn_time = 4.0 # shorter in the last 2 minutes so the end stays busy
@export var hit_slow_percent = 0.10 # 10% slower when you get hit
@export var hit_slow_duration = 0.5
@export var tuna_rush_time = 15.0
@export var tuna_speed_bonus = 0.2 # 20% faster with the tuna rush
@export var carrier_slow = 0.15 # 15% slower while carrying the pearl

const DAMAGE_NUMBER = preload("res://Celebes Abyssal Tides/scenes/player/DamageNumber.tscn")

@onready var camera = $Camera2D
@onready var primary_ability = $PrimaryAbility
@onready var ultimate_ability = $UltAbility
@onready var label = $Label
@onready var sprite = $AnimatedSprite2D
@onready var attack_range = $AttackRange
@onready var health = $HealthComponent
@onready var death_dust = get_node_or_null("DeathDust")
@onready var pearl_indicator = $PearlIndicator # pearl icon on top of the head
@onready var launch_fx = $LaunchFX

# kelp
var kelp_tile_count = 0
var is_hidden_in_kelp = false
var is_revealed_from_attack = false

var print_timer = 0.0 # so the console doesnt get spammed
var move_direction = Vector2.ZERO
var facing_direction = Vector2.DOWN
var is_dashing = false
var dash_timer = 0.0
var dash_direction = Vector2.DOWN
var dash_cooldown_timer = 0.0
var slow_timer = 0.0
var respawn_timer = 0.0 # counts down while dead, the hud shows it
var tuna_rush_timer = 0.0 # faster and shorter dash cooldown while this is more than 0

# exported so the other players can see my animation
@export var anim_name = "walk_down"
@export var anim_frozen = true
var is_swinging = false
var hit_tween = null # red flash when hit
var is_dead = false
var has_pearl = false
var cutscene_frozen = false
@export var net_position = Vector2.ZERO # for smooth movement in multiplayer
const SMOOTHING = 18.0
const SNAP_DISTANCE = 200.0 # if further than this just teleport
var team = 0 # 0 = Sea Nomads (left), 1 = Garbage Monsters (right). the arena sets this
var character = -1 # character id from character select (0 Bugis, 5 Toxic Sludge). the arena sets this


func _enter_tree():
	var id = str(name).to_int()
	if id == 0:
		id = 1 # scene was run alone so use 1
	set_multiplayer_authority(id)
	add_to_group("players")


func _ready():
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING # so you cant stand on other players
	net_position = position

	label.text = LobbyManager.get_player_name(get_multiplayer_authority())
	label.add_theme_font_override("font", GameManager.PIXEL_FONT)
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_constant_override("outline_size", 4)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_color_override("font_color", GameManager.TEAM_COLORS.get(team, Color.WHITE))

	camera.enabled = is_multiplayer_authority() # only my camera

	# swings only play once
	for swing in ["top_swing", "bottom_swing", "right_swing", "left_swing"]:
		sprite.sprite_frames.set_animation_loop(swing, false)

	sprite.frame_changed.connect(_on_frame_changed)
	health.knocked_out.connect(_on_knocked_out)
	sprite.play(anim_name)
	pearl_indicator.visible = has_pearl
	_add_feet_shadow()

	# connect my player to my hud
	if is_multiplayer_authority():
		var hud = get_tree().get_first_node_in_group("hud")
		if hud:
			hud.set_player(self)


# runs on every peer
func _process(delta):
	if is_multiplayer_authority():
		net_position = position
	elif position.distance_to(net_position) > SNAP_DISTANCE:
		position = net_position # too far (respawn), just teleport
	else:
		position = position.lerp(net_position, 1.0 - exp(-SMOOTHING * delta)) # glide there

	# here and not in _physics_process so every pc counts it (the hud and the other players)
	if tuna_rush_timer > 0:
		tuna_rush_timer -= delta

	if sprite.animation != anim_name:
		sprite.play(anim_name)
	if anim_frozen:
		sprite.pause() # standing still
	elif not sprite.is_playing() and sprite.sprite_frames.get_animation_loop(anim_name):
		sprite.play() # walking again


func _physics_process(delta):
	if not is_multiplayer_authority():
		return # other players positions come from the sync
	if is_dead:
		count_respawn(delta)
		return
	if cutscene_frozen:
		velocity = Vector2.ZERO
		anim_frozen = true
		return

	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta
	if slow_timer > 0:
		slow_timer -= delta

	move_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")

	print_timer -= delta
	if move_direction != Vector2.ZERO:
		if not is_dashing:
			facing_direction = move_direction # remember last direction (not while dashing)
		if print_timer <= 0:
			if move_direction.y < 0:
				print("up")
			elif move_direction.y > 0:
				print("DOWN")
			elif move_direction.x < 0:
				print("LEFT")
			elif move_direction.x > 0:
				print("RIGHT")
			print_timer = 1.0 # 1 sec delay
	else:
		print_timer = 0.0

	if Input.is_action_just_pressed("basic_attack"):
		start_swing()
		reveal_from_attack()

	if Input.is_action_just_pressed("primary"):
		primary_ability.request_use.rpc()
		reveal_from_attack()
	if Input.is_action_just_pressed("ultimate"):
		ultimate_ability.request_use.rpc()
		reveal_from_attack()

	if Input.is_action_just_pressed("dash"):
		if dash_cooldown_timer <= 0 and is_dashing == false:
			start_dash()
		else:
			print("Dash is still cooling down.")

	if is_dashing:
		dash_player(delta)
	else:
		move_player()

	move_and_slide()
	update_animation()


# dark oval under the feet, same width as the feet collision
func _add_feet_shadow():
	var gradient = Gradient.new()
	gradient.set_color(0, Color(0, 0, 0, 0.6)) # dark middle
	gradient.set_color(1, Color(0, 0, 0, 0)) # see through edge
	var texture = GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)

	var feet = $CollisionShape2D
	var width = 26.0
	if feet.shape is CapsuleShape2D:
		width = feet.shape.height + 6.0

	var shadow = Sprite2D.new()
	shadow.name = "FeetShadow"
	shadow.texture = texture
	shadow.position = Vector2(0, _feet_ground_y())
	shadow.scale = Vector2(width, 8.0) / 64.0 # the gradient texture is 64x64
	add_child(shadow)
	move_child(shadow, 0) # first child so its under the sprite


# finds the lowest pixel of the first walk_down frame (where the feet are)
func _feet_ground_y():
	var fallback = $CollisionShape2D.position.y
	if not sprite.sprite_frames.has_animation("walk_down"):
		return fallback
	var frame = sprite.sprite_frames.get_frame_texture("walk_down", 0)
	if frame == null:
		return fallback
	var image = frame.get_image()
	if image == null:
		return fallback

	# start from the bottom row going up
	var y = image.get_height() - 1
	while y >= 0:
		for x in image.get_width():
			if image.get_pixel(x, y).a > 0.15:
				var top = 0.0
				if sprite.centered:
					top = -image.get_height() / 2.0
				return sprite.position.y + (sprite.offset.y + top + y - 1.0) * sprite.scale.y # 1px up so its under the feet
		y -= 1
	return fallback


func move_player():
	var speed = move_speed
	if slow_timer > 0:
		speed *= 1.0 - hit_slow_percent
	if tuna_rush_timer > 0:
		speed *= 1.0 + tuna_speed_bonus
	if has_pearl:
		speed *= 1.0 - carrier_slow
	velocity = move_direction * speed


func update_animation():
	if is_swinging:
		return # let the swing finish

	anim_frozen = move_direction == Vector2.ZERO # no input = stop on the frame

	# use the last direction so standing still keeps facing the same way
	if abs(facing_direction.x) > abs(facing_direction.y):
		if facing_direction.x < 0:
			anim_name = "walk_left"
		else:
			anim_name = "walk_right"
	elif facing_direction.y < 0:
		anim_name = "walk_up"
	else:
		anim_name = "walk_down"


func start_swing():
	if is_swinging:
		return
	is_swinging = true
	_play_attack_sound.rpc()
	anim_frozen = false # swing plays even if standing still

	# put the hitbox in front
	var swing_dir = get_swing_direction()
	attack_range.position = body_center + swing_dir * attack_offset
	if swing_dir.x != 0:
		attack_range.rotation = 0.0 # tall box for left and right
	else:
		attack_range.rotation = PI / 2 # flat box for up and down

	if swing_dir == Vector2.UP:
		anim_name = "top_swing"
	elif swing_dir == Vector2.DOWN:
		anim_name = "bottom_swing"
	elif swing_dir == Vector2.RIGHT:
		anim_name = "right_swing"
	else:
		anim_name = "left_swing"

	# wait for the whole swing animation to finish
	var frames = sprite.sprite_frames
	var swing_length = 0.0
	for i in frames.get_frame_count(anim_name):
		swing_length += frames.get_frame_duration(anim_name, i)
	swing_length /= frames.get_animation_speed(anim_name) * absf(sprite.speed_scale)
	await get_tree().create_timer(swing_length).timeout
	is_swinging = false
	update_animation() # back to walking right away


# same rule as update_animation so the swing matches where you face
func get_swing_direction():
	if abs(facing_direction.x) > abs(facing_direction.y):
		if facing_direction.x > 0:
			return Vector2.RIGHT
		return Vector2.LEFT
	if facing_direction.y < 0:
		return Vector2.UP
	return Vector2.DOWN


func roll_damage() -> int:
	var low = int(attack_damage * (1.0 - damage_spread))
	var high = int(attack_damage * (1.0 + damage_spread))
	return (randi_range(low, high) + randi_range(low, high)) / 2  # int division, stays low..high


func _on_frame_changed():
	if not is_multiplayer_authority():
		return # only the attacker checks hits
	if is_dead or not is_swinging:
		return
	if sprite.frame != swing_hit_frames.get(str(sprite.animation), 2):
		return # not the hit frame yet

	for area in attack_range.get_overlapping_areas(): # only hurtboxes (layer 3)
		var target = area.get_parent()
		if target == self:
			continue
		if target.has_method("receive_hit"):
			target.receive_hit.rpc(roll_damage(), str(name)) # send my name so they know who hit them


@rpc("any_peer", "call_local") # any_peer because the attacker is not the owner
func receive_hit(amount, attacker_name):
	if is_dead:
		return

	# find the attacker from the name
	var attacker = null
	for player in get_tree().get_nodes_in_group("players"):
		if str(player.name) == attacker_name:
			attacker = player

	# only the host saves the scoreboard so it doesnt count twice
	var is_host = multiplayer.multiplayer_peer != null and multiplayer.is_server()
	var was_alive = health.current_health > 0.0
	if is_host and was_alive:
		ScoreboardManager.record_damage(str(name).to_int(), str(attacker_name).to_int())

	health.take_damage(amount, attacker)
	# carrying the pearl into the well? the hit starts the channel over
	if is_host and has_pearl:
		for well in get_tree().get_nodes_in_group("wells"):
			well.interrupt_channel(self)
	if was_alive:
		show_damage_number(amount)
	if team == 0:
		SFXManager.play_at("hurt_sea", global_position)
	else:
		SFXManager.play_at("hurt_garbage", global_position)

	if is_host and was_alive and health.current_health <= 0.0:
		ScoreboardManager.record_death(str(name).to_int(), str(attacker_name).to_int())

	if not is_dead:
		flash_hit()
		slow_timer = hit_slow_duration # resets, doesnt stack


# every pc makes its own number, it only changes how it looks so no rpc
func show_damage_number(amount):
	if modulate.a == 0.0:
		return # hiding in kelp, dont give them away
	var number = DAMAGE_NUMBER.instantiate()
	get_tree().current_scene.add_child(number)
	number.global_position = global_position + body_center + Vector2(randf_range(-8, 8), -16) # random so the numbers dont stack
	number.show_damage(amount)


func flash_hit():
	if hit_tween:
		hit_tween.kill() # stop the old flash
	sprite.self_modulate = Color(1, 0.3, 0.3) # red
	hit_tween = create_tween()
	hit_tween.tween_property(sprite, "self_modulate", Color.WHITE, 0.2)


# called on every peer so everyone sees the pearl icon
func set_has_pearl(value):
	has_pearl = value
	pearl_indicator.visible = value


# runs on every peer
func _on_knocked_out():
	is_dead = true
	is_swinging = false
	is_dashing = false
	velocity = Vector2.ZERO
	label.visible = false
	$FeetShadow.visible = false
	if hit_tween:
		hit_tween.kill()
	sprite.self_modulate = Color.WHITE
	var fade = create_tween()
	fade.tween_property(sprite, "self_modulate:a", 0.0, 0.6)
	if death_dust:
		death_dust.restart()

	# host drops the pearl where i died
	if has_pearl and multiplayer.is_server():
		var pearl = get_tree().get_first_node_in_group("pearl")
		if pearl:
			pearl.dropped.rpc(global_position)

	tuna_rush_timer = 0.0 # you lose the tuna rush when you die

	# only the owner respawns, _physics_process counts it down
	if is_multiplayer_authority():
		respawn_timer = get_respawn_time()


func get_respawn_time():
	if GameManager.state == GameManager.MatchState.SERPENT_RISING:
		return serpent_respawn_time
	return respawn_time


# not an await timer, because the serpent cutscene can respawn you first and then you would respawn twice
func count_respawn(delta):
	if respawn_timer <= 0:
		return # already respawned or waiting for the rpc
	respawn_timer -= delta
	if respawn_timer <= 0:
		respawn.rpc(pick_spawn_point())


func pick_spawn_point():
	var arena = get_tree().current_scene
	if arena.has_method("get_respawn_position"):
		return arena.get_respawn_position(team) # arena knows the right spawns (changes after 5 min)

	var spawns = null
	if team == 0:
		spawns = arena.find_child("TeamLeftSpawns")
	else:
		spawns = arena.find_child("TeamRightSpawns")
	if spawns == null or spawns.get_child_count() == 0:
		print("No team spawns found, respawning in place")
		return global_position

	var spawn = spawns.get_child(randi() % spawns.get_child_count()) # random one
	return spawn.global_position


@rpc("authority", "call_local")
func respawn(spawn_position: Vector2):
	global_position = spawn_position
	health.reset_full()
	sprite.self_modulate = Color.WHITE
	label.visible = true
	$FeetShadow.visible = true
	slow_timer = 0.0
	respawn_timer = 0.0
	is_dead = false
	SFXManager.play_at("respawn", global_position)


# everyone calls this when the tuna run says who caught it
func start_tuna_rush():
	tuna_rush_timer = tuna_rush_time


func start_dash():
	is_dashing = true
	dash_timer = dash_duration
	dash_cooldown_timer = dash_cooldown
	if tuna_rush_timer > 0:
		dash_cooldown_timer = dash_cooldown / 2.0 # tuna rush = half the cooldown
	dash_direction = facing_direction.normalized() # save it so the dash goes straight
	reveal_from_attack()
	play_launch_fx.rpc(dash_direction)
	_play_dash_sound.rpc()
	print("Dash started!")


func dash_player(delta):
	velocity = dash_direction * dash_speed # same direction the whole dash, you cant steer it
	dash_timer -= delta
	if dash_timer <= 0:
		is_dashing = false
		print("Dash ended.")


@rpc("authority", "call_local")
func play_launch_fx(direction: Vector2):
	launch_fx.play(direction, dash_duration)


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
		_apply_visibility()
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
		modulate.a = 0.4 # you can always see urself
		return

	# check if im also in kelp
	var local_player = _get_local_player()
	if local_player and local_player.is_hidden_in_kelp:
		modulate.a = 0.6 # both in kelp so you can see them
	else:
		modulate.a = 0.0 # invisible


func _get_local_player():
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
	if is_concealed:
		modulate.a = 0.2
	else:
		modulate.a = 1.0


@rpc("authority", "call_local", "unreliable")
func _play_attack_sound():
	if team == 0:
		SFXManager.play_at("attack_sea", global_position)
	else:
		SFXManager.play_at("attack_garbage", global_position)


@rpc("authority", "call_local", "unreliable")
func _play_dash_sound():
	SFXManager.play_at("dash", global_position)
