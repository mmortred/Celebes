extends ability_base

# Toxic Mist - toxic sludge ability 1, burps out a poison cloud around him that stays for 2 seconds
# enemies inside take damage every tick. everyone sees the cloud, only his own pc deals the damage

const DAMAGE_PER_SECOND = 8
const RADIUS = 90.0 # 1.5x melee range
const DURATION = 2.0
const TICK_TIME = 0.5 # damage every half second (4 + 4 = 8 per second)
const COOLDOWN = 9.0
const CLOUD = preload("res://Celebes Abyssal Tides/scenes/player/fx/ToxicMistCloud.tscn")


# in _ready so these win over the numbers saved in the character scene
func _ready():
	ability_name = "Toxic Mist"
	cooldown_time = COOLDOWN


func _execute(caster):
	if not is_instance_valid(caster):
		return
	SFXManager.play_at("bubble_strike", caster.global_position)
	# the cloud stays where he burped it, it doesnt follow him
	var center = caster.global_position
	var cloud = spawn_fx(caster, CLOUD, center)
	cloud.life = DURATION

	if not caster.is_multiplayer_authority():
		return
	var ticks = int(round(DURATION / TICK_TIME))
	var damage = int(round(DAMAGE_PER_SECOND * TICK_TIME))
	for i in ticks:
		await get_tree().create_timer(TICK_TIME).timeout
		if not is_instance_valid(caster):
			return
		for target in find_enemies(caster, center + caster.body_center, RADIUS):
			caster.deal_damage(target, damage)
