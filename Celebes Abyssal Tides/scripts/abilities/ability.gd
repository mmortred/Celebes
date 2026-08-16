class_name AbilityBase
extends Node

@export var cooldown_time: float = 1.0
@export var ability_name: String = "Ability"

var cooldown_timer: float = 0.0
var is_on_cooldown: bool = false

func _process(delta):
	if is_on_cooldown:
		cooldown_timer -= delta
		if cooldown_timer <= 0:
			is_on_cooldown = false

func can_use() -> bool:
	return not is_on_cooldown

func use(caster: CharacterBody2D):
	if not can_use():
		return
	is_on_cooldown = true
	cooldown_timer = cooldown_time
	_execute(caster)

@rpc("any_peer", "call_local")
func request_use():
	use(get_parent())

# override this in different abilities
func _execute(caster: CharacterBody2D):
	pass
