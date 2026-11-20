extends ability_base

# Contaminate - toxic sludge ability 2, flings poison goo at the closest enemy in front of him
# their hits do 30% less damage for 3 seconds. only his own pc picks who gets hit

const WEAKEN_PERCENT = 0.3 # their damage goes down 30%
const WEAKEN_TIME = 3.0
const RANGE = 78.0 # 1.3x melee range
const COOLDOWN = 9.0
const HIT_DELAY = 0.4 # wait for the glob to land


# in _ready so these win over the numbers saved in the character scene
func _ready():
	ability_name = "Contaminate"
	cooldown_time = COOLDOWN


func _execute(caster):
	if not is_instance_valid(caster):
		return
	SFXManager.play_at("bubble_strike", caster.global_position)
	if not caster.is_multiplayer_authority():
		return

	var direction = caster.get_swing_direction()
	await get_tree().create_timer(HIT_DELAY).timeout
	if not is_instance_valid(caster) or caster.is_dead:
		return
	var target = find_closest_enemy(caster, center_of(caster), RANGE, direction)
	if target:
		target.apply_weaken.rpc(WEAKEN_PERCENT, WEAKEN_TIME)
