extends Control

# one character card in character select. the id, name and team are set on each card in CharacterSelect.tscn
# character_select.gd changes the border, the text on top and if you can click it

signal picked(character_id)
signal hovered(character_id) # -1 when the mouse leaves

@export var character_id = 0
@export var character_name = "BUGIS"
@export var team = "sea" # "sea" or "garbage"

@onready var card = $Card
@onready var portrait = $Portrait
@onready var missing = $Missing
@onready var name_label = $NameLabel
@onready var owner_label = $OwnerLabel
@onready var button = $Button


func _ready():
	name_label.text = character_name
	var icon = CharacterSelectManager.get_icon(character_id)
	portrait.texture = icon
	portrait.visible = icon != null
	missing.visible = icon == null # "?" if theres no art yet
	button.pressed.connect(_on_button_pressed)
	button.mouse_entered.connect(hovered.emit.bind(character_id))
	button.mouse_exited.connect(hovered.emit.bind(-1))


func _on_button_pressed():
	picked.emit(character_id)


func set_border(color, width):
	var style = card.get_theme_stylebox("panel").duplicate() # own copy so the other cards dont change
	style.border_color = color
	style.set_border_width_all(width)
	card.add_theme_stylebox_override("panel", style)


func set_owner_text(text, color):
	owner_label.text = text
	owner_label.modulate = color


# allowed = you could pick this one (right team, has art), clickable = not taken and not locked
func set_clickable(allowed, clickable):
	button.disabled = not clickable
	if clickable:
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	elif allowed:
		button.mouse_default_cursor_shape = Control.CURSOR_ARROW # already yours or locked, just not clickable
	else:
		button.mouse_default_cursor_shape = Control.CURSOR_FORBIDDEN
	if allowed:
		name_label.modulate = Color.WHITE
	else:
		name_label.modulate = Color(0.60, 0.64, 0.68) # gray if you cant pick it
