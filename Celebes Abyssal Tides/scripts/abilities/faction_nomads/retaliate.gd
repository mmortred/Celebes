extends ability_base

# Retaliate - minahasan ability 2, for 3 seconds half the damage he takes goes back to the attacker
# player.gd receive_hit does the sending back, this just starts the timer and the glow on every pc

const BUFF_TIME = 3.0
const AURA = preload("res://Celebes Abyssal Tides/scenes/player/fx/SeaNomad/Minahasan/RetaliateAura.tscn")
const COOLDOWN = 10.0


# in _ready so these win over the numbers saved in the character scene
func _ready():
	ability_name = "Retaliate"
	cooldown_time = COOLDOWN


func get_stats():
	return "Sends back half of the damage he takes
Time: %ss" % BUFF_TIME


func _execute(caster):
	if not is_instance_valid(caster):
		return
	SFXManager.play_at("spear_thrust", caster.global_position)
	caster.retaliate_timer = BUFF_TIME

	var old = caster.get_node_or_null("RetaliateAura")
	if old:
		old.name = "OldAura" # so the new one can use the name
		old.queue_free()
	var aura = AURA.instantiate()
	aura.name = "RetaliateAura"
	aura.life = BUFF_TIME
	caster.add_child(aura)
	aura.position = caster.sprite_walk.position # same spot and size as his body
	aura.scale = caster.sprite_walk.scale
