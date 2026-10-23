extends Node
## Persistent menu/lobby audio; music volume is stored locally.
const SAVE_PATH := "user://audio_settings.cfg"
const MUSIC := preload("res://Celebes Abyssal Tides/assets/audio/kulintang_lobby.mp3")
var player: AudioStreamPlayer
var volume: float = 0.65

func _ready() -> void:
    var cfg := ConfigFile.new()
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

func set_music_volume(value: float) -> void:
    volume = clampf(value, 0.0, 1.0)
    _apply_volume()
    var cfg := ConfigFile.new()
    cfg.set_value("audio", "music_volume", volume)
    cfg.save(SAVE_PATH)

func _apply_volume() -> void:
    if player:
        player.volume_db = linear_to_db(maxf(volume, 0.0001))

func _repeat() -> void:
    if _is_menu_scene():
        player.play()

func _scene_added(node: Node) -> void:
    if node == get_tree().current_scene:
        call_deferred("_sync_scene")

func _is_menu_scene() -> bool:
    var scene := get_tree().current_scene
    if scene == null:
        return false
    var path := scene.scene_file_path
    return path.ends_with("MainMenu.tscn") or path.ends_with("PvPLobby.tscn") or path.ends_with("CharacterSelect.tscn")

func _sync_scene() -> void:
    if _is_menu_scene():
        if not player.playing:
            player.play()
    elif player.playing:
        player.stop()

func _process(_delta: float) -> void:
    # Detect scene transitions reliably even when current_scene is assigned after node_added.
    var should_play := _is_menu_scene()
    if should_play and not player.playing:
        player.play()
    elif not should_play and player.playing:
        player.stop()
