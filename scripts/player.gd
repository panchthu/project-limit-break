extends Node2D
## Spielfigur, die sich Feld fuer Feld auf dem Raster bewegt.
## Jeder Schritt ist ein "Zug" (signal moved).

signal moved(cell: Vector2i)

## Dauer der Schritt-Animation in Sekunden.
const MOVE_TIME := 0.12

@export var start_cell := Vector2i(2, 2)

var cell: Vector2i
var facing := Vector2i.DOWN
var _is_moving := false


func _ready() -> void:
	cell = start_cell
	position = Grid.cell_to_world(cell)


func _process(_delta: float) -> void:
	# Waehrend eines Schritts keine neue Eingabe: so bleibt alles im Raster.
	if _is_moving:
		return
	var dir := _read_direction()
	if dir != Vector2i.ZERO:
		try_move(dir)


func try_move(dir: Vector2i) -> void:
	facing = dir
	queue_redraw()
	var target := cell + dir
	if not Grid.is_inside(target):
		return
	cell = target
	_is_moving = true
	var tween := create_tween()
	tween.tween_property(self, "position", Grid.cell_to_world(cell), MOVE_TIME)
	tween.finished.connect(_on_move_finished)


func _on_move_finished() -> void:
	_is_moving = false
	moved.emit(cell)


## Nur eine Richtung gleichzeitig, keine Diagonalen.
func _read_direction() -> Vector2i:
	if Input.is_action_pressed("move_up"):
		return Vector2i.UP
	if Input.is_action_pressed("move_down"):
		return Vector2i.DOWN
	if Input.is_action_pressed("move_left"):
		return Vector2i.LEFT
	if Input.is_action_pressed("move_right"):
		return Vector2i.RIGHT
	return Vector2i.ZERO


## Platzhalter-Grafik, bis echte Pixel-Art da ist.
func _draw() -> void:
	var s := Grid.TILE_SIZE
	draw_rect(Rect2(2, 2, s - 4, s - 4), Color("f2a541"))
	# Kleiner Punkt zeigt die Blickrichtung.
	var center := Vector2(s, s) / 2.0
	var eye := center + Vector2(facing) * 4.0 - Vector2(1, 1)
	draw_rect(Rect2(eye, Vector2(2, 2)), Color("1d1a2f"))
