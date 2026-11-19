class_name ability_base
extends Node

# base for all abilities, the other abilities extend this
# request_use is an rpc so use() and _execute() run on every pc.
# the effects show everywhere, but only the casters own pc deals the damage (check is_multiplayer_authority)

@export var cooldown_time = 1.0
@export var ability_name = "Ability"
@export var effect_animation = &"" # which animation of AnimatedAbility plays ("primary" or "ultimate")

const ICON_FOLDER = "res://Celebes Abyssal Tides/assets/ui/abilities/"

var cooldown_timer = 0.0
var is_on_cooldown = false


func _process(delta):
	if is_on_cooldown:
		cooldown_timer -= delta
		if cooldown_timer <= 0:
			is_on_cooldown = false


func can_use():
	return not is_on_cooldown


func use(caster):
	if not can_use():
		return
	if caster.is_dead or caster.stun_timer > 0:
		return # cant use abilities while dead or stunned
	is_on_cooldown = true
	cooldown_timer = cooldown_time
	if caster.has_method("play_ability_effect"):
		caster.play_ability_effect(effect_animation)
	_execute(caster)


@rpc("any_peer", "call_local")
func request_use():
	use(get_parent())


# each ability changes this one
func _execute(caster):
	pass


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
func spawn_fx(caster, scene, where):
	var fx = scene.instantiate()
	caster.get_tree().current_scene.add_child(fx)
	fx.global_position = where
	fx.z_index = 1 # the arena sorts by y, this keeps the effect from going under the floor tiles
	return fx
