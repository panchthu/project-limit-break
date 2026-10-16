extends Control
## Titelbildschirm: Logo als Platzhalter, Enter startet die Kaempfer-Auswahl.

@onready var hint_label: Label = $HintLabel

var _time := 0.0


func _process(delta: float) -> void:
	# "Druecke Enter" blinkt langsam.
	_time += delta
	hint_label.visible = fmod(_time, 1.0) < 0.7
	if Input.is_action_just_pressed("confirm"):
		Game.goto_select()
	elif Input.is_action_just_pressed("back"):
		get_tree().quit()
