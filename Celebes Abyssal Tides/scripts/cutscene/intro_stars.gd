extends Sprite2D
# twinkling stars, t is the twinkle clock (16 frames)

const FRAMES = 16

var t = 0.0:
	set(value):
		t = value
		# the twinkle repeats every PI seconds
		var frame_number = int(t / PI * FRAMES) % FRAMES
		if frame_number < 0:
			frame_number += FRAMES
		frame = frame_number
