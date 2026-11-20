extends Node2D

# a shot that flies straight (bajau water bolt, plastic hoard pellet and plastic shot)
# every pc has its own copy so everyone sees it, but only the shooters own copy deals the damage

@export var hit_radius = 14.0 # size of the shot, the hurtbox gets half of this bigger

var shooter = null # the player who shot it
var direction = Vector2.RIGHT
var damage = 10
var speed = 420.0
var max_range = 300.0
var travelled = 0.0
var slow_percent = 0.0 # more than 0 = also slows who it hits
var slow_time = 0.0
var skip_bodies = [] # the players, the wall check only looks for walls
var ground_offset = Vector2.ZERO # the shot flies at body height, the walls are checked at the feet
var started = false


func _ready():
	rotation = direction.angle() # the art faces right
	$AnimatedSprite2D.play("default")
	for player in get_tree().get_nodes_in_group("players"):
		skip_bodies.append(player.get_rid())
	if is_instance_valid(shooter):
		ground_offset = -shooter.body_center


func _process(delta):
	# first frame: shooting right next to a wall, the shot starts on the other side of it
	if not started:
		started = true
		if is_instance_valid(shooter) and _hits_wall(shooter.global_position, global_position + ground_offset):
			queue_free()
			return

	if not is_instance_valid(shooter):
		queue_free()
		return

	var step = direction * speed * delta
	var from = global_position
	var to = global_position + step

	# did it go through someones hurtbox this frame (the whole path, so fast shots cant skip over a body)
	for player in get_tree().get_nodes_in_group("players"):
		if player.team == shooter.team or player.is_dead:
			continue
		if not _hits_body(player, from, to):
			continue
		# only the shooters own pc sends the hit, the other copies just disappear
		if shooter.is_multiplayer_authority():
			player.receive_hit.rpc(damage, str(shooter.name))
			if slow_percent > 0:
				player.apply_slow.rpc(slow_percent, slow_time)
		queue_free()
		return

	# walls and barriers stop the shot (every pc checks so it disappears everywhere)
	if _hits_wall(from + ground_offset, to + ground_offset):
		queue_free()
		return
	global_position = to
	travelled += step.length()
	if travelled >= max_range:
		queue_free()


# the same box the melee attacks hit (HurtBox), a bit bigger because the shot has a size too
func _hits_body(player, from, to):
	var box = player.get_node_or_null("HurtBox/CollisionShape2D")
	if box == null or not box.shape is RectangleShape2D:
		var body = player.global_position + player.body_center
		return Geometry2D.get_closest_point_to_segment(body, from, to).distance_to(body) <= hit_radius
	# move the path into the box's own space so the box is just a rectangle around 0,0
	var inverse = box.global_transform.affine_inverse()
	var a = inverse * from
	var b = inverse * to
	var size = box.shape.size
	var rect = Rect2(-size / 2.0, size).grow(hit_radius * 0.5)
	if rect.has_point(a) or rect.has_point(b):
		return true
	var corners = [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]
	for i in 4:
		if Geometry2D.segment_intersects_segment(a, b, corners[i], corners[(i + 1) % 4]) != null:
			return true
	return false


# is there a wall (layer 1, not a player) between these two points
func _hits_wall(from, to):
	var query = PhysicsRayQueryParameters2D.create(from, to, 1, skip_bodies)
	return not get_world_2d().direct_space_state.intersect_ray(query).is_empty()
