extends ability_base

# Scatter Debris - plastic hoard ability 2, throws junk off his back that rains down in front of him
# everyone in the area takes damage and gets slowed. everyone sees the junk land, only his own pc deals the damage

const DAMAGE = 10
const SLOW_PERCENT = 0.3 # 30% slower
const SLOW_TIME = 2.0
const RANGE = 360.0 # 1.2x attack range, how far the junk reaches in front of him
const COOLDOWN = 8.0
const LAND_DELAY = 0.5 # the junk is in the air for a bit
const DEBRIS = preload("res://Celebes Abyssal Tides/scenes/player/fx/ScatterDebrisFx.tscn")


# in _ready so these win over the numbers saved in the character scene
func _ready():
	ability_name = "Scatter Debris"
	cooldown_time = COOLDOWN


func _execute(caster):
	if not is_instance_valid(caster):
		return
	SFXManager.play_at("bubble_strike", caster.global_position)
	var direction = caster.get_swing_direction()
	# the area is a circle in front of him, it goes from his feet to RANGE away
	var center = caster.global_position + direction * RANGE * 0.5
	var radius = RANGE * 0.5

	await get_tree().create_timer(LAND_DELAY).timeout
	if not is_instance_valid(caster):
		return
	# 3 piles of junk landing across the area (every pc)
	var side = Vector2(-direction.y, direction.x)
	for offset in [Vector2.ZERO, direction * radius * 0.6 + side * radius * 0.4, -direction * radius * 0.5 - side * radius * 0.4]:
		var fx = spawn_fx(caster, DEBRIS, center + offset)
		fx.scale = Vector2(1.6, 1.6)

	if not caster.is_multiplayer_authority() or caster.is_dead:
		return
	for target in find_enemies(caster, center, radius):
		caster.deal_damage(target, DAMAGE)
		target.apply_slow.rpc(SLOW_PERCENT, SLOW_TIME)
