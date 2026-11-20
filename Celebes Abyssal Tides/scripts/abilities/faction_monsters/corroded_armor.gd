extends ability_base

# Corroded Armor - rusty leviathan ability 2, for 4 seconds he takes half damage and sends some of it back
# player.gd receive_hit does the less damage and the sending back, this starts the timer and the glow on every pc

const DAMAGE_REDUCTION = 0.5 # takes 50% less damage
const BUFF_TIME = 4.0
const COOLDOWN = 12.0
const REFLECT_PERCENT = 0.5 # half of the damage he takes goes back to the attacker
const AURA = preload("res://Celebes Abyssal Tides/scenes/player/fx/Monsters/RustyLeviathan/CorrodedAura.tscn")


# in _ready so these win over the numbers saved in the character scene
func _ready():
	ability_name = "Corroded Armor"
	cooldown_time = COOLDOWN


func get_stats():
	return "Takes less damage and sends some of it back
Less damage: %d%%
Sent back: %d%%
Time: %ss" % [DAMAGE_REDUCTION * 100, REFLECT_PERCENT * 100, BUFF_TIME]


func _execute(caster):
	if not is_instance_valid(caster):
		return
	SFXManager.play_at("spear_thrust", caster.global_position)
	caster.armor_percent = DAMAGE_REDUCTION
	caster.reflect_percent = REFLECT_PERCENT
	caster.armor_timer = BUFF_TIME

	var old = caster.get_node_or_null("CorrodedAura")
	if old:
		old.name = "OldAura" # so the new one can use the name
		old.queue_free()
	var aura = AURA.instantiate()
	aura.name = "CorrodedAura"
	aura.life = BUFF_TIME
	caster.add_child(aura)
	aura.position = caster.sprite_walk.position # same spot and size as his body
	aura.scale = caster.sprite_walk.scale
