class_name HealthComponent
extends Node

# the hp of one player. player.gd listens to the two signals

signal health_changed(new_health, max_health)
signal knocked_out

@export var max_health = 100.0
var current_health = 100.0


func _ready():
	current_health = max_health # full hp at the start


func take_damage(amount, _source_player = null):
	if current_health <= 0:
		return # already knocked out

	current_health = max(0.0, current_health - amount) # dont go below 0
	health_changed.emit(current_health, max_health) # update the hud

	if current_health == 0:
		knocked_out.emit()


func heal(amount):
	current_health = min(max_health, current_health + amount) # dont go above max
	health_changed.emit(current_health, max_health)


# back to full hp (for respawning)
func reset_full():
	current_health = max_health
	health_changed.emit(current_health, max_health)
