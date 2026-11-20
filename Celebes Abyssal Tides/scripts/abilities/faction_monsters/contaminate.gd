extends ability_base

# Contaminate - toxic sludge ability 2, throws a big glob of poison goo where the mouse is
# it splats into one big puddle that stays for a few seconds
# enemies standing in it take damage and their hits do 30% less damage. only his own pc deals the damage

const RANGE = 150.0 # how far he can throw it (closer if the mouse is closer)
const RADIUS = 72.0 # half the width of the puddle, the puddle is half as tall as it is wide
const FALL_TIME = 0.35 # how long the glob falls
const FALL_HEIGHT = 80.0
const DURATION = 3.0 # how long the goo stays
const DAMAGE_PER_SECOND = 6
const TICK_TIME = 0.5
const WEAKEN_PERCENT = 0.3 # their damage goes down 30%
const WEAKEN_TIME = 2.0 # keeps going for a bit after they leave the goo
const COOLDOWN = 9.0
const DROP = preload("res://Celebes Abyssal Tides/scenes/player/fx/Monsters/ToxicSludge/ContaminateDrop.tscn")
const PUDDLE = preload("res://Celebes Abyssal Tides/scenes/player/fx/Monsters/ToxicSludge/ContaminateBigPool.tscn")


# in _ready so these win over the numbers saved in the character scene
func _ready():
	ability_name = "Contaminate"
	cooldown_time = COOLDOWN
	aim_with_mouse = true


func get_stats():
	return "Big poison puddle where the mouse is\nDamage: %d per second\nWeakens their hits by %d%%\nTime: %ss\nRange: %d" % [DAMAGE_PER_SECOND, WEAKEN_PERCENT * 100, DURATION, RANGE]


func _execute(caster):
	if not is_instance_valid(caster):
		return
	SFXManager.play_at("bubble_strike", caster.global_position)
	# on the floor where the mouse is, not further than RANGE
	var spot = caster.global_position + aim_direction * min(aim_distance, RANGE) # under whatever the mouse points at

	# every pc shows the glob falling and the puddle
	var drop = spawn_fx(caster, DROP, spot + Vector2(0, -FALL_HEIGHT), FALL_TIME)
	drop.scale = drop.scale * 2.0 # one big glob
	var fall = drop.create_tween()
	fall.tween_property(drop, "global_position", spot, FALL_TIME).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	await get_tree().create_timer(FALL_TIME).timeout
	if not is_instance_valid(caster):
		return
	_make_puddle(caster, spot)

	if not caster.is_multiplayer_authority():
		return
	var ticks = int(round(DURATION / TICK_TIME))
	var damage = int(round(DAMAGE_PER_SECOND * TICK_TIME))
	for i in ticks:
		if not is_instance_valid(caster):
			return
		for target in _enemies_in_puddle(caster, spot):
			caster.deal_damage(target, damage)
			target.apply_weaken.rpc(WEAKEN_PERCENT, WEAKEN_TIME)
		await get_tree().create_timer(TICK_TIME).timeout


# splats flat and wide then settles, fades out at the end
func _make_puddle(caster, spot):
	var puddle = spawn_fx(caster, PUDDLE, spot, DURATION)
	var base_scale = puddle.scale
	puddle.scale = base_scale * Vector2(1.3, 0.4)
	var splat = puddle.create_tween()
	splat.tween_property(puddle, "scale", base_scale, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	splat.tween_interval(DURATION - 0.7)
	splat.tween_property(puddle, "modulate:a", 0.0, 0.5)


# feet inside the oval of the puddle
func _enemies_in_puddle(caster, spot):
	var found = []
	for player in caster.get_tree().get_nodes_in_group("players"):
		if player == caster or player.team == caster.team or player.is_dead:
			continue
		var offset = player.global_position - spot
		var x = offset.x / RADIUS
		var y = offset.y / (RADIUS * 0.5)
		if x * x + y * y <= 1.0:
			found.append(player)
	return found
