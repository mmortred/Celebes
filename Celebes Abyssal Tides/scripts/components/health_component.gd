class_name HealthComponent
extends Node

# the prints are for testing, can remove later

signal health_changed(new_health, max_health)
signal knocked_out

@export var max_health = 100.0
var current_health = 100.0


func _ready():
	current_health = max_health # full hp at the start
	print("[HealthComponent] Initialized on ", _owner_name(), " with ", current_health, " HP.")


# name of the player this belongs to
func _owner_name():
	if get_parent():
		return get_parent().name
	return name


func take_damage(amount, source_player = null):
	if current_health <= 0:
		print("[HealthComponent] Hit ignored on ", _owner_name(), " (already knocked out).")
		return

	current_health = max(0.0, current_health - amount) # dont go below 0

	var source_name = "Unknown Source"
	if source_player != null and "name" in source_player:
		source_name = source_player.name
	print("[HealthComponent] ", _owner_name(), " took ", amount, " damage from ", source_name, ". HP: ", current_health, "/", max_health)

	health_changed.emit(current_health, max_health) # update the hud

	if current_health == 0:
		print("[HealthComponent] ", _owner_name(), " is KNOCKED OUT!")
		knocked_out.emit()


func heal(amount):
	current_health = min(max_health, current_health + amount) # dont go above max
	print("[HealthComponent] ", _owner_name(), " healed ", amount, " HP. Current HP: ", current_health, "/", max_health)
	health_changed.emit(current_health, max_health)


# back to full hp (for respawning)
func reset_full():
	current_health = max_health
	print("[HealthComponent] ", _owner_name(), " health reset to full: ", current_health, "/", max_health)
	health_changed.emit(current_health, max_health)
