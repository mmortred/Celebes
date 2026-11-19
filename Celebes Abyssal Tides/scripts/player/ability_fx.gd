extends AnimatedSprite2D

# one ability effect (heal ring, retaliate glow). deletes itself when its done

@export var life = 0.0 # 0 = gone when the animation ends, more = loops for that many seconds


func _ready():
	play("default")
	if life > 0:
		await get_tree().create_timer(life).timeout
		queue_free()
	else:
		animation_finished.connect(queue_free)
