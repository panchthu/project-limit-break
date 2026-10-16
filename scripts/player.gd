extends Unit
## Spielfigur. Liest nur die Eingabe; was daraus wird (laufen oder
## angreifen), entscheidet die Hauptszene, weil sie die Zuege verwaltet.


## Nur eine Richtung gleichzeitig, keine Diagonalen.
func read_direction() -> Vector2i:
	if Input.is_action_pressed("move_up"):
		return Vector2i.UP
	if Input.is_action_pressed("move_down"):
		return Vector2i.DOWN
	if Input.is_action_pressed("move_left"):
		return Vector2i.LEFT
	if Input.is_action_pressed("move_right"):
		return Vector2i.RIGHT
	return Vector2i.ZERO


func _die() -> void:
	modulate = Color(0.4, 0.4, 0.4)
	super()
