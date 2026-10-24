extends ability_base
class_name SpearThrust

## Just a sample ability
 
func _init():
	ability_name = "Spear Thrust"
	cooldown_time = 1.5

func _execute(caster):
	if is_instance_valid(caster) and caster is Node2D:
		SFXManager.play_at("spear_thrust", caster.global_position)
	print(caster.name, " used SPEAR THRUST")
