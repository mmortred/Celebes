class_name ability_base
extends Node

# base for all abilities, the other abilities extend this

@export var cooldown_time = 1.0
@export var ability_name = "Ability"

var cooldown_timer = 0.0
var is_on_cooldown = false


func _process(delta):
	if is_on_cooldown:
		cooldown_timer -= delta
		if cooldown_timer <= 0:
			is_on_cooldown = false


func can_use():
	return not is_on_cooldown


func use(caster):
	if not can_use():
		return
	is_on_cooldown = true
	cooldown_timer = cooldown_time
	_execute(caster)


@rpc("any_peer", "call_local")
func request_use():
	use(get_parent())


# each ability changes this one
func _execute(caster):
	pass
