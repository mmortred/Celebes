extends Node

# the kulintang music. starts at the intro and never restarts, it only gets louder or quieter.
# menus = full volume, arena = low volume (like a floater). the volume is saved on this pc

const SAVE_PATH = "user://audio_settings.cfg"
const MUSIC = preload("res://Celebes Abyssal Tides/assets/audio/kulintang_lobby.mp3")

const ARENA_VOLUME = 0.2 # <-- how loud it is in the arena (0.2 = 20% of the music volume slider)
const FADE_TIME = 2.0 # <-- seconds to fade between menu and arena
const INTRO_FADE_TIME = 3.0 # <-- seconds to fade in when the game starts

var player = null
var volume = 0.65 # the music slider
var fade = 0.0 # 0 = silent, 1 = full, moves toward the target
var fade_time = INTRO_FADE_TIME
var target = 1.0


func _ready():
	var cfg = ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		volume = clampf(float(cfg.get_value("audio", "music_volume", 0.65)), 0.0, 1.0)
	var song = MUSIC.duplicate()
	song.loop = true # so the song never stops
	player = AudioStreamPlayer.new()
	player.stream = song
	player.bus = "Master"
	add_child(player)
	player.finished.connect(player.play) # backup if the loop ever ends
	_apply_volume()
	player.play() # starts at the intro


func set_music_volume(value):
	volume = clampf(value, 0.0, 1.0)
	_apply_volume()
	var cfg = ConfigFile.new()
	cfg.set_value("audio", "music_volume", volume)
	cfg.save(SAVE_PATH)


func _apply_volume():
	if player:
		player.volume_db = linear_to_db(maxf(volume * fade, 0.0001))


func _is_arena_scene():
	var scene = get_tree().current_scene
	if scene == null:
		return false
	return scene.scene_file_path.ends_with("MainArena.tscn")


func _process(delta):
	var new_target = 1.0
	if _is_arena_scene():
		new_target = ARENA_VOLUME
	if new_target != target:
		target = new_target
		fade_time = FADE_TIME
	fade = move_toward(fade, target, delta / fade_time)
	_apply_volume()
