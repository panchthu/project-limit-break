extends Unit
## Einfacher Gegner: greift an, wenn er neben dem Spieler steht,
## sonst geht er einen Schritt auf ihn zu.


func _ready() -> void:
	super()
	add_to_group("enemies")


## Waehlt den naechsten Schritt Richtung Ziel. is_free(cell) sagt, ob ein Feld frei ist.
func next_step(target: Vector2i, is_free: Callable) -> Vector2i:
	var diff := target - cell
	var horizontal := Vector2i(signi(diff.x), 0)
	var vertical := Vector2i(0, signi(diff.y))
	# Zuerst entlang der laengeren Strecke, sonst die andere Achse probieren.
	var options := [horizontal, vertical] if abs(diff.x) >= abs(diff.y) else [vertical, horizontal]
	for dir: Vector2i in options:
		if dir != Vector2i.ZERO and is_free.call(cell + dir):
			return dir
	return Vector2i.ZERO


func _die() -> void:
	# Sofort aus der Gruppe, damit der Gegner nicht mehr mitspielt.
	remove_from_group("enemies")
	super()
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.finished.connect(queue_free)
