extends Node

# plays sound effects on this pc only. call it from something that already runs on every peer

const SOUNDS = {
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
	"ui_click": preload("res://Celebes Abyssal Tides/assets/audio/sfx/ui_click.wav"),
	"hit": preload("res://Celebes Abyssal Tides/assets/audio/sfx2/hit.wav"),
	"player_death": preload("res://Celebes Abyssal Tides/assets/audio/sfx2/player_death.wav"),
	"heavy_attack": preload("res://Celebes Abyssal Tides/assets/audio/sfx2/heavy_attack.wav"),
	"ability_ready": preload("res://Celebes Abyssal Tides/assets/audio/sfx2/ability_ready.wav"),
	"low_health_warning": preload("res://Celebes Abyssal Tides/assets/audio/sfx2/low_health_warning.wav"),
	"pearl_drop": preload("res://Celebes Abyssal Tides/assets/audio/sfx2/pearl_drop.wav"),
	"pearl_spawn": preload("res://Celebes Abyssal Tides/assets/audio/sfx2/pearl_spawn.wav"),
	"serpent_growl": preload("res://Celebes Abyssal Tides/assets/audio/sfx2/five_minute_sea_dragon_growl.wav")
}
const SAVE_PATH = "user://sfx_settings.cfg"

var volume = 0.7


func _ready():
	var cfg = ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		volume = clampf(float(cfg.get_value("audio", "sfx_volume", 0.7)), 0.0, 1.0)


func set_sfx_volume(value):
	volume = clampf(value, 0.0, 1.0)
	var cfg = ConfigFile.new()
	cfg.set_value("audio", "sfx_volume", volume)
	cfg.save(SAVE_PATH)


# menu sounds (no position)
func play_ui(sound_name):
	if volume <= 0.0 or not SOUNDS.has(sound_name):
		return
	var player = AudioStreamPlayer.new()
	player.stream = SOUNDS[sound_name]
	player.volume_db = linear_to_db(volume)
	add_child(player)
	player.finished.connect(player.queue_free) # delete it when its done
	player.play()


# sounds in the game, quieter when far away
func play_at(sound_name, world_position):
	if volume <= 0.0 or not SOUNDS.has(sound_name):
		return
	var scene = get_tree().current_scene
	if scene == null:
		return
	var player = AudioStreamPlayer2D.new()
	player.stream = SOUNDS[sound_name]
	player.volume_db = linear_to_db(volume)
	player.max_distance = 1200.0
	scene.add_child(player)
	player.global_position = world_position
	player.finished.connect(player.queue_free)
	player.play()
