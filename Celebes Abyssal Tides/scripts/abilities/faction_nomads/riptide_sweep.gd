extends ability_base

# Riptide Sweep - bugis ability 2, swings the spear all around him with a wave and hits everyone close
# only his own pc checks who got hit

const DAMAGE = 25
const RADIUS = 120.0 # 2x melee range, all around him
const COOLDOWN = 10.0
const WAVE_ART_RADIUS = 48.0 # how far the wave png reaches, so the wave is as big as RADIUS
const HIT_DELAY = 0.35 # wait for the frame where the wave is out
const WAVE = preload("res://Celebes Abyssal Tides/scenes/player/fx/SeaNomad/Bugis/RiptideWave.tscn")


# in _ready so these win over the numbers saved in the character scene
func _ready():
	ability_name = "Riptide Sweep"
	cooldown_time = COOLDOWN


func get_stats():
	return "Spins the spear and hits everyone around him
Damage: %d
Radius: %d" % [DAMAGE, RADIUS]


func _execute(caster):
	if not is_instance_valid(caster):
		return
	SFXManager.play_at("bubble_strike", caster.global_position)
	await get_tree().create_timer(HIT_DELAY).timeout
	if not is_instance_valid(caster) or caster.is_dead:
		return
	var wave = spawn_fx(caster, WAVE, center_of(caster)) # ring of water (every pc)
	fit_fx(wave, RADIUS, WAVE_ART_RADIUS)

	if not caster.is_multiplayer_authority():
		return

	for target in find_enemies(caster, center_of(caster), RADIUS):
		caster.deal_damage(target, DAMAGE)
