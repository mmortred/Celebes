extends Node2D
## A team's scoring well. Walk in carrying the pearl to score (server checks).
## Each well belongs to a phase: "early" wells count for the first 5 minutes,
## "late" wells after the 5-minute mark (the arena switches them).
## Art: WellNomad / WellMonster sheets, 64x128 frames in rows of 5.

const FRAME := Vector2i(64, 128)
const SHEETS := {
	0: {"texture": preload("res://Celebes Abyssal Tides/assets/tf_atlantis/WellNomad.png"), "frames": 20, "idle": 12},
	1: {"texture": preload("res://Celebes Abyssal Tides/assets/tf_atlantis/WellMonster.png"), "frames": 22, "idle": 21},
}

@export var team := 0 # 0 = Sea Nomads, 1 = Garbage Monsters
@export var late := false # true = only scores after the 5-minute mark

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var score_area: Area2D = $ScoreArea
@onready var blocker_shape: CollisionShape2D = $Blocker/CollisionShape2D # solid while locked

var active := true


func _ready() -> void:
	add_to_group("wells")
	sprite.show_behind_parent = true # so the padlock (_draw) shows on top of the well
	sprite.sprite_frames = _build_frames()
	sprite.play("idle")
	sprite.animation_finished.connect(func(): sprite.play("idle"))
	score_area.body_entered.connect(_on_body_entered)
	set_active(not late)


func _build_frames() -> SpriteFrames:
	var sheet: Dictionary = SHEETS[team]
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	frames.add_animation("idle")
	frames.add_frame("idle", _cell(sheet.texture, sheet.idle))
	frames.add_animation("capture")
	frames.set_animation_loop("capture", false)
	frames.set_animation_speed("capture", 12.0)
	for i in sheet.frames:
		frames.add_frame("capture", _cell(sheet.texture, i))
	return frames


func _cell(texture: Texture2D, index: int) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = Rect2(Vector2((index % 5) * FRAME.x, (index / 5) * FRAME.y), Vector2(FRAME))
	return atlas


# Locked wells (inner ones before 5:00, outer ones after) are solid so nobody can
# step in, dimmed, show a padlock, and don't score.
func set_active(value: bool) -> void:
	active = value
	sprite.modulate = Color.WHITE if value else Color(0.55, 0.55, 0.6, 0.6)
	blocker_shape.set_deferred("disabled", value)
	queue_redraw()


func _draw() -> void:
	if active:
		return
	# padlock floating over the well
	var top := Vector2(0, -92)
	draw_arc(top + Vector2(0, -4), 6.0, PI, TAU, 10, Color(0.85, 0.85, 0.9), 2.5)
	draw_rect(Rect2(top + Vector2(-8, -4), Vector2(16, 13)), Color(0.85, 0.85, 0.9))
	draw_rect(Rect2(top + Vector2(-1.5, 0), Vector2(3, 5)), Color(0.2, 0.2, 0.28))


func play_capture() -> void:
	sprite.play("capture")


func _on_body_entered(body) -> void:
	if not multiplayer.is_server() or not active:
		return
	if not body.is_in_group("players") or body.is_dead or not body.has_pearl or body.team != team:
		return
	var pearl = get_tree().get_first_node_in_group("pearl")
	if pearl:
		pearl.try_capture(body, self)
