extends ability_base

# Plastic Shot - plastic hoard ability 1, fires a big bottle that hits the first enemy it touches
# the shot is made on every pc (player.gd fire_projectile), only his own copy deals the damage

const DAMAGE = 25
const RANGE = 600.0 # 2x attack range
const SPEED = 520.0
const COOLDOWN = 10.0
const FIRE_DELAY = 0.35 # wait for the blast frame
const SHOT = "res://Celebes Abyssal Tides/scenes/player/fx/Monsters/PlasticHoard/PlasticShotBolt.tscn"


# in _ready so these win over the numbers saved in the character scene
func _ready():
	ability_name = "Plastic Shot"
	cooldown_time = COOLDOWN
	aim_with_mouse = true


func get_stats():
	return "Big bottle that hits the first enemy, aim with the mouse
Damage: %d
Range: %d" % [DAMAGE, RANGE]


func _execute(caster):
	if not is_instance_valid(caster):
		return
	SFXManager.play_at("bubble_strike", caster.global_position)
	if not caster.is_multiplayer_authority():
		return

	var direction = aim_direction
	await get_tree().create_timer(FIRE_DELAY).timeout
	if not is_instance_valid(caster) or caster.is_dead:
		return
	caster.fire_projectile.rpc(SHOT, direction, caster.get_damage(DAMAGE), SPEED, RANGE)
