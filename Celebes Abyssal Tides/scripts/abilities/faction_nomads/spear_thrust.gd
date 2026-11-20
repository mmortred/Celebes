extends ability_base

# Spear Thrust - bugis ability 1, a long stab that hits the closest enemy in front of him
# only his own pc checks who got hit

const DAMAGE = 25
const RANGE = 90.0 # 1.5x melee range
const COOLDOWN = 7.0
const HIT_DELAY = 0.3 # wait for the lunge frame


# in _ready so these win over the numbers saved in the character scene
func _ready():
	ability_name = "Spear Thrust"
	cooldown_time = COOLDOWN


func _execute(caster):
	if not is_instance_valid(caster):
		return
	SFXManager.play_at("spear_thrust", caster.global_position)
	if not caster.is_multiplayer_authority():
		return

	var direction = caster.get_swing_direction()
	await get_tree().create_timer(HIT_DELAY).timeout
	if not is_instance_valid(caster) or caster.is_dead:
		return

	var target = find_closest_enemy(caster, center_of(caster), RANGE, direction)
	if target:
		caster.deal_damage(target, DAMAGE)
