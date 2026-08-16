extends Area2D
class_name KelpZone

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.has_method("enter_kelp"):
		body.enter_kelp()

func _on_body_exited(body):
	if body.has_method("exit_kelp"):
		body.exit_kelp()
