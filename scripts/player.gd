class_name Player
extends Unit
## Spielfigur. Liest die Eingabe und setzt die Spezialfaehigkeiten des
## gewaehlten Kaempfers um. Wann gelaufen oder angegriffen wird,
## entscheidet die Hauptszene, weil sie die Zuege verwaltet.

## Farbe und Flugzeit des Ki-Strahls.
const KI_BLAST_COLOR := Color("aef3ff")
const KI_BLAST_TIME := 0.15
## Flugzeit pro Feld, wenn ein Gegner geworfen wird.
const THROW_TIME_PER_CELL := 0.06

var fighter: FighterData


## Werte des gewaehlten Kaempfers uebernehmen.
func setup(data: FighterData) -> void:
	fighter = data
	max_hp = data.max_hp
	attack = data.attack
	body_color = data.color
	heal_full()


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


## Ki-Strahl: ein Lichtball fliegt zum Ziel, dann gibt es Schaden.
func shoot(target: Unit) -> void:
	face((target.cell - cell).sign())
	var blast := ColorRect.new()
	blast.color = KI_BLAST_COLOR
	blast.size = Vector2(4, 4)
	var start := Vector2(Grid.TILE_SIZE, Grid.TILE_SIZE) / 2.0 - blast.size / 2.0
	blast.position = start
	blast.z_index = 1
	add_child(blast)
	var tween := create_tween()
	tween.tween_property(blast, "position", start + target.position - position, KI_BLAST_TIME)
	await tween.finished
	blast.queue_free()
	target.take_damage(attack)


## Wurf: den (noch lebenden) Gegner in Blickrichtung wegschleudern.
## Knallt er vorher gegen etwas, gibt es Extra-Schaden. Gibt den Extra-Schaden zurueck.
func throw_unit(target: Unit, is_free: Callable) -> int:
	var landing := target.cell
	for i in fighter.throw_distance:
		if not is_free.call(landing + facing):
			break
		landing += facing
	var flown := (landing - target.cell).length()
	if landing != target.cell:
		await target.slide_to(landing, THROW_TIME_PER_CELL * flown)
	if flown < fighter.throw_distance and fighter.throw_slam_damage > 0:
		target.take_damage(fighter.throw_slam_damage)
		return fighter.throw_slam_damage
	return 0


## Ein Gegner greift an. Hier wirken Ausweichen, Super-Armor und Konter.
## Gibt den Text fuer die Meldungszeile zurueck.
func defend(attacker: Unit) -> String:
	await attacker.lunge_at(self)
	if randf() < fighter.dodge_chance:
		await _dodge_from(attacker)
		return "Ausgewichen!"
	var damage: int = max(attacker.attack - fighter.armor, 1)
	take_damage(damage)
	var text := "Autsch! -%d" % damage
	if fighter.counter_damage > 0 and is_alive() and attacker.is_alive():
		await attack_unit(attacker, fighter.counter_damage)
		text += "  Konter! -%d" % fighter.counter_damage
	return text


## Kurzer Seitenschritt weg vom Angreifer und zurueck.
func _dodge_from(attacker: Unit) -> void:
	var away := Vector2((cell - attacker.cell).sign())
	var side := Vector2(away.y, away.x) * 5.0
	var home := Grid.cell_to_world(cell)
	var tween := create_tween()
	tween.tween_property(self, "position", home + side, 0.06)
	tween.tween_property(self, "position", home, 0.08)
	await tween.finished


func _die() -> void:
	modulate = Color(0.4, 0.4, 0.4)
	super()
