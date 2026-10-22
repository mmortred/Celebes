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
	var outline := color.darkened(0.55)
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	var mid := PackedVector2Array()
	var tip := Vector2.ZERO
	for i in segments + 1:
		var k := float(i) / segments
		var x := sin(k * 5.0 + height) * curl * k
		var w := width * (1.0 - k * 0.5) * 0.5
		left.append(Vector2(x - w, -height * k))
		right.append(Vector2(x + w, -height * k))
		mid.append(Vector2(x, -height * k))
		tip = Vector2(x, -height - width * 0.4)

	# leaf blades off alternating sides, with a little air bladder at each base
	for i in range(2, segments - 1, 3):
		var side := -1.0 if (i / 3) % 2 == 0 else 1.0
		var base := mid[i]
		var reach := width * 0.9
		var leaf := PackedVector2Array([
			base + Vector2(0, 2), base + Vector2(side * reach, -reach * 0.6),
			base + Vector2(side * reach * 1.2, -reach * 1.6), base + Vector2(side * reach * 0.3, -reach * 0.8),
		])
		draw_colored_polygon(leaf, color.darkened(0.12))
		draw_polyline(leaf + PackedVector2Array([leaf[0]]), outline, 1.0)
		draw_circle(base + Vector2(side * width * 0.5, -1), 1.5, color.lightened(0.25))

	var rev := right.duplicate()
	rev.reverse()
	var strand := left + PackedVector2Array([tip]) + rev
	draw_colored_polygon(strand, color)
	# shade the right edge, light midrib, then outline
	for i in segments:
		draw_line(right[i] - Vector2(1, 0), right[i + 1] - Vector2(1, 0), color.darkened(0.25), 1.0)
	draw_polyline(mid, color.lightened(0.2), 1.0)
	draw_polyline(strand + PackedVector2Array([strand[0]]), outline, 1.0)
