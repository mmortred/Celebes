extends AbilityBase
class_name SpearThrust

## Just a sample ability
 
func _init():
	ability_name = "Spear Thrust"
	cooldown_time = 1.5

func _execute(caster):
	print(caster.name, " used SPEAR THRUST")
