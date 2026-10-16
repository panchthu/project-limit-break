class_name Unit
extends Node2D
## Gemeinsame Basis fuer alles, was auf dem Raster steht und kaempft
## (Spieler und Gegner): Feld, Lebenspunkte, Bewegen, Angreifen, Schaden.

signal died

## Posen im Sprite-Streifen der Helden (in dieser Reihenfolge). Gegner haben nur eine Pose.
enum Pose { IDLE, GEHEN, ANGRIFF1, ANGRIFF2, SPEZIAL, TREFFER, KO }

## Dauer der Schritt-Animation in Sekunden.
const MOVE_TIME := 0.12
## Flugzeit eines Ki-Schusses.
const BLAST_TIME := 0.15
## So lange bleibt die Treffer-Pose stehen.
const HURT_TIME := 0.25
## Hoehe der Haende ueber der Feld-Oberkante: hier starten Ki-Schuesse und Strahlen.
const HAND_OFFSET := Vector2(8, 2)
const SHADOW_COLOR := Color(0, 0, 0, 0.35)
const BOSS_SHADOW_COLOR := Color(1, 0.878, 0.541, 0.45)

@export var start_cell := Vector2i.ZERO
@export var max_hp := 10
@export var attack := 2
## Ersatzfarbe fuer ein Kaestchen, falls kein Sprite gesetzt ist.
@export var body_color := Color.WHITE
## Goldener Schatten, z. B. fuer Bosse.
@export var outlined := false

var cell: Vector2i
var hp: int
var facing := Vector2i.DOWN

## Das Bild der Figur. Fuesse stehen unten mittig auf dem Feld, der Kopf ragt nach oben raus.
var _sprite := Sprite2D.new()
## Schaut die Figur im Bild nach links? (Gegner ja, Helden nach rechts.)
var _sprite_faces_left := false
var _looks_left := false
## Schlaege wechseln zwischen den beiden Angriffs-Posen.
var _next_attack_pose := Pose.ANGRIFF1
## Laufender Rueckweg zur Idle-Pose (wird abgebrochen, wenn eine neue Pose kommt).
var _pose_tween: Tween


func _init() -> void:
	_sprite.centered = false
	_sprite.visible = false
	add_child(_sprite)


func _ready() -> void:
	cell = start_cell
	hp = max_hp
	position = Grid.cell_to_world(cell)


## Bild setzen: ein Streifen mit frames Posen nebeneinander (1 = nur eine Pose).
func set_sprite(texture: Texture2D, frames: int, faces_left: bool) -> void:
	if texture == null:
		return
	_sprite.texture = texture
	_sprite.hframes = frames
	_sprite.visible = true
	_sprite_faces_left = faces_left
	_looks_left = faces_left
	var frame_size := Vector2(texture.get_width() / frames, texture.get_height())
	_sprite.offset = Vector2(-floorf(frame_size.x / 2.0), -frame_size.y)
	_sprite.position = Vector2(Grid.TILE_SIZE / 2.0, Grid.TILE_SIZE)
	_update_flip()
	queue_redraw()


func has_sprite() -> bool:
	return _sprite.visible


## Hoehe einer Pose in Pixeln.
func sprite_height() -> float:
	if not has_sprite():
		return Grid.TILE_SIZE
	return _sprite.texture.get_height()


## Toenung und Groesse des Bildes (z. B. fuer Verwandlungen). Die Fuesse bleiben auf dem Feld.
func set_look(tint: Color, scale_factor: float) -> void:
	_sprite.self_modulate = tint
	_sprite.scale = Vector2.ONE * scale_factor
	queue_redraw()


## Breite einer Pose in Pixeln (fuer Schatten und Lebensbalken).
func sprite_width() -> float:
	if not has_sprite():
		return Grid.TILE_SIZE
	return _sprite.texture.get_width() / float(_sprite.hframes)


## Pose zeigen (hat die Figur sie nicht, bleibt das Bild wie es ist).
func set_pose(pose: Pose) -> void:
	if _pose_tween:
		_pose_tween.kill()
		_pose_tween = null
	if pose < _sprite.hframes:
		_sprite.frame = pose


## Pose kurz zeigen, danach zurueck zur Idle-Pose.
func flash_pose(pose: Pose, duration: float) -> void:
	set_pose(pose)
	_pose_tween = create_tween()
	_pose_tween.tween_interval(duration)
	_pose_tween.tween_callback(_back_to_idle)


func _back_to_idle() -> void:
	if is_alive():
		set_pose(Pose.IDLE)


## Kopie des aktuellen Bildes (z. B. fuer das Nachbild), an derselben Stelle.
func sprite_copy() -> Sprite2D:
	var copy: Sprite2D = _sprite.duplicate()
	copy.position += position
	return copy


func is_alive() -> bool:
	return hp > 0


## Einen Schritt auf ein freies Nachbarfeld machen (mit Animation).
func move_to(target: Vector2i) -> void:
	face(target - cell)
	set_pose(Pose.GEHEN)
	await slide_to(target, MOVE_TIME)
	_back_to_idle()


## Auf ein Feld rutschen, ohne sich umzudrehen (z. B. wenn man geworfen wird).
func slide_to(target: Vector2i, duration: float) -> void:
	cell = target
	var tween := create_tween()
	tween.tween_property(self, "position", Grid.cell_to_world(cell), duration)
	await tween.finished


## Kurz in Blickrichtung "stossen" (nur Animation, kein Schaden).
func lunge_at(other: Unit) -> void:
	face((other.cell - cell).sign())
	set_pose(_next_attack_pose)
	_next_attack_pose = Pose.ANGRIFF2 if _next_attack_pose == Pose.ANGRIFF1 else Pose.ANGRIFF1
	var home := Grid.cell_to_world(cell)
	var tween := create_tween()
	tween.tween_property(self, "position", home + Vector2(facing) * 6.0, 0.05)
	tween.tween_property(self, "position", home, 0.08)
	# Die Schlag-Pose kurz stehen lassen, damit man sie sieht.
	tween.tween_interval(0.06)
	await tween.finished
	_back_to_idle()


## Ki-Schuss: ein Lichtball fliegt zum Ziel (nur Animation, kein Schaden).
func fire_blast(target: Unit, color: Color) -> void:
	face((target.cell - cell).sign())
	set_pose(Pose.SPEZIAL)
	var blast := ColorRect.new()
	blast.color = color
	blast.size = Vector2(4, 4)
	var start := HAND_OFFSET - blast.size / 2.0
	blast.position = start
	blast.z_index = 1
	add_child(blast)
	var tween := create_tween()
	tween.tween_property(blast, "position", start + target.position - position, BLAST_TIME)
	await tween.finished
	blast.queue_free()
	_back_to_idle()


## Zustossen, dann Schaden austeilen. Ohne amount zaehlt der normale Angriffswert.
func attack_unit(other: Unit, amount := -1) -> void:
	await lunge_at(other)
	other.take_damage(attack if amount < 0 else amount)


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
	else:
		flash_pose(Pose.TREFFER, HURT_TIME)


func heal(amount: int) -> void:
	if is_alive():
		hp = min(hp + amount, max_hp)
		queue_redraw()


func heal_full() -> void:
	hp = max_hp
	queue_redraw()


func face(dir: Vector2i) -> void:
	if dir != Vector2i.ZERO:
		facing = dir
		# Hoch und runter gibt es im Bild nicht, dann bleibt die alte Seite.
		if dir.x != 0:
			_looks_left = dir.x < 0
			_update_flip()
		queue_redraw()


func _update_flip() -> void:
	_sprite.flip_h = _looks_left != _sprite_faces_left


## Wird von Spieler und Gegner erweitert.
func _die() -> void:
	set_pose(Pose.KO)
	died.emit()


## Unter dem Bild: Schatten an den Fuessen und Lebensbalken. Ohne Sprite ein Kaestchen.
func _draw() -> void:
	var s := Grid.TILE_SIZE
	if not has_sprite():
		_draw_box()
		return
	var width := sprite_width()
	# Schatten als flache Ellipse unter den Fuessen.
	var radius := clampf(width * 0.35, 6.0, 16.0)
	draw_set_transform(Vector2(s / 2.0, s - 1.0), 0.0, Vector2(1.0, 0.3))
	draw_circle(Vector2.ZERO, radius, BOSS_SHADOW_COLOR if outlined else SHADOW_COLOR)
	draw_set_transform(Vector2.ZERO)
	# Lebensbalken direkt unter den Fuessen, bei grossen Figuren breiter.
	var bar_width := clampf(round(width * 0.6), 12.0, 28.0)
	var bar := Rect2((s - bar_width) / 2.0, s, bar_width, 2)
	draw_rect(bar, Color("1d1a2f"))
	bar.size.x = round(bar_width * float(hp) / max_hp)
	draw_rect(bar, Color("6cd36c"))


## Ersatz-Grafik ohne Sprite: farbiges Kaestchen mit Punkt fuer die Blickrichtung.
func _draw_box() -> void:
	var s := Grid.TILE_SIZE
	draw_rect(Rect2(2, 3, s - 4, s - 5), body_color)
	if outlined:
		draw_rect(Rect2(1.5, 2.5, s - 3, s - 4), Color("ffe08a"), false, 1.0)
	var center := Vector2(s, s + 1) / 2.0
	var eye := center + Vector2(facing) * 4.0 - Vector2(1, 1)
	draw_rect(Rect2(eye, Vector2(2, 2)), Color("1d1a2f"))
	var bar_width := s - 4
	draw_rect(Rect2(2, 0, bar_width, 2), Color("1d1a2f"))
	draw_rect(Rect2(2, 0, round(bar_width * float(hp) / max_hp), 2), Color("6cd36c"))
