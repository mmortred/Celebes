extends Sprite2D
# fish in the intro, t is the tail clock (8 frames)

const FRAMES = 8

@export var facing_left = true:
	set(value):
		facing_left = value
		if facing_left:
			scale.x = 1
		else:
			scale.x = -1

var t = 0.0:
	set(value):
		t = value
		# one tail flick takes TAU / 8 seconds, cut into 8 frames
		var frame_number = int(t * 8.0 / TAU * FRAMES) % FRAMES
		if frame_number < 0:
			frame_number += FRAMES
		frame = frame_number
