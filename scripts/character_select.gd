extends Control
## Kaempfer-Auswahl: links/rechts waehlen, Enter startet den Run, Esc zurueck zum Titel.

const BOX_SIZE := Vector2(64, 64)
const BOX_GAP := 24.0
const BOX_TOP := 40.0

var selected := 0

@onready var name_label: Label = $NameLabel
@onready var stats_label: Label = $StatsLabel
@onready var description_label: Label = $DescriptionLabel


func _ready() -> void:
	selected = Game.fighter_index
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
	var fighter: Dictionary = Game.FIGHTERS[selected]
	name_label.text = fighter.name
	stats_label.text = "HP %d   Angriff %d" % [fighter.max_hp, fighter.attack]
	description_label.text = fighter.description
	queue_redraw()


func _box_rect(index: int) -> Rect2:
	var count := Game.FIGHTERS.size()
	var total_width := count * BOX_SIZE.x + (count - 1) * BOX_GAP
	var left := (size.x - total_width) / 2.0
	return Rect2(Vector2(left + index * (BOX_SIZE.x + BOX_GAP), BOX_TOP), BOX_SIZE)


## Drei farbige Kaestchen als Platzhalter fuer die Kaempfer-Portraets.
func _draw() -> void:
	for i in Game.FIGHTERS.size():
		var rect := _box_rect(i)
		var color: Color = Game.FIGHTERS[i].color
		if i != selected:
			color = color.darkened(0.55)
		draw_rect(rect, color)
		if i == selected:
			draw_rect(rect.grow(2), Color("ffe08a"), false, 1.0)
