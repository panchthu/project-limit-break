extends Control
## Kaempfer-Auswahl: links/rechts waehlen, Enter startet den Run, Esc zurueck zum Titel.

## Die Artworks sind 120 x 160 gross und werden auf halbe Groesse verkleinert.
const CARD_SIZE := Vector2(60, 80)
const CARD_GAP := 20.0
const CARD_TOP := 4.0
const FRAME_COLOR := Color("ffe08a")

var selected := 0
var _cards: Array[TextureRect] = []

@onready var name_label: Label = $NameLabel
@onready var stats_label: Label = $StatsLabel
@onready var ability_label: Label = $AbilityLabel
@onready var description_label: Label = $DescriptionLabel
@onready var technique_label: Label = $TechniqueLabel


func _ready() -> void:
	selected = Game.fighter_index
	for i in Game.FIGHTERS.size():
		var card := TextureRect.new()
		card.texture = Game.FIGHTERS[i].artwork
		card.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		card.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		# Weich verkleinern, sonst flimmern die Details.
		card.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		var rect := _card_rect(i)
		card.position = rect.position
		card.size = rect.size
		add_child(card)
		_cards.append(card)
	_refresh()


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("move_left"):
		_change(-1)
	elif Input.is_action_just_pressed("move_right"):
		_change(1)
	elif Input.is_action_just_pressed("confirm"):
		Game.start_run(selected)
	elif Input.is_action_just_pressed("back"):
		Game.goto_title()


func _change(step: int) -> void:
	selected = wrapi(selected + step, 0, Game.FIGHTERS.size())
	_refresh()


func _refresh() -> void:
	var fighter := Game.FIGHTERS[selected]
	name_label.text = fighter.display_name
	stats_label.text = "HP %d   Angriff %d   Ki %d" % [fighter.max_hp, fighter.attack, fighter.max_ki]
	ability_label.text = "%s: %s" % [fighter.ability_name, fighter.ability_text]
	var lines: PackedStringArray = []
	var keys := ["Q", "E"]
	for i in fighter.techniques.size():
		var technique := fighter.techniques[i]
		lines.append("%s %s (%d Ki): %s" % [keys[i], technique.display_name, technique.ki_cost, technique.description])
	technique_label.text = "\n".join(lines)
	description_label.text = fighter.description
	for i in _cards.size():
		_cards[i].modulate = Color.WHITE if i == selected else Color(0.4, 0.38, 0.5)
	queue_redraw()


func _card_rect(index: int) -> Rect2:
	var count := Game.FIGHTERS.size()
	var total_width := count * CARD_SIZE.x + (count - 1) * CARD_GAP
	var left := roundf((get_viewport_rect().size.x - total_width) / 2.0)
	return Rect2(Vector2(left + index * (CARD_SIZE.x + CARD_GAP), CARD_TOP), CARD_SIZE)


## Goldener Rahmen um das gewaehlte Artwork.
func _draw() -> void:
	draw_rect(_card_rect(selected).grow(2), FRAME_COLOR, false, 1.0)
