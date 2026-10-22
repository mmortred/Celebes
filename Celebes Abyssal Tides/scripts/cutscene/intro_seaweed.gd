@tool
extends Node2D
## placeholder kelp drawn as a wavy ribbon. base sits at this node's origin.
## give it the sway shader material to make it move.

@export var height := 90.0:
	set(v): height = v; queue_redraw()
@export var width := 10.0:
	set(v): width = v; queue_redraw()
@export var color := Color("3f8f5a"):
	set(v): color = v; queue_redraw()
@export var curl := 6.0: # how wavy the strand is
	set(v): curl = v; queue_redraw()
@export var segments := 16:
	set(v): segments = maxi(v, 2); queue_redraw()


func _draw():
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	var tip := Vector2.ZERO
	for i in segments + 1:
		var k := float(i) / segments
		var x := sin(k * 5.0 + height) * curl * k
		var w := width * (1.0 - k * 0.5) * 0.5
		left.append(Vector2(x - w, -height * k))
		right.append(Vector2(x + w, -height * k))
		tip = Vector2(x, -height - width * 0.4)
	right.reverse()
	# rounded-ish tip between the two sides
	draw_colored_polygon(left + PackedVector2Array([tip]) + right, color)
