class_name Player
extends Unit
## Spielfigur. Liest die Eingabe und setzt die Spezialfaehigkeiten des
## gewaehlten Kaempfers um. Wann gelaufen oder angegriffen wird,
## entscheidet die Hauptszene, weil sie die Zuege verwaltet.
## Die Werte kommen aus dem Kaempfer des Runs (mit Upgrades) plus der Verwandlung, falls aktiv.

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
## Aktive Verwandlung (null = normal).
var form: TransformationData = null
## Laufende Zeit fuer das Flackern der Aura.
var _aura_time := 0.0


## Werte des gewaehlten Kaempfers uebernehmen.
func setup(data: FighterData) -> void:
	fighter = data
	body_color = data.color
	set_sprite(data.sprite_sheet, Pose.size(), false)
	refresh_stats()
	heal_full()
	set_ki(data.start_ki)


## Werte neu aus den Daten holen (nach einem Upgrade oder beim Verwandeln).
func refresh_stats() -> void:
	max_hp = fighter.max_hp
	attack = fighter.attack + (form.bonus_attack if form else 0)
	max_ki = fighter.max_ki
	hp = min(hp, max_hp)
	set_ki(ki)


func is_transformed() -> bool:
	return form != null


## Verwandeln geht, wenn sie erwacht ist, die Ki-Leiste voll ist und er nicht schon verwandelt ist.
func can_transform() -> bool:
	return Game.transformation_unlocked and fighter.transformation != null \
		and not is_transformed() and ki >= max_ki


## Verwandlung beginnt: Aura, Toenung, Groesse und Bonuswerte.
func transform() -> void:
	form = fighter.transformation
	Game.transformed_once = true
	refresh_stats()
	if form.sprite_sheet:
		_swap_sheet(form.sprite_sheet)
		set_look(Color.WHITE, form.sprite_scale)
	else:
		set_look(form.aura_color.lerp(Color.WHITE, 0.45), form.sprite_scale)
	set_pose(Pose.SPEZIAL)
	modulate = form.aura_color * 2.0
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.5)
	await tween.finished
	_back_to_idle()


## Verwandlung endet (Ki ist leer).
func revert() -> void:
	if form.sprite_sheet:
		_swap_sheet(fighter.sprite_sheet)
	form = null
	refresh_stats()
	set_look(Color.WHITE, 1.0)


## Anderes Posen-Bild, die Figur schaut weiter in dieselbe Richtung.
func _swap_sheet(texture: Texture2D) -> void:
	var looks_left := _looks_left
	set_sprite(texture, Pose.size(), false)
	_looks_left = looks_left
	_update_flip()


func attack_range() -> int:
	return fighter.attack_range + (form.bonus_range if form else 0)


func armor() -> int:
	return fighter.armor + (form.bonus_armor if form else 0)


func counter_damage() -> int:
	return fighter.counter_damage + (form.bonus_counter if form else 0)


func dodge_chance() -> float:
	return fighter.dodge_chance + (form.bonus_dodge if form else 0.0)


func slam_damage() -> int:
	return fighter.throw_slam_damage + (form.bonus_slam if form else 0)


## Ki-Kosten einer Technik nach Upgrades (mindestens 1).
func technique_cost(technique: TechniqueData) -> int:
	return maxi(technique.ki_cost - fighter.technique_discount, 1)


## Spielt er gerade seinen Stil, bekommt die Verwandlung Ki zurueck.
func _refuel(kind: TransformationData.Refuel) -> void:
	if form and form.refuel == kind:
		gain_ki(form.refuel_amount)

func set_ki(value: int) -> void:
	ki = clampi(value, 0, max_ki)
	ki_changed.emit()


func gain_ki(amount: int) -> void:
	set_ki(ki + amount)


func can_afford(technique: TechniqueData) -> bool:
	return ki >= technique_cost(technique)


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
		slam = slam_damage()
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
		_refuel(TransformationData.Refuel.KONTER)
		return "Geblockt!  Konter! -%d" % counter_stance
	if sure_dodge or randf() < dodge_chance():
		await _dodge_from(attacker)
		_refuel(TransformationData.Refuel.AUSWEICHEN)
		return "Ausgewichen!"
	var damage: int = max(attacker.attack - armor(), 1)
	take_damage(damage)
	_refuel(TransformationData.Refuel.TREFFER)
	var text := ("Ki-Schuss! -%d" if ranged else "Autsch! -%d") % damage
	var counter := counter_damage()
	if counter > 0 and is_alive() and attacker.is_alive():
		if not ranged:
			await attack_unit(attacker, counter)
		elif form and form.counter_ranged:
			# Spiegelgeist wirft den Ki-Schuss zurueck.
			await shoot(attacker, counter)
		else:
			return text
		_refuel(TransformationData.Refuel.KONTER)
		text += "  Konter! -%d" % counter
	return text


## Spezialattacke eines Bosses trifft. Nur Haltungen helfen noch, Super-Armor zieht ab.
func take_special(attacker: Unit, amount: int) -> String:
	if counter_stance > 0:
		return "Geblockt!"
	if sure_dodge:
		await _dodge_from(attacker)
		return "Ausgewichen!"
	var damage: int = max(amount - armor(), 1)
	take_damage(damage)
	_refuel(TransformationData.Refuel.TREFFER)
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
	# Mit eigenen Posen faellt er verwandelt um, sonst verschwindet die Toenung.
	if form and not form.sprite_sheet:
		set_look(Color.WHITE, 1.0)
	form = null
	modulate = Color(0.6, 0.6, 0.6)
	super()


func _process(delta: float) -> void:
	if form:
		_aura_time += delta
		queue_redraw()


func _draw() -> void:
	if form:
		_draw_aura()
	super()
	# Aktive Haltung als Ki-Ring um die Fuesse.
	if counter_stance > 0 or sure_dodge:
		var s := Grid.TILE_SIZE
		draw_set_transform(Vector2(s / 2.0, s - 1.0), 0.0, Vector2(1.0, 0.35))
		draw_arc(Vector2.ZERO, 10.0, 0.0, TAU, 24, KI_AURA_COLOR, 1.0)
		draw_set_transform(Vector2.ZERO)


## Flackernde Aura hinter der Figur (wird vor dem Bild gezeichnet) und aufsteigende Funken.
func _draw_aura() -> void:
	var s := Grid.TILE_SIZE
	var height := sprite_height() * form.sprite_scale
	var width := sprite_width() * form.sprite_scale
	var pulse := sin(_aura_time * 8.0) * 1.5
	var middle := Vector2(s / 2.0, s - height * 0.42)
	# Mit eigenen Posen ist die Aura schon im Bild, dann nur Funken und Ring.
	for i in (0 if form.sprite_sheet else 3):
		var grow := 1.0 + i * 0.18
		var radius := Vector2(width * 0.34 + pulse, height * 0.5 + pulse) * grow
		draw_set_transform(middle, 0.0, radius / 10.0)
		draw_circle(Vector2.ZERO, 10.0, Color(form.aura_color, 0.22 - i * 0.06))
	draw_set_transform(Vector2.ZERO)
	# Funken steigen von den Fuessen bis ueber den Kopf.
	for i in 6:
		var rise := fmod(_aura_time * 22.0 + i * 9.0, height + 4.0)
		var x := s / 2.0 + sin(i * 2.3 + _aura_time * 3.0) * width * 0.38
		var alpha := 1.0 - rise / (height + 4.0)
		draw_rect(Rect2(roundf(x), roundf(s - rise), 1, 2), Color(form.aura_color.lightened(0.4), alpha))
	# Ring um die Fuesse.
	draw_set_transform(Vector2(s / 2.0, s - 1.0), 0.0, Vector2(1.0, 0.35))
	draw_arc(Vector2.ZERO, width * 0.45 + pulse, 0.0, TAU, 24, form.aura_color, 1.0)
	draw_set_transform(Vector2.ZERO)
