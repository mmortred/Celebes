extends Control

const BG = preload("res://Celebes Abyssal Tides/assets/placeholder_assets/LobbyUI.jpg")
const ARENA_PATH := "res://Celebes Abyssal Tides/scenes/arena/Arena.tscn"
const CINEMATIC_SECONDS := 4.0
const FACTS := [
	"The Coral Triangle contains some of the world's richest marine biodiversity.",
	"Plastic pollution can harm marine wildlife through ingestion and entanglement.",
	"Healthy coral reefs provide shelter and food for many marine species."
]
const FISH_TEXTURES = [
	preload("res://Celebes Abyssal Tides/assets/cutscene_fish/clownfish.png"),
	preload("res://Celebes Abyssal Tides/assets/cutscene_fish/blue_tang.png"),
	preload("res://Celebes Abyssal Tides/assets/cutscene_fish/butterflyfish.png"),
	preload("res://Celebes Abyssal Tides/assets/cutscene_fish/anchovy.png")
]
var progress: ProgressBar
var status: Label
var fish_data: Array[Dictionary] = []
var bubbles: Array[Dictionary] = []
var elapsed := 0.0

func _ready() -> void:
	var background := TextureRect.new()
	background.texture = BG
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var shade := ColorRect.new()
	shade.color = Color(0.008, 0.025, 0.055, 0.76)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	var effects := Control.new()
	effects.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	effects.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(effects)
	for i in range(7):
		var fish := TextureRect.new()
		fish.texture = FISH_TEXTURES[i % FISH_TEXTURES.size()]
		fish.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		fish.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		fish.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		fish.size = Vector2(40 + (i % 3) * 12, 40 + (i % 3) * 12)
		fish.flip_h = i % 2 == 1
		effects.add_child(fish)
		fish_data.append({"node": fish, "phase": i * 0.8, "speed": 48.0 + (i % 3) * 17.0, "start": -70.0 - i * 95.0, "y": 32.0 + (i * 41) % 270, "reverse": i % 2 == 1})
	for i in range(24):
		var bubble := ColorRect.new()
		bubble.color = Color(0.5, 0.9, 1.0, 0.18)
		var d := 2.0 + float(i % 4)
		bubble.size = Vector2(d, d)
		bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
		effects.add_child(bubble)
		bubbles.append({"node": bubble, "x": float((i * 71 + 17) % 640), "offset": float((i * 37) % 360), "speed": 18.0 + float(i % 5) * 7.0})
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(455, 0)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.012, 0.055, 0.095, 0.94)
	style.border_color = Color(0.26, 0.76, 0.84, 0.85)
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 20
	style.content_margin_bottom = 20
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 13)
	panel.add_child(content)
	var heading := Label.new()
	heading.text = "ENTERING THE ABYSS"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 27)
	heading.add_theme_color_override("font_color", Color("a3edf3"))
	content.add_child(heading)
	var fact := Label.new()
	fact.text = FACTS.pick_random()
	fact.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fact.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	fact.custom_minimum_size.y = 53
	fact.add_theme_font_size_override("font_size", 14)
	content.add_child(fact)
	progress = ProgressBar.new()
	progress.custom_minimum_size.y = 18
	progress.show_percentage = false
	content.add_child(progress)
	status = Label.new()
	status.text = "Loading arena..."
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.add_theme_font_size_override("font_size", 13)
	content.add_child(status)
	_load_arena()

func _process(delta: float) -> void:
	elapsed += delta
	var w := size.x
	var h := size.y
	for item in fish_data:
		var fish: TextureRect = item["node"]
		var travel := fmod(float(item["start"]) + elapsed * float(item["speed"]), w + 160.0)
		var x := w + 60.0 - travel if bool(item["reverse"]) else travel - 60.0
		fish.position = Vector2(x, float(item["y"]) + sin(elapsed * 3.0 + float(item["phase"])) * 8.0)
	for item in bubbles:
		var bubble: ColorRect = item["node"]
		bubble.position = Vector2(fmod(float(item["x"]), maxf(w, 1.0)), h - fmod(float(item["offset"]) + elapsed * float(item["speed"]), h + 20.0))

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
	var remaining := maxf(0.0, CINEMATIC_SECONDS - elapsed)
	if remaining > 0.0:
		await get_tree().create_timer(remaining).timeout
	status.text = "Waiting for other players..."
	progress.value = 100.0
	if has_node("/root/CharacterSelectManager"):
		CharacterSelectManager.report_loading_ready()
	else:
		get_tree().change_scene_to_file(ARENA_PATH)
