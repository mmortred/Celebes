extends Node
## Client-local sound playback. Call from replicated events only once per peer.
const ROOT := "res://Celebes Abyssal Tides/assets/audio/sfx/"
const SOUNDS := {
    "attack_sea": preload("res://Celebes Abyssal Tides/assets/audio/sfx/attack_sea.wav"),
    "attack_garbage": preload("res://Celebes Abyssal Tides/assets/audio/sfx/attack_garbage.wav"),
    "hurt_sea": preload("res://Celebes Abyssal Tides/assets/audio/sfx/hurt_sea.wav"),
    "hurt_garbage": preload("res://Celebes Abyssal Tides/assets/audio/sfx/hurt_garbage.wav"),
    "pearl_pickup": preload("res://Celebes Abyssal Tides/assets/audio/sfx/pearl_pickup.wav"),
    "score": preload("res://Celebes Abyssal Tides/assets/audio/sfx/score.wav"),
    "respawn": preload("res://Celebes Abyssal Tides/assets/audio/sfx/respawn.wav"),
    "bubble_strike": preload("res://Celebes Abyssal Tides/assets/audio/sfx/bubble_strike.wav"),
    "spear_thrust": preload("res://Celebes Abyssal Tides/assets/audio/sfx/spear_thrust.wav"),
    "dash": preload("res://Celebes Abyssal Tides/assets/audio/sfx/dash.wav"),
    "step_sea": preload("res://Celebes Abyssal Tides/assets/audio/sfx/step_sea.wav"),
    "step_garbage": preload("res://Celebes Abyssal Tides/assets/audio/sfx/step_garbage.wav"),
    "ui_click": preload("res://Celebes Abyssal Tides/assets/audio/sfx/ui_click.wav")
}
const SAVE_PATH := "user://sfx_settings.cfg"
var volume: float = 0.7

func _ready() -> void:
    var cfg := ConfigFile.new()
    if cfg.load(SAVE_PATH) == OK:
        volume = clampf(float(cfg.get_value("audio", "sfx_volume", 0.7)), 0.0, 1.0)

func set_sfx_volume(value: float) -> void:
    volume = clampf(value, 0.0, 1.0)
    var cfg := ConfigFile.new()
    cfg.set_value("audio", "sfx_volume", volume)
    cfg.save(SAVE_PATH)

func play_ui(sound_name: String) -> void:
    if volume <= 0.0 or not SOUNDS.has(sound_name):
        return
    var player := AudioStreamPlayer.new()
    player.stream = SOUNDS[sound_name]
    player.volume_db = linear_to_db(volume)
    add_child(player)
    player.finished.connect(player.queue_free)
    player.play()

func play_at(sound_name: String, world_position: Vector2) -> void:
    if volume <= 0.0 or not SOUNDS.has(sound_name):
        return
    var scene := get_tree().current_scene
    if scene == null:
        return
    var player := AudioStreamPlayer2D.new()
    player.stream = SOUNDS[sound_name]
    player.volume_db = linear_to_db(volume)
    player.max_distance = 1200.0
    player.global_position = world_position
    scene.add_child(player)
    player.global_position = world_position
    player.finished.connect(player.queue_free)
    player.play()
