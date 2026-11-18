extends Node

# my username, saved on this pc. the lobby host shares it with everyone

signal username_changed(new_name)

const SAVE_PATH = "user://player_profile.cfg"
const MAX_NAME_LENGTH = 18

var username = "Player"


func _ready():
	var cfg = ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		username = sanitize(str(cfg.get_value("profile", "username", "Player")))


# cleans the name: no new lines or tabs, max 18 letters, not empty
func sanitize(value):
	var cleaned = value.strip_edges().replace("\n", " ").replace("\r", " ").replace("\t", " ")
	if cleaned.length() > MAX_NAME_LENGTH:
		cleaned = cleaned.substr(0, MAX_NAME_LENGTH)
	if cleaned.is_empty():
		cleaned = "Player"
	return cleaned


func set_username(value):
	username = sanitize(value)
	var cfg = ConfigFile.new()
	cfg.set_value("profile", "username", username)
	var result = cfg.save(SAVE_PATH)
	if result != OK:
		push_warning("Could not save username: " + error_string(result))
	username_changed.emit(username)
