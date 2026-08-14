class_name HealthComponent
extends Node
# The print consoles are for testing // can be removed later on
# Signals sent out to notify other scripts
signal health_changed(new_health: float, max_health: float)
signal knocked_out

@export var max_health: float = 100.0
var current_health: float = 100.0

# Runs when the node enters the scene tree
func _ready() -> void:
	current_health = max_health # Start at full health when game starts
	print("[HealthComponent] Initialized on ", get_parent().name if get_parent() else name, " with ", current_health, " HP.")

# Reduces health when taking a hit
func take_damage(amount: float, source_player = null) -> void:
	# Don't take damage if already knocked out
	if current_health <= 0:
		print("[HealthComponent] Hit ignored on ", get_parent().name if get_parent() else name, " (already knocked out).")
		return   
		
	# Reduce health, it never drops below 0.0
	current_health = max(0.0, current_health - amount)
	
	var source_name = source_player.name if source_player != null and "name" in source_player else "Unknown Source"
	print("[HealthComponent] ", get_parent().name if get_parent() else name, " took ", amount, " damage from ", source_name, ". HP: ", current_health, "/", max_health)
	
	# Tell the UI/other scripts that health changed
	health_changed.emit(current_health, max_health)
	
	# Trigger knockout signal if health hits zero
	if current_health == 0:
		print("[HealthComponent] ", get_parent().name if get_parent() else name, " is KNOCKED OUT!")
		knocked_out.emit()

# Increases health when healed 
func heal(amount: float) -> void:
	# Increase health, it never goes above max_health
	current_health = min(max_health, current_health + amount)
	print("[HealthComponent] ", get_parent().name if get_parent() else name, " healed ", amount, " HP. Current HP: ", current_health, "/", max_health)
	
	# Update UI with new health value
	health_changed.emit(current_health, max_health)

# Instantly restores health back to full (useful for respawning)
func reset_full() -> void:
	current_health = max_health
	print("[HealthComponent] ", get_parent().name if get_parent() else name, " health reset to full: ", current_health, "/", max_health)
	health_changed.emit(current_health, max_health)
