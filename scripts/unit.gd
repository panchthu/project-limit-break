class_name Unit
extends Node2D
## Gemeinsame Basis fuer alles, was auf dem Raster steht und kaempft
## (Spieler und Gegner): Feld, Lebenspunkte, Bewegen, Angreifen, Schaden.

signal died

## Dauer der Schritt-Animation in Sekunden.
const MOVE_TIME := 0.12

@export var start_cell := Vector2i.ZERO
@export var max_hp := 10
@export var attack := 2
## Platzhalter-Farbe, bis echte Pixel-Art da ist.
@export var body_color := Color.WHITE
## Heller Rahmen, z. B. fuer Bosse.
@export var outlined := false

var cell: Vector2i
var hp: int
var facing := Vector2i.DOWN


func _ready() -> void:
	cell = start_cell
	hp = max_hp
	position = Grid.cell_to_world(cell)


func is_alive() -> bool:
	return hp > 0


## Einen Schritt auf ein freies Nachbarfeld machen (mit Animation).
func move_to(target: Vector2i) -> void:
	face(target - cell)
	cell = target
	var tween := create_tween()
	tween.tween_property(self, "position", Grid.cell_to_world(cell), MOVE_TIME)
	await tween.finished


## Kurz zum Ziel hin "stossen", dann Schaden austeilen.
func attack_unit(other: Unit) -> void:
	face(other.cell - cell)
	var home := Grid.cell_to_world(cell)
	var tween := create_tween()
	tween.tween_property(self, "position", home + Vector2(facing) * 6.0, 0.05)
	tween.tween_property(self, "position", home, 0.08)
	await tween.finished
	other.take_damage(attack)


func take_damage(amount: int) -> void:
	if not is_alive():
		return
	hp = max(hp - amount, 0)
	queue_redraw()
	# Kurzes rotes Aufblitzen als Treffer-Feedback.
	modulate = Color(1, 0.3, 0.3)
	create_tween().tween_property(self, "modulate", Color.WHITE, 0.2)
	if hp == 0:
		_die()


func heal_full() -> void:
	hp = max_hp
	queue_redraw()


func face(dir: Vector2i) -> void:
	if dir != Vector2i.ZERO:
		facing = dir
		queue_redraw()


## Wird von Spieler und Gegner erweitert.
func _die() -> void:
	died.emit()


func _draw() -> void:
	var s := Grid.TILE_SIZE
	draw_rect(Rect2(2, 3, s - 4, s - 5), body_color)
	if outlined:
		draw_rect(Rect2(1.5, 2.5, s - 3, s - 4), Color("ffe08a"), false, 1.0)
	# Kleiner Punkt zeigt die Blickrichtung.
	var center := Vector2(s, s + 1) / 2.0
	var eye := center + Vector2(facing) * 4.0 - Vector2(1, 1)
	draw_rect(Rect2(eye, Vector2(2, 2)), Color("1d1a2f"))
	# Lebensbalken ueber der Figur.
	var bar_width := s - 4
	draw_rect(Rect2(2, 0, bar_width, 2), Color("1d1a2f"))
	draw_rect(Rect2(2, 0, round(bar_width * float(hp) / max_hp), 2), Color("6cd36c"))
