extends ability_base

# Spear Thrust - bugis ability 1, a long stab that hits the closest enemy in front of him
# only his own pc checks who got hit

const DAMAGE = 25
const RANGE = 90.0 # 1.5x melee range
const COOLDOWN = 7.0
const HIT_DELAY = 0.3 # wait for the lunge frame
const TRAIL_OFFSET = 44.0 # the trail starts at his spear, this is half of its length
const TRAIL_Y = 10.0 # the spear is held lower than the middle of the body
const TRAIL = preload("res://Celebes Abyssal Tides/scenes/player/fx/SeaNomad/Bugis/SpearThrustTrail.tscn")


# in _ready so these win over the numbers saved in the character scene
func _ready():
	ability_name = "Spear Thrust"
	cooldown_time = COOLDOWN


func get_stats():
	return "Long stab at the closest enemy in front
Damage: %d
Range: %d" % [DAMAGE, RANGE]


func _execute(caster):
	if not is_instance_valid(caster):
		return
	SFXManager.play_at("spear_thrust", caster.global_position)
	var direction = aim_direction
	await get_tree().create_timer(HIT_DELAY).timeout
	if not is_instance_valid(caster) or caster.is_dead:
		return
	# water streak along the stab (every pc)
	var trail = spawn_fx(caster, TRAIL, center_of(caster) + direction * TRAIL_OFFSET + Vector2(0, TRAIL_Y * absf(direction.x)))
	trail.rotation = direction.angle()

	if not caster.is_multiplayer_authority():
		return

	var target = find_closest_enemy(caster, center_of(caster), RANGE, direction)
	if target:
		caster.deal_damage(target, DAMAGE)
