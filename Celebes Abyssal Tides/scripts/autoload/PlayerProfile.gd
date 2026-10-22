extends Node
## Locally stored display name; synchronized by the lobby host.
signal username_changed(new_name: String)
const SAVE_PATH := "user://player_profile.cfg"
const MAX_NAME_LENGTH := 18
var username: String = "Player"

func _ready() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		username = sanitize(str(cfg.get_value("profile", "username", "Player")))

func sanitize(value: String) -> String:
	var cleaned := value.strip_edges().replace("\n", " ").replace("\r", " ").replace("\t", " ")
	if cleaned.length() > MAX_NAME_LENGTH:
		cleaned = cleaned.substr(0, MAX_NAME_LENGTH)
	if cleaned.is_empty():
		cleaned = "Player"
	return cleaned

func set_username(value: String) -> void:
	username = sanitize(value)
	var cfg := ConfigFile.new()
	cfg.set_value("profile", "username", username)
	var result := cfg.save(SAVE_PATH)
	if result != OK:
		push_warning("Could not save username: " + error_string(result))
	username_changed.emit(username)
