extends Label

# the facts and awareness lines on the main menu. one line at a time, facts and awareness are mixed in random order
# this label and its child SourceLabel are nodes in MainMenu.tscn, move them there. the source is only shown for facts

@export var change_time = 8.0 # seconds each line stays
@export var fade_time = 0.6 # seconds to fade out or in
@export var source_gap = 5.0 # space between the line and its source

# text, source
const FACTS = [
	["General Santos, the Tuna Capital of the Philippines, sits near the tuna-rich fishing grounds of the Celebes Sea.", "SEAFDEC / USAID Oceans"],
	["General Santos had the most plastic litter of the Sarangani Bay sites surveyed. Across all sites, over half was plastic bags and food packaging.", "UP Open University, 2023"],
	["Microplastics have been found in fish sold at the General Santos fish port, including mackerel tuna.", "MSU-General Santos, 2024"],
	["Plastic can harm fish by blocking their guts, starving them and building up toxins. It has even been found in flying fish, which tuna eat.", "NOAA Fisheries, 2019"],
	["Overfishing and climate change have cut General Santos tuna catches by at least 10% in five years.", "Manila Bulletin, 2024"],
]

const AWARENESS = [
	"Plastic bags and food wrappers are what pile up on our beaches. Bring your own bag and container.",
	"Say no to single-use sachets and plastic bags when you can.",
	"Never leave trash on the beach. What the tide takes, the sea keeps.",
	"Rivers and esteros carry trash to Sarangani Bay. Clean streets mean a cleaner sea.",
	"Join a coastal or river clean-up in your area.",
	"Choose tuna and seafood that is caught legally and responsibly.",
	"A warming sea means fewer fish. Save energy and cut waste where you can.",
	"Share what you learn. Change starts when people know.",
]

@onready var source_label = $SourceLabel

var lines = [] # what is left to show, every line shows once before any repeats
var last_text = ""
var timer = 0.0


func _ready():
	_show_next()


func _process(delta):
	timer += delta
	if timer < change_time:
		return
	timer = 0.0
	var fade = create_tween()
	fade.tween_property(self, "modulate:a", 0.0, fade_time)
	fade.tween_callback(_show_next)
	fade.tween_property(self, "modulate:a", 1.0, fade_time)


# all facts and awareness lines in one shuffled list
func _refill():
	lines = []
	for fact in FACTS:
		lines.append(fact)
	for awareness in AWARENESS:
		lines.append([awareness, ""])
	lines.shuffle()
	# the same line never shows twice in a row
	if lines[lines.size() - 1][0] == last_text:
		lines.reverse()


func _show_next():
	if lines.is_empty():
		_refill()
	var line = lines.pop_back()
	last_text = line[0]
	text = line[0]
	if line[1] == "":
		source_label.text = ""
	else:
		source_label.text = "[" + line[1] + "]"
	_place_source()


# the source goes right under the last line, however many lines the text has
func _place_source():
	size.y = 0.0 # shrink to the text
	source_label.position.y = get_combined_minimum_size().y + source_gap
