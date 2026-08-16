extends StaticBody2D

@export var max_hp: float = 30.0
var current_hp: float = 30.0

func _ready() -> void:
	current_hp = max_hp

func take_damage(amount: float) -> void:
	current_hp -= amount
	print("[CoralBarrier] Took ", amount, " damage. Remaining HP: ", current_hp)
	
	if current_hp <= 0:
		print("[CoralBarrier] Destroyed!")
		queue_free()
