extends AbilityBase
class_name BubbleStrike

## Just a sample ability
 
func _init():
	ability_name = "Bubble Strike"
	cooldown_time = 8.0

func _execute(caster):
	print(caster.name, " used BUBBLE STRIKE")
