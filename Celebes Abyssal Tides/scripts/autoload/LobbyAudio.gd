extends Node

# lobby music, plays only on the menu screens. the volume is saved on this pc

const SAVE_PATH = "user://audio_settings.cfg"
const MUSIC = preload("res://Celebes Abyssal Tides/assets/audio/kulintang_lobby.mp3")

var player = null
var volume = 0.65


func _ready():
	var cfg = ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		volume = clampf(float(cfg.get_value("audio", "music_volume", 0.65)), 0.0, 1.0)
	player = AudioStreamPlayer.new()
	player.stream = MUSIC
	player.bus = "Master"
	add_child(player)
	_apply_volume()
	player.finished.connect(_repeat)
	get_tree().node_added.connect(_scene_added)
	call_deferred("_sync_scene")


func set_music_volume(value):
	volume = clampf(value, 0.0, 1.0)
	_apply_volume()
	var cfg = ConfigFile.new()
	cfg.set_value("audio", "music_volume", volume)
	cfg.save(SAVE_PATH)


func _apply_volume():
	if player:
		player.volume_db = linear_to_db(maxf(volume, 0.0001))


# loop the song
func _repeat():
	if _is_menu_scene():
		player.play()


func _scene_added(node):
	if node == get_tree().current_scene:
		call_deferred("_sync_scene")


func _is_menu_scene():
	var scene = get_tree().current_scene
	if scene == null:
		return false
	var path = scene.scene_file_path
	if path.ends_with("MainMenu.tscn"):
		return true
	if path.ends_with("PvPLobby.tscn"):
		return true
	if path.ends_with("CharacterSelect.tscn"):
		return true
	return false


func _sync_scene():
	if _is_menu_scene():
		if not player.playing:
			player.play()
	elif player.playing:
		player.stop()


func _process(_delta):
	# check every frame too because current_scene is sometimes set after node_added
	_sync_scene()
