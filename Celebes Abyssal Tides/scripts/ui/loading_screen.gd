extends Control

const BG = preload("res://Celebes Abyssal Tides/assets/placeholder_assets/LobbyUI.jpg")
const ARENA_PATH = "res://Celebes Abyssal Tides/scenes/arena/Arena.tscn"
const FACTS = [
	"The Coral Triangle contains some of the world's richest marine biodiversity.",
	"Plastic pollution can harm marine wildlife through ingestion and entanglement.",
	"Healthy coral reefs provide shelter and food for many marine species."
]
var progress: ProgressBar
var status: Label

func _ready() -> void:
	var background := TextureRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.texture = BG
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(background)
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.015, 0.05, 0.12, 0.82)
	add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := VBoxContainer.new()
	panel.custom_minimum_size = Vector2(670, 260)
	panel.add_theme_constant_override("separation", 24)
	center.add_child(panel)
	var heading := Label.new()
	heading.text = "ENTERING THE ABYSS"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 44)
	panel.add_child(heading)
	var fact := Label.new()
	fact.text = FACTS.pick_random()
	fact.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fact.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	fact.add_theme_font_size_override("font_size", 20)
	panel.add_child(fact)
	progress = ProgressBar.new()
	progress.custom_minimum_size.y = 26
	progress.show_percentage = false
	panel.add_child(progress)
	status = Label.new()
	status.text = "Loading arena..."
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(status)
	_load_arena()

func _load_arena() -> void:
	var err := ResourceLoader.load_threaded_request(ARENA_PATH)
	if err != OK:
		status.text = "Unable to load Arena (error %d)" % err
		return
	while true:
		var values: Array = []
		var result := ResourceLoader.load_threaded_get_status(ARENA_PATH, values)
		if not values.is_empty():
			progress.value = float(values[0]) * 100.0
		if result == ResourceLoader.THREAD_LOAD_LOADED:
			break
		if result == ResourceLoader.THREAD_LOAD_FAILED or result == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			status.text = "Arena resource failed to load."
			return
		await get_tree().process_frame
	# Ensure a visible loading screen, even on fast PCs.
	await get_tree().create_timer(0.8).timeout
	status.text = "Waiting for other players..."
	progress.value = 100
	if has_node("/root/CharacterSelectManager"):
		CharacterSelectManager.report_loading_ready()
	else:
		get_tree().change_scene_to_file(ARENA_PATH)
