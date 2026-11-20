extends Control

# one ability icon on the hud (E or R), the dark cover goes around like a clock while the cooldown runs

@onready var icon = $Icon
@onready var cover = $Cooldown
@onready var time_label = $TimeLabel
@onready var key_label = $KeyLabel
@onready var tooltip = $Tooltip
@onready var tooltip_label = $Tooltip/Label

var ability = null # the ability node on my player


func _ready():
	mouse_entered.connect(_show_tooltip)
	mouse_exited.connect(_hide_tooltip)


# hover the icon = the stats of the ability (from the numbers at the top of its script)
func _show_tooltip():
	if ability == null or not is_instance_valid(ability):
		return
	tooltip_label.text = ability.get_info()
	tooltip.visible = true
	tooltip.reset_size()
	tooltip.position = Vector2(0, -tooltip.size.y - 4) # just over the icon


func _hide_tooltip():
	tooltip.visible = false


func set_ability(new_ability, key_text):
	ability = new_ability
	icon.texture = ability.get_icon()
	key_label.text = key_text
	visible = true


func _process(_delta):
	if ability == null or not is_instance_valid(ability):
		return
	if ability.is_on_cooldown and ability.cooldown_time > 0:
		cover.value = ability.cooldown_timer / ability.cooldown_time * 100.0
		time_label.text = str(int(ceil(ability.cooldown_timer)))
		time_label.visible = true
		icon.modulate = Color(0.6, 0.6, 0.6)
	else:
		cover.value = 0.0
		time_label.visible = false
		icon.modulate = Color.WHITE
