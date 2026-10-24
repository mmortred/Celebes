extends ability_base
class_name BubbleStrike

## Just a sample ability
 
func _init():
	ability_name = "Bubble Strike"
	cooldown_time = 8.0

func _execute(caster):
	if is_instance_valid(caster) and caster is Node2D:
		SFXManager.play_at("bubble_strike", caster.global_position)
	print(caster.name, " used BUBBLE STRIKE")
