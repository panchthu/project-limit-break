class_name Enemy
extends Unit
## Gegner. Wie er sich verhaelt, steht in seinen Daten (EnemyData.behavior).
## Bosse holen ausserdem regelmaessig zu einer Spezialattacke aus:
## erst werden die Felder markiert, im naechsten Gegnerzug schlaegt sie ein.

var data: EnemyData
var armor := 0
## TANK: ruht jeden zweiten Zug.
var _resting := false
## FERNKAMPF: ist im letzten Zug zurueckgewichen (zweimal hintereinander geht nicht).
var _retreated := false
## Zuege seit der letzten Spezialattacke.
var _special_counter := 0
## Felder, auf die die angekuendigte Spezialattacke einschlaegt (leer = keine Warnung).
var warned_cells: Array[Vector2i] = []


func _ready() -> void:
	super()
	add_to_group("enemies")


## Werte aus der Daten-Datei uebernehmen (vor add_child aufrufen).
func setup(enemy_data: EnemyData, at: Vector2i) -> void:
	data = enemy_data
	start_cell = at
	max_hp = data.max_hp
	attack = data.attack
	armor = data.armor
	body_color = data.color
	outlined = data.is_boss
	set_sprite(data.sprite, 1, true)


func take_damage(amount: int) -> void:
	super(max(amount - armor, 1))


## Ein ganzer Gegnerzug. Gibt den Text fuer die Meldungszeile zurueck ("" = nichts zu melden).
## is_free(cell) sagt, ob ein Feld frei ist.
func take_turn(player: Player, is_free: Callable) -> String:
	if data.special_pattern != EnemyData.Pattern.KEINER:
		if not warned_cells.is_empty():
			return await _unleash_special(player)
		_special_counter += 1
		if _special_counter >= data.special_every:
			_special_counter = 0
			_prepare_special(player)
			return "%s holt aus: %s!" % [data.display_name, data.special_name]
	match data.behavior:
		EnemyData.Behavior.FERNKAMPF:
			return await _ranged_turn(player, is_free)
		EnemyData.Behavior.TANK:
			_resting = not _resting
			if _distance_to(player.cell) == 1:
				return await player.defend(self)
			if not _resting:
				await _walk_towards(player.cell, is_free, 1)
			return ""
		_:
			if _distance_to(player.cell) == 1:
				return await player.defend(self)
			# Nach dem Laufen schlaegt auch der Schnelle erst im naechsten Zug zu.
			await _walk_towards(player.cell, is_free, data.steps)
			return ""


## Fernkaempfer: schiesst, wenn der Spieler frei in der Linie steht. Sonst Abstand halten
## oder sich in eine Schusslinie stellen. Zurueckweichen klappt nur jeden zweiten Zug,
## sonst koennten Nahkaempfer ihn nie erwischen.
func _ranged_turn(player: Player, is_free: Callable) -> String:
	var retreated := _retreated
	_retreated = false
	if _distance_to(player.cell) == 1:
		var away := Vector2i.ZERO if retreated else _step_away_from(player.cell, is_free)
		if away == Vector2i.ZERO:
			return await player.defend(self)
		_retreated = true
		await move_to(cell + away)
		return ""
	if _has_clear_shot(player.cell, is_free):
		return await player.defend(self, true)
	# Ein Nachbarfeld suchen, von dem aus er schiessen koennte.
	for dir: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		var spot := cell + dir
		if is_free.call(spot) and _clear_shot_from(spot, player.cell, is_free) and _manhattan(spot, player.cell) > 1:
			await move_to(spot)
			return ""
	await _walk_towards(player.cell, is_free, 1)
	return ""


## Spezialattacke ankuendigen: Felder merken, die im naechsten Gegnerzug getroffen werden.
func _prepare_special(player: Player) -> void:
	warned_cells.clear()
	for y in Grid.HEIGHT:
		for x in Grid.WIDTH:
			var target := Vector2i(x, y)
			if _special_hits(target, player.cell):
				warned_cells.append(target)
	# Warnfarbe: Boss leuchtet auf.
	modulate = Color(1.6, 1.3, 0.6)
	create_tween().tween_property(self, "modulate", Color.WHITE, 0.4)


func _special_hits(target: Vector2i, player_cell: Vector2i) -> bool:
	match data.special_pattern:
		EnemyData.Pattern.UMKREIS:
			var diff := (target - cell).abs()
			return target != cell and max(diff.x, diff.y) <= data.special_size
		EnemyData.Pattern.KREUZ:
			return target != cell and (target.x == cell.x or target.y == cell.y)
		EnemyData.Pattern.SCHACHBRETT:
			return target != cell and (target.x + target.y) % 2 == (player_cell.x + player_cell.y) % 2
	return false


## Die angekuendigte Attacke schlaegt ein. Steht der Spieler noch drin, wird er getroffen.
func _unleash_special(player: Player) -> String:
	var hit := player.cell in warned_cells
	warned_cells.clear()
	await lunge_at(player)
	if not hit:
		return "%s verfehlt!" % data.special_name
	return await player.take_special(self, data.special_damage)


## Bis zu max_steps Schritte Richtung Ziel, stoppt neben dem Ziel.
func _walk_towards(target: Vector2i, is_free: Callable, max_steps: int) -> void:
	for i in max_steps:
		if _distance_to(target) <= 1:
			break
		var step := next_step(target, is_free)
		if step == Vector2i.ZERO:
			break
		await move_to(cell + step)


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


## Ein Schritt, der weiter weg vom Ziel fuehrt (ZERO = keiner moeglich).
func _step_away_from(target: Vector2i, is_free: Callable) -> Vector2i:
	for dir: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		if is_free.call(cell + dir) and _manhattan(cell + dir, target) > _distance_to(target):
			return dir
	return Vector2i.ZERO


func _has_clear_shot(target: Vector2i, is_free: Callable) -> bool:
	return _clear_shot_from(cell, target, is_free)


## Steht target in gerader Linie hoechstens attack_range weit, ohne etwas dazwischen?
func _clear_shot_from(from: Vector2i, target: Vector2i, is_free: Callable) -> bool:
	if from.x != target.x and from.y != target.y:
		return false
	var distance := _manhattan(from, target)
	if distance > data.attack_range:
		return false
	var dir := (target - from).sign()
	for i in range(1, distance):
		var between := from + dir * i
		if between != cell and not is_free.call(between):
			return false
	return true


func _distance_to(target: Vector2i) -> int:
	return _manhattan(cell, target)


static func _manhattan(a: Vector2i, b: Vector2i) -> int:
	var diff := (a - b).abs()
	return diff.x + diff.y


func _die() -> void:
	# Sofort aus der Gruppe, damit der Gegner nicht mehr mitspielt.
	remove_from_group("enemies")
	warned_cells.clear()
	super()
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.finished.connect(queue_free)
