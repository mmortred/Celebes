extends ability_base

# Heal - bajau ability 2, heals her and the allies close to her for 16 HP over 2 seconds
# everyone sees the green ring and the glow around her, but only her own pc picks who gets healed (so it doesnt heal twice)

const RANGE = 150.0
const TICKS = 4
const HEAL_PER_TICK = 4 # 4 ticks x 4 HP = 16 HP
const TICK_TIME = 0.5 # 4 ticks x 0.5 = 2 seconds
const COOLDOWN = 13.0
const PULSE_ART_RADIUS = 48.0 # how far the ring png reaches, so the ring is as big as RANGE
const PULSE = preload("res://Celebes Abyssal Tides/scenes/player/fx/SeaNomad/Bajau/HealPulse.tscn")
const AURA = preload("res://Celebes Abyssal Tides/scenes/player/fx/SeaNomad/Bajau/HealAura.tscn")
const GROUND = preload("res://Celebes Abyssal Tides/scenes/player/fx/SeaNomad/Bajau/HealGround.tscn")


# in _ready so these win over the numbers saved in the character scene
func _ready():
	ability_name = "Heal"
	cooldown_time = COOLDOWN


func get_stats():
	return "Heals her and the allies close to her
Heal: %d HP over %ss
Range: %d" % [TICKS * HEAL_PER_TICK, TICKS * TICK_TIME, RANGE]


func _execute(caster):
	if not is_instance_valid(caster):
		return
	SFXManager.play_at("bubble_strike", caster.global_position)
	var pulse = spawn_fx(caster, PULSE, caster.global_position)
	fit_fx(pulse, RANGE, PULSE_ART_RADIUS)
	# green glow on the floor under her and plus signs around her for the whole heal
	for scene in [GROUND, AURA]:
		var fx = scene.instantiate()
		var fx_name = "HealAura"
		if scene == GROUND:
			fx_name = "HealGround"
		var old = caster.get_node_or_null(fx_name)
		if old:
			old.name = "Old" + fx_name
			old.queue_free()
		fx.name = fx_name
		fx.life = TICKS * TICK_TIME
		caster.add_child(fx)
		if scene == GROUND:
			caster.move_child(fx, 0) # first child so she is drawn on top of it
		fx.position = caster.sprite_walk.position
		fx.scale = caster.sprite_walk.scale

	if not caster.is_multiplayer_authority():
		return
	for i in TICKS:
		await get_tree().create_timer(TICK_TIME).timeout
		if not is_instance_valid(caster) or caster.is_dead:
			return # stops if she dies
		for player in caster.get_tree().get_nodes_in_group("players"):
			if player.team != caster.team or player.is_dead:
				continue
			if player.global_position.distance_to(caster.global_position) <= RANGE:
				player.receive_heal.rpc(HEAL_PER_TICK)
