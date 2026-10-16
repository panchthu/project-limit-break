extends Control
## Ergebnis nach dem Run: Sieg oder Game Over.
## Enter = zurueck zum Titel, R = gleicher Kaempfer nochmal.

@onready var headline_label: Label = $HeadlineLabel
@onready var info_label: Label = $InfoLabel


func _ready() -> void:
	if Game.last_run_won:
		headline_label.text = "SIEG!"
		headline_label.modulate = Color("ffe08a")
	else:
		headline_label.text = "GAME OVER"
		headline_label.modulate = Color("d94d6b")
	info_label.text = "%s  -  Map %d/%d  -  %d Zuege" % [
		Game.fighter().display_name, Game.map_index + 1, Game.MAPS.size(), Game.last_run_turns]


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("confirm"):
		Game.goto_title()
	elif Input.is_action_just_pressed("restart"):
		Game.start_run(Game.fighter_index)
