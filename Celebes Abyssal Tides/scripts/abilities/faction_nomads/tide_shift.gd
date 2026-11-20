extends ability_base

# Tide Shift - bajau ability 1, she and the allies close to her get 40% faster for 2 seconds
# this runs on every pc. each pc only moves its own player so the speed only matters there

const RANGE = 150.0
const BUFF_TIME = 2.0
const COOLDOWN = 8.0


# in _ready so these win over the numbers saved in the character scene
func _ready():
	ability_name = "Tide Shift"
	cooldown_time = COOLDOWN


func get_stats():
	return "She and the allies close to her move faster
Speed: +40%%
Time: %ss
Range: %d" % [BUFF_TIME, RANGE]


func _execute(caster):
	if not is_instance_valid(caster):
		return
	SFXManager.play_at("bubble_strike", caster.global_position)
	for player in caster.get_tree().get_nodes_in_group("players"):
		if player.team != caster.team or player.is_dead:
			continue
		if player.global_position.distance_to(caster.global_position) <= RANGE:
			player.tide_timer = BUFF_TIME
