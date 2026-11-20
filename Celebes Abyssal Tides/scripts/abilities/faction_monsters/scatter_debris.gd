extends ability_base

# Scatter Debris - plastic hoard ability 2, junk rains down in a straight line toward the mouse (like a rocket barrage)
# the piles land one after another from him outwards, each pile hurts and slows whoever is under it
# everyone sees the junk land, only his own pc deals the damage

const DAMAGE = 10
const SLOW_PERCENT = 0.3 # 30% slower
const SLOW_TIME = 2.0
const RANGE = 360.0 # 1.2x attack range, how long the line is
const WIDTH = 70.0 # how wide the line is
const PILES = 6 # junk piles along the line
const LAND_DELAY = 0.5 # the first pile is in the air for a bit
const PILE_GAP = 0.08 # time between each pile landing
const PILE_ART_WIDTH = 78.0 # how wide one pile png is, so the piles are as wide as WIDTH
const COOLDOWN = 8.0
const DEBRIS = preload("res://Celebes Abyssal Tides/scenes/player/fx/Monsters/PlasticHoard/ScatterDebrisFx.tscn")


# in _ready so these win over the numbers saved in the character scene
func _ready():
	ability_name = "Scatter Debris"
	cooldown_time = COOLDOWN
	aim_with_mouse = true


func get_stats():
	return "Junk rains down in a line toward the mouse, hurts and slows\nDamage: %d\nSlow: %d%% for %ss\nLength: %d" % [DAMAGE, SLOW_PERCENT * 100, SLOW_TIME, RANGE]


func _execute(caster):
	if not is_instance_valid(caster):
		return
	SFXManager.play_at("bubble_strike", caster.global_position)
	var direction = aim_direction
	var start = caster.global_position # the line is on the floor, from his feet
	var step = RANGE / PILES
	var already_hit = [] # each enemy only gets hit once

	await get_tree().create_timer(LAND_DELAY).timeout
	for i in PILES:
		if not is_instance_valid(caster):
			return
		var from = start + direction * (step * i)
		var to = from + direction * step
		var fx = spawn_fx(caster, DEBRIS, (from + to) * 0.5) # every pc
		fit_fx(fx, WIDTH, PILE_ART_WIDTH)
		if caster.is_multiplayer_authority() and not caster.is_dead:
			for target in _enemies_near(caster, from, to):
				if already_hit.has(target):
					continue
				already_hit.append(target)
				caster.deal_damage(target, DAMAGE)
				target.apply_slow.rpc(SLOW_PERCENT, SLOW_TIME)
		await get_tree().create_timer(PILE_GAP).timeout


# enemies whose feet are close to this piece of the line
func _enemies_near(caster, from, to):
	var found = []
	for player in caster.get_tree().get_nodes_in_group("players"):
		if player == caster or player.team == caster.team or player.is_dead:
			continue
		var closest = Geometry2D.get_closest_point_to_segment(player.global_position, from, to)
		if closest.distance_to(player.global_position) <= WIDTH * 0.5:
			found.append(player)
	return found
