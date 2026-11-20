class_name ability_base
extends Node

# base for all abilities, the other abilities extend this
# request_use is an rpc so use() and _execute() run on every pc.
# the effects show everywhere, but only the casters own pc deals the damage (check is_multiplayer_authority)

@export var cooldown_time = 1.0
@export var ability_name = "Ability"
@export var effect_animation = &"" # which animation of AnimatedAbility plays ("primary" or "ultimate")
@export var ready_sound_min_cooldown = 3.0 # the ready ping only plays for abilities with at least this cooldown
@export var aim_with_mouse = false # true = goes exactly where the mouse is, false = up, down, left or right toward the mouse

const ICON_FOLDER = "res://Celebes Abyssal Tides/assets/ui/abilities/"

var cooldown_timer = 0.0
var is_on_cooldown = false
var aim_direction = Vector2.DOWN # sent with request_use so every pc uses the same direction
var aim_distance = 0.0 # how far the mouse was from the middle of the body (aimed abilities)


func _process(delta):
	if is_on_cooldown:
		cooldown_timer -= delta
		if cooldown_timer <= 0:
			is_on_cooldown = false
			_play_ready_sound()


# only the owner hears it
func _play_ready_sound():
	if cooldown_time < ready_sound_min_cooldown:
		return
	if not get_parent().is_multiplayer_authority() or get_parent().is_dead:
		return
	SFXManager.play_ui("ability_ready")


func can_use():
	return not is_on_cooldown


func use(caster):
	if not can_use():
		return
	if caster.is_dead or caster.stun_timer > 0:
		return # cant use abilities while dead or stunned
	is_on_cooldown = true
	cooldown_timer = cooldown_time
	caster.face_toward(aim_direction) # turn to the mouse so the pose matches on every pc
	if caster.has_method("play_ability_effect"):
		caster.play_ability_effect(effect_animation)
	if effect_animation == &"ultimate":
		SFXManager.play_at("heavy_attack", caster.global_position)
	_execute(caster)


# my own pc picks the direction and sends it, so the other pcs dont have to guess
@rpc("any_peer", "call_local")
func request_use(aim: Vector2):
	var caster = get_parent()
	if aim == Vector2.ZERO:
		aim = caster.get_swing_direction()
	aim_direction = aim.normalized()
	aim_distance = aim.length()
	use(caster)


# where this ability goes, only my own pc calls this
# aimed abilities go exactly at the mouse, the others go up, down, left or right (whichever is closest to the mouse)
func pick_aim(caster):
	if aim_with_mouse:
		return caster.get_mouse_offset()
	return caster.snap_direction(caster.get_mouse_direction())


# each ability changes this one
func _execute(caster):
	pass


# the stats in the hover box on the hud, each ability writes its own from its numbers
func get_stats():
	return ""


func get_info():
	var text = ability_name
	var stats = get_stats()
	if stats != "":
		text += "
" + stats
	text += "
Cooldown: " + str(snappedf(cooldown_time, 0.1)) + "s"
	return text


# the hud icon, the png has the same name as the ability ("Spear Thrust" -> spear_thrust.png)
func get_icon():
	var path = ICON_FOLDER + ability_name.to_snake_case() + ".png"
	if ResourceLoader.exists(path):
		return load(path)
	return null


# ---------------- helpers the abilities share ----------------

# middle of the body in the world
func center_of(player):
	return player.global_position + player.body_center


# enemies that are alive and close to the point. direction = only the ones in front (Vector2.ZERO = all around)
func find_enemies(caster, center, radius, direction = Vector2.ZERO):
	var found = []
	for player in caster.get_tree().get_nodes_in_group("players"):
		if player == caster or player.team == caster.team or player.is_dead:
			continue
		var offset = center_of(player) - center
		if offset.length() > radius:
			continue
		if direction != Vector2.ZERO and offset.length() > 8.0 and offset.normalized().dot(direction) < 0.5:
			continue # not in front
		found.append(player)
	return found


# the closest one from find_enemies, or null
func find_closest_enemy(caster, center, radius, direction = Vector2.ZERO):
	var best = null
	var best_distance = radius + 1.0
	for player in find_enemies(caster, center, radius, direction):
		var distance = center_of(player).distance_to(center)
		if distance < best_distance:
			best = player
			best_distance = distance
	return best


# puts an effect scene in the world (every pc does this so everyone sees it)
# life is set before add_child, ability_fx reads it in _ready (0 = gone when the animation ends)
func spawn_fx(caster, scene, where, life = 0.0):
	var fx = scene.instantiate()
	fx.life = life
	caster.get_tree().current_scene.add_child(fx)
	fx.global_position = where
	fx.z_index = 1 # the arena sorts by y, this keeps the effect from going under the floor tiles
	return fx
