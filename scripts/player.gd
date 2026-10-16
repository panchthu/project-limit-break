class_name Player
extends Unit
## Spielfigur. Liest die Eingabe und setzt die Spezialfaehigkeiten des
## gewaehlten Kaempfers um. Wann gelaufen oder angegriffen wird,
## entscheidet die Hauptszene, weil sie die Zuege verwaltet.

## Farbe des Ki-Strahls.
const KI_BLAST_COLOR := Color("aef3ff")
## Farbe der Ki-Schuesse der Gegner.
const ENEMY_BLAST_COLOR := Color("ff8a6b")
## Flugzeit pro Feld, wenn ein Gegner geworfen wird.
const THROW_TIME_PER_CELL := 0.06
## Farbe der Ki-Aura beim Aufladen.
const KI_AURA_COLOR := Color("8fe8ff")

## Ki hat sich geaendert (fuer die Anzeige).
signal ki_changed

var fighter: FighterData
var ki := 0
var max_ki := 10
## Konter-Haltung: Schaden, den jeder Angreifer im naechsten Gegnerzug kassiert (0 = aus).
var counter_stance := 0
## Nachbild: im naechsten Gegnerzug weicht er jedem Angriff aus.
var sure_dodge := false


## Werte des gewaehlten Kaempfers uebernehmen.
func setup(data: FighterData) -> void:
	fighter = data
	max_hp = data.max_hp
	attack = data.attack
	body_color = data.color
	set_sprite(data.sprite_sheet, Pose.size(), false)
	max_ki = data.max_ki
	heal_full()
	set_ki(data.start_ki)


func set_ki(value: int) -> void:
	ki = clampi(value, 0, max_ki)
	ki_changed.emit()


func gain_ki(amount: int) -> void:
	set_ki(ki + amount)


func can_afford(technique: TechniqueData) -> bool:
	return ki >= technique.ki_cost


## Haltungen gelten nur fuer einen Gegnerzug.
func clear_stances() -> void:
	counter_stance = 0
	sure_dodge = false
	queue_redraw()


## Ki aufladen: Aura flackert kurz auf.
func charge() -> void:
	gain_ki(fighter.ki_charge)
	await charge_flash()


## Kurzes Aufleuchten in Ki-Farbe.
func charge_flash() -> void:
	set_pose(Pose.SPEZIAL)
	modulate = KI_AURA_COLOR * 1.6
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.35)
	await tween.finished
	_back_to_idle()


## Nur eine Richtung gleichzeitig, keine Diagonalen.
## Mit just = true zaehlt nur ein frischer Tastendruck (nicht gedrueckt halten).
func read_direction(just := false) -> Vector2i:
	var directions := {
		"move_up": Vector2i.UP,
		"move_down": Vector2i.DOWN,
		"move_left": Vector2i.LEFT,
		"move_right": Vector2i.RIGHT,
	}
	for action: String in directions:
		var pressed := Input.is_action_just_pressed(action) if just else Input.is_action_pressed(action)
		if pressed:
			return directions[action]
	return Vector2i.ZERO


## Ki-Strahl: ein Lichtball fliegt zum Ziel, dann gibt es Schaden.
func shoot(target: Unit, amount := -1) -> void:
	await fire_blast(target, KI_BLAST_COLOR)
	target.take_damage(attack if amount < 0 else amount)


## Ki-Welle: ein breiter Strahl von der Figur bis cells Felder weit.
func beam(dir: Vector2i, cells: int) -> void:
	face(dir)
	set_pose(Pose.SPEZIAL)
	var ray := ColorRect.new()
	ray.color = KI_BLAST_COLOR
	var length := cells * Grid.TILE_SIZE
	var thick := 6.0
	# Rechteck von den Haenden der Figur in Richtung dir.
	var a := HAND_OFFSET
	var b := a + Vector2(dir) * length
	ray.position = Vector2(min(a.x, b.x), min(a.y, b.y)) - Vector2(thick, thick) / 2.0 * Vector2(absi(dir.y), absi(dir.x))
	ray.size = (b - a).abs() + Vector2(thick * absi(dir.y), thick * absi(dir.x))
	ray.z_index = 1
	add_child(ray)
	var tween := create_tween()
	tween.tween_property(ray, "modulate:a", 0.0, 0.3)
	await tween.finished
	ray.queue_free()
	_back_to_idle()


## Nachbild: ein blasser Abdruck bleibt stehen, die Figur rutscht weiter.
func dash_to(target: Vector2i) -> void:
	var ghost: CanvasItem
	if has_sprite():
		ghost = sprite_copy()
		ghost.modulate = Color(KI_AURA_COLOR, 0.7)
	else:
		var box := ColorRect.new()
		box.color = Color(body_color, 0.6)
		box.position = position + Vector2(2, 3)
		box.size = Vector2(Grid.TILE_SIZE - 4, Grid.TILE_SIZE - 5)
		ghost = box
	get_parent().add_child(ghost)
	var fade := ghost.create_tween()
	fade.tween_property(ghost, "modulate:a", 0.0, 0.4)
	fade.tween_callback(ghost.queue_free)
	face((target - cell).sign())
	set_pose(Pose.GEHEN)
	await slide_to(target, 0.08)
	_back_to_idle()


## Wurf: den (noch lebenden) Gegner in Blickrichtung wegschleudern.
## Knallt er vorher gegen etwas, gibt es Extra-Schaden. Gibt den Extra-Schaden zurueck.
## Ohne distance/slam zaehlen die Werte des Kaempfers; dir ist sonst die Blickrichtung.
func throw_unit(target: Unit, is_free: Callable, distance := -1, slam := -1, dir := Vector2i.ZERO) -> int:
	if distance < 0:
		distance = fighter.throw_distance
	if slam < 0:
		slam = fighter.throw_slam_damage
	if dir == Vector2i.ZERO:
		dir = facing
	var landing := target.cell
	for i in distance:
		if not is_free.call(landing + dir):
			break
		landing += dir
	var flown := (landing - target.cell).length()
	if landing != target.cell:
		await target.slide_to(landing, THROW_TIME_PER_CELL * flown)
	if flown < distance and slam > 0:
		target.take_damage(slam)
		return slam
	return 0


## Ein Gegner greift an. Hier wirken Haltungen, Ausweichen, Super-Armor und Konter.
## ranged = Ki-Schuss aus der Ferne (dann gibt es keinen Konter).
## Gibt den Text fuer die Meldungszeile zurueck.
func defend(attacker: Unit, ranged := false) -> String:
	if ranged:
		await attacker.fire_blast(self, ENEMY_BLAST_COLOR)
	else:
		await attacker.lunge_at(self)
	if counter_stance > 0:
		if ranged:
			return "Geblockt!"
		await attack_unit(attacker, counter_stance)
		return "Geblockt!  Konter! -%d" % counter_stance
	if sure_dodge or randf() < fighter.dodge_chance:
		await _dodge_from(attacker)
		return "Ausgewichen!"
	var damage: int = max(attacker.attack - fighter.armor, 1)
	take_damage(damage)
	var text := ("Ki-Schuss! -%d" if ranged else "Autsch! -%d") % damage
	if fighter.counter_damage > 0 and not ranged and is_alive() and attacker.is_alive():
		await attack_unit(attacker, fighter.counter_damage)
		text += "  Konter! -%d" % fighter.counter_damage
	return text


## Spezialattacke eines Bosses trifft. Nur Haltungen helfen noch, Super-Armor zieht ab.
func take_special(attacker: Unit, amount: int) -> String:
	if counter_stance > 0:
		return "Geblockt!"
	if sure_dodge:
		await _dodge_from(attacker)
		return "Ausgewichen!"
	var damage: int = max(amount - fighter.armor, 1)
	take_damage(damage)
	return "Volltreffer! -%d" % damage


## Kurzer Seitenschritt weg vom Angreifer und zurueck.
func _dodge_from(attacker: Unit) -> void:
	var away := Vector2((cell - attacker.cell).sign())
	var side := Vector2(away.y, away.x) * 5.0
	var home := Grid.cell_to_world(cell)
	set_pose(Pose.GEHEN)
	var tween := create_tween()
	tween.tween_property(self, "position", home + side, 0.06)
	tween.tween_property(self, "position", home, 0.08)
	await tween.finished
	_back_to_idle()


func _die() -> void:
	modulate = Color(0.6, 0.6, 0.6)
	super()


func _draw() -> void:
	super()
	# Aktive Haltung als Ki-Ring um die Fuesse.
	if counter_stance > 0 or sure_dodge:
		var s := Grid.TILE_SIZE
		draw_set_transform(Vector2(s / 2.0, s - 1.0), 0.0, Vector2(1.0, 0.35))
		draw_arc(Vector2.ZERO, 10.0, 0.0, TAU, 24, KI_AURA_COLOR, 1.0)
		draw_set_transform(Vector2.ZERO)
