extends ability_base

# Tide Shift - bajau ability 1, she and the allies close to her get 40% faster for 2 seconds
# this runs on every pc. each pc only moves its own player so the speed only matters there

const RANGE = 150.0
const SPEED_BONUS = 0.4 # 40% faster
const RING_ART_RADIUS = 48.0 # how far the ring png reaches, so the ring is as big as RANGE
const BUFF_TIME = 2.0
const COOLDOWN = 8.0
const RING = preload("res://Celebes Abyssal Tides/scenes/player/fx/SeaNomad/Bajau/TideShiftRing.tscn")


# in _ready so these win over the numbers saved in the character scene
func _ready():
	ability_name = "Tide Shift"
	cooldown_time = COOLDOWN


func get_stats():
	return "She and the allies close to her move faster
Speed: +%d%%
Time: %ss
Range: %d" % [SPEED_BONUS * 100, BUFF_TIME, RANGE]


func _execute(caster):
	if not is_instance_valid(caster):
		return
	SFXManager.play_at("bubble_strike", caster.global_position)
	var ring = spawn_fx(caster, RING, center_of(caster)) # rings spreading out (every pc)
	fit_fx(ring, RANGE, RING_ART_RADIUS)
	for player in caster.get_tree().get_nodes_in_group("players"):
		if player.team != caster.team or player.is_dead:
			continue
		if player.global_position.distance_to(caster.global_position) <= RANGE:
			player.tide_speed_bonus = SPEED_BONUS
			player.tide_timer = BUFF_TIME
