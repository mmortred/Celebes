extends Node2D

# a shot that flies straight (bajau water bolt, plastic hoard pellet and plastic shot)
# every pc has its own copy so everyone sees it, but only the shooters own copy deals the damage

@export var hit_radius = 14.0 # how close it has to get to someones body

var shooter = null # the player who shot it
var direction = Vector2.RIGHT
var damage = 10
var speed = 420.0
var max_range = 300.0
var travelled = 0.0
var slow_percent = 0.0 # more than 0 = also slows who it hits
var slow_time = 0.0


func _ready():
	rotation = direction.angle() # the art faces right
	$AnimatedSprite2D.play("default")


func _process(delta):
	var step = direction * speed * delta
	global_position += step
	travelled += step.length()
	if travelled >= max_range:
		queue_free()
		return

	if not is_instance_valid(shooter):
		queue_free()
		return

	for player in get_tree().get_nodes_in_group("players"):
		if player.team == shooter.team or player.is_dead:
			continue
		var body = player.global_position + player.body_center
		if body.distance_to(global_position) > hit_radius:
			continue
		# only the shooters own pc sends the hit, the other copies just disappear
		if shooter.is_multiplayer_authority():
			player.receive_hit.rpc(damage, str(shooter.name))
			if slow_percent > 0:
				player.apply_slow.rpc(slow_percent, slow_time)
		queue_free()
		return
