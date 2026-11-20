extends ability_base

# Shield Bash - minahasan ability 1, hits the enemies in front of him, pushes them back and stuns them
# only his own pc checks who got hit, same as the basic attack

const DAMAGE = 15
const RANGE = 72.0
const PUSH = 60.0 # how far they get pushed
const STUN_TIME = 0.5 # stunned after the push
const COOLDOWN = 10.0
const HIT_DELAY = 0.15 # wait for the frame where the shield hits


# in _ready so these win over the numbers saved in the character scene
func _ready():
	ability_name = "Shield Bash"
	cooldown_time = COOLDOWN


func get_stats():
	return "Hits the enemies in front, pushes them back and stuns
Damage: %d
Stun: %ss
Range: %d" % [DAMAGE, STUN_TIME, RANGE]


func _execute(caster):
	if not is_instance_valid(caster):
		return
	SFXManager.play_at("spear_thrust", caster.global_position)
	if not caster.is_multiplayer_authority():
		return

	var direction = aim_direction
	await get_tree().create_timer(HIT_DELAY).timeout
	if not is_instance_valid(caster) or caster.is_dead:
		return

	for target in find_enemies(caster, center_of(caster), RANGE, direction):
		caster.deal_damage(target, DAMAGE)
		target.knock_back.rpc(direction * PUSH)
		target.stun.rpc(STUN_TIME + caster.knockback_time) # the stun starts after the push
