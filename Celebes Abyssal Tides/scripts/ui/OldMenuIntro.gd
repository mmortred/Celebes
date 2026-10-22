extends Control

const MENU_PATH := "res://Celebes Abyssal Tides/scenes/MainMenu.tscn"
const BG = preload("res://Celebes Abyssal Tides/assets/placeholder_assets/LobbyUI.jpg")
const LOGO = preload("res://Celebes Abyssal Tides/assets/ui/celebes_logo.png")
const NSTW_LOGO = preload("res://Celebes Abyssal Tides/assets/ui/nstw_2026_logo.png")
const CLUTTER = preload("res://Celebes Abyssal Tides/assets/ui/ClutterFile.png")
const PIXEL_FONT = preload("res://Celebes Abyssal Tides/assets/fonts/PixelifySans-VariableFont_wght.ttf")
const FISH = [
    preload("res://Celebes Abyssal Tides/assets/cutscene_fish/clownfish.png"),
    preload("res://Celebes Abyssal Tides/assets/cutscene_fish/blue_tang.png"),
    preload("res://Celebes Abyssal Tides/assets/cutscene_fish/butterflyfish.png")
]
const DURATION := 8.0
var elapsed := 0.0
var finished := false
var fish_data: Array[Dictionary] = []
var bubble_data: Array[Dictionary] = []
var overlay: ColorRect
var background_node: TextureRect
var tint_node: ColorRect
var title_node: TextureRect
var nstw_node: TextureRect
var credit_node: Label
var subtitle_node: Label
var skip_node: Label

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    var background := TextureRect.new()
    background.texture = BG
    background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    background.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(background)
    background_node = background

    var tint := ColorRect.new()
    tint.color = Color(0.006, 0.018, 0.055, 0.64)
    tint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(tint)
    tint_node = tint

    # Decorative sprites from the provided sprite sheet, kept away from the title.
    _add_clutter(Rect2(128, 0, 32, 32), Vector2(42, 286), Vector2(25, 25))
    _add_clutter(Rect2(160, 0, 32, 32), Vector2(90, 313), Vector2(23, 23))
    _add_clutter(Rect2(192, 0, 32, 32), Vector2(535, 300), Vector2(27, 27))
    _add_clutter(Rect2(224, 0, 32, 32), Vector2(575, 273), Vector2(28, 28))

    for i in range(3):
        var fish := TextureRect.new()
        fish.texture = FISH[i]
        fish.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
        fish.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        fish.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        fish.size = Vector2(32, 32)
        fish.flip_h = i == 1
        fish.mouse_filter = Control.MOUSE_FILTER_IGNORE
        add_child(fish)
        fish_data.append({"node": fish, "phase": float(i) * 1.7, "speed": 25.0 + float(i) * 8.0, "start": -40.0 - float(i) * 170.0, "y": 100.0 + float(i) * 83.0, "reverse": i == 1})

    for i in range(18):
        var bubble := ColorRect.new()
        bubble.color = Color(0.54, 0.91, 1.0, 0.22)
        var diameter := 2.0 + float(i % 3)
        bubble.size = Vector2(diameter, diameter)
        bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
        add_child(bubble)
        bubble_data.append({"node": bubble, "x": float((i * 67 + 35) % 640), "offset": float((i * 43) % 360), "speed": 14.0 + float(i % 5) * 6.0})

    # NSTW 2026 is a standalone pixel-art logo, not a hanging banner.
    var nstw_logo := TextureRect.new()
    nstw_logo.texture = NSTW_LOGO
    nstw_logo.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    nstw_logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    nstw_logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    nstw_logo.position = Vector2(10, 274)
    nstw_logo.size = Vector2(126, 60)
    nstw_logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
    nstw_logo.modulate.a = 0.0
    add_child(nstw_logo)
    nstw_node = nstw_logo

    # Explicit pixel coordinates in the 640x360 logical viewport: no center-anchor offset.
    var logo := TextureRect.new()
    logo.texture = LOGO
    logo.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    logo.position = Vector2(190, 73)
    logo.size = Vector2(260, 140)
    logo.modulate.a = 0.0
    logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(logo)
    title_node = logo

    var credit := _text("Made by maKate Studios", 12, Color("c5edf1"))
    credit.position = Vector2(190, 218)
    credit.size = Vector2(260, 20)
    credit.modulate.a = 0.0
    add_child(credit)
    credit_node = credit

    var subtitle := _text("THE OCEAN IS CALLING", 17, Color("b2edf6"))
    subtitle.position = Vector2(155, 262)
    subtitle.size = Vector2(330, 30)
    subtitle.modulate.a = 0.0
    add_child(subtitle)
    subtitle_node = subtitle

    var skip := _text("PRESS ANY KEY TO SKIP", 11, Color(0.72, 0.85, 0.91, 0.9))
    skip.position = Vector2(185, 326)
    skip.size = Vector2(270, 22)
    skip.modulate.a = 0.0
    add_child(skip)
    skip_node = skip

    overlay = ColorRect.new()
    overlay.color = Color.BLACK
    overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(overlay)
    # One controlled timeline: ambient reveal, title, credit, NSTW, then exit.
    var reveal := create_tween()
    reveal.tween_property(overlay, "color:a", 0.0, 1.2)
    reveal.parallel().tween_property(logo, "modulate:a", 1.0, 1.2).set_delay(1.6)
    reveal.parallel().tween_property(credit, "modulate:a", 1.0, 0.65).set_delay(3.0)
    reveal.parallel().tween_property(subtitle, "modulate:a", 1.0, 0.7).set_delay(3.4)
    reveal.parallel().tween_property(nstw_logo, "modulate:a", 1.0, 0.9).set_delay(4.2)
    reveal.parallel().tween_property(skip, "modulate:a", 0.8, 0.5).set_delay(5.1)

func _text(message: String, font_size: int, color: Color) -> Label:
    var label := Label.new()
    label.text = message
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.add_theme_font_override("font", PIXEL_FONT)
    label.add_theme_font_size_override("font_size", font_size)
    label.add_theme_color_override("font_color", color)
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    return label

func _add_clutter(region: Rect2, pos: Vector2, dimensions: Vector2) -> void:
    var atlas := AtlasTexture.new()
    atlas.atlas = CLUTTER
    atlas.region = region
    var sprite := TextureRect.new()
    sprite.texture = atlas
    sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    sprite.stretch_mode = TextureRect.STRETCH_SCALE
    sprite.position = pos
    sprite.size = dimensions
    sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(sprite)

func _process(delta: float) -> void:
    if finished:
        return
    elapsed += delta
    # Gentle light variation; no camera movement or exposed background edges.
    tint_node.color.a = 0.62 + sin(elapsed * 0.75) * 0.025
    if title_node.modulate.a > 0.99:
        title_node.scale = Vector2.ONE * (1.0 + sin(elapsed * 1.5) * 0.006)
        title_node.pivot_offset = title_node.size * 0.5
    var w := maxf(size.x, 1.0)
    var h := maxf(size.y, 1.0)
    for item in fish_data:
        var fish: TextureRect = item["node"]
        var travel := fposmod(float(item["start"]) + elapsed * float(item["speed"]), w + 100.0)
        var x := w + 40.0 - travel if bool(item["reverse"]) else travel - 40.0
        fish.position = Vector2(x, float(item["y"]) + sin(elapsed * 2.4 + float(item["phase"])) * 7.0)
    for item in bubble_data:
        var bubble: ColorRect = item["node"]
        bubble.position = Vector2(fposmod(float(item["x"]), w), h - fposmod(float(item["offset"]) + elapsed * float(item["speed"]), h + 20.0))
    if elapsed >= DURATION - 0.35:
        _finish()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        _finish()
    elif event is InputEventMouseButton and event.pressed:
        _finish()

func _finish() -> void:
    if finished:
        return
    finished = true
    var fade := create_tween()
    fade.tween_property(overlay, "color:a", 1.0, 0.35)
    await fade.finished
    get_tree().change_scene_to_file(MENU_PATH)
