extends ability_base

# Crushing Slam - rusty leviathan ability 1, smashes the anchor down in front of him
# hits the enemies there, pushes them back and stuns them. only his own pc deals the damage

const DAMAGE = 35
const RANGE = 78.0 # 1.3x melee range
const PUSH = 60.0 # how far they get pushed
const STUN_TIME = 0.5
const COOLDOWN = 8.0
const HIT_DELAY = 0.4 # wait for the anchor to hit the ground
const CRACK = preload("res://Celebes Abyssal Tides/scenes/player/fx/Monsters/RustyLeviathan/SlamCrack.tscn")


# in _ready so these win over the numbers saved in the character scene
func _ready():
	ability_name = "Crushing Slam"
	cooldown_time = COOLDOWN


func get_stats():
	return "Smashes the anchor in front, pushes back and stuns
Damage: %d
Stun: %ss
Range: %d" % [DAMAGE, STUN_TIME, RANGE]


func _execute(caster):
	if not is_instance_valid(caster):
		return
	var direction = aim_direction
	await get_tree().create_timer(HIT_DELAY).timeout
	if not is_instance_valid(caster) or caster.is_dead:
		return
	SFXManager.play_at("spear_thrust", caster.global_position)
	# crack in the ground where the anchor lands (every pc)
	spawn_fx(caster, CRACK, caster.global_position + direction * RANGE * 0.5)

	if not caster.is_multiplayer_authority():
		return
	for target in find_enemies(caster, center_of(caster), RANGE, direction):
		caster.deal_damage(target, DAMAGE)
		target.knock_back.rpc(direction * PUSH)
		target.stun.rpc(STUN_TIME + caster.knockback_time) # the stun starts after the push
