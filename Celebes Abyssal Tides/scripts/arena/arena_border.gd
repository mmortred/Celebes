extends Node2D
## The arena border after the 5-minute mark. It starts around the whole arena,
## slowly shrinks to end_radius (the circle drawn on the map) and stays there.
## Nobody can be outside it: each peer pushes its own player back inside, the
## same way it moves it, so the push looks smooth on every screen.
## Red danger look: pulsing line, red haze outside, embers on the edge, and a red
## screen vignette for my own player as they get close.

@export var start_radius := 2000.0 # covers the whole arena, corners included
@export var end_radius := 1300.0 # the final circle; the outer wells end up outside it
@export var shrink_time := 30.0 # seconds to go from start to end
@export var color := Color(1.8, 0.22, 0.18) # above 1 so it stays red under the arena's blue CanvasModulate
@export var warn_distance := 220.0 # my screen starts going red this far from the edge

const SEGMENTS := 128
const HAZE_BANDS := [ # [distance outside the line, alpha] -> [distance, alpha]; the last one reaches past the arena corners
	[0.0, 0.2, 120.0, 0.35],
	[120.0, 0.35, 600.0, 0.6],
	[600.0, 0.6, 2400.0, 0.75],
]
const EMBERS := 90

var active := false
var radius := 0.0
var elapsed := 0.0
var vignette: TextureRect


func _ready() -> void:
	hide()
	_make_vignette()


# Called on every peer at the same moment (GameManager's leviathan rising rpc).
func start() -> void:
	active = true
	elapsed = 0.0
	radius = start_radius
	show()


func _process(delta: float) -> void:
	if not active:
		return
	_update_vignette()
	if GameManager.match_paused: # holds still during the leviathan cutscene
		return
	elapsed += delta
	var progress := clampf(elapsed / shrink_time, 0.0, 1.0)
	radius = lerpf(start_radius, end_radius, smoothstep(0.0, 1.0, progress))
	queue_redraw()


func _physics_process(_delta: float) -> void:
	if not active:
		return
	for player in get_tree().get_nodes_in_group("players"):
		if not player.is_multiplayer_authority():
			continue # each owner keeps its own player inside
		var offset: Vector2 = player.global_position - global_position
		if offset.length() > radius:
			player.global_position = global_position + offset.limit_length(radius)


func _draw() -> void:
	var pulse := 0.5 + 0.5 * sin(elapsed * 4.0)
	# red gradient outside the line: light at the edge, deeper red the further out
	for band in HAZE_BANDS:
		var from := Color(color, band[1] + 0.06 * pulse)
		var to := Color(color, band[3] + 0.06 * pulse)
		for i in SEGMENTS:
			var d0 := Vector2.from_angle(TAU * i / SEGMENTS)
			var d1 := Vector2.from_angle(TAU * (i + 1) / SEGMENTS)
			var r0: float = radius + band[0]
			var r1: float = radius + band[2]
			draw_polygon(PackedVector2Array([d0 * r0, d1 * r0, d1 * r1, d0 * r1]), PackedColorArray([from, from, to, to]))
	# glow fading inward, so the danger reads before you touch the line
	for i in 6:
		draw_arc(Vector2.ZERO, radius - 6.0 - i * 9.0, 0.0, TAU, SEGMENTS, Color(color, (0.14 - i * 0.022) * (0.7 + 0.3 * pulse)), 9.0)
	# the line: thick dark-red base, bright pulsing core
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, SEGMENTS, Color(0.5, 0.0, 0.0, 0.9), 12.0)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, SEGMENTS, Color(color, 0.75 + 0.25 * pulse), 4.0 + 2.0 * pulse)
	# embers drifting along the edge (same on every screen, no randomness to sync)
	for k in EMBERS:
		var s := float(k) * 12.9898
		var angle := fmod(s * 0.618, TAU) + elapsed * (0.02 + 0.03 * fmod(s, 1.0))
		var life := fmod(elapsed * 0.6 + fmod(s * 0.37, 1.0), 1.0) # 0 -> 1, then starts again
		var drift := lerpf(-10.0, 60.0, life) # rises out from the line
		var p := Vector2.from_angle(angle) * (radius + drift)
		draw_circle(p, lerpf(6.0, 1.5, life), Color(2.5, 0.5 + 0.6 * (1.0 - life), 0.25, 1.0 - life))


# Full-screen red edges for my own player, stronger the closer they are to the border.
func _make_vignette() -> void:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1, 0, 0, 0))
	gradient.set_color(1, Color(0.9, 0.0, 0.05, 0.6))
	gradient.add_point(0.7, Color(1, 0, 0, 0))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	vignette = TextureRect.new()
	vignette.texture = texture
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette.stretch_mode = TextureRect.STRETCH_SCALE
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vignette.modulate.a = 0.0
	# first child of the HUD's layer: over the world, under the HUD
	var hud_layer = get_parent().get_node_or_null("CanvasLayer")
	if hud_layer is CanvasLayer:
		hud_layer.add_child.call_deferred(vignette)
		hud_layer.move_child.call_deferred(vignette, 0)
	else:
		var layer := CanvasLayer.new()
		add_child(layer)
		layer.add_child(vignette)


func _update_vignette() -> void:
	var closeness := 0.0
	for player in get_tree().get_nodes_in_group("players"):
		if player.is_multiplayer_authority() and not player.is_dead:
			var gap: float = radius - (player.global_position - global_position).length()
			closeness = clampf(1.0 - gap / warn_distance, 0.0, 1.0)
	vignette.modulate.a = closeness * (0.75 + 0.25 * sin(elapsed * 8.0))
