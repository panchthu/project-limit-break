extends Node2D
## Hauptszene: zeichnet den Boden, richtet die Tasten ein und steuert die Zuege.
## Ablauf: Spieler handelt (laufen, angreifen, Ki aufladen oder eine Technik), danach handelt jeder Gegner.
## Eine Aktion pro Zug. Techniken kosten Ki, Aufladen und normale Treffer bringen Ki.
## Ein Run besteht aus mehreren Maps (Game.MAPS), jede Map aus Runden (data/maps/*.tres).
## Sind alle Gegner einer Runde besiegt, startet die naechste; nach dem Boss kommt die naechste Map.
## Nach jeder Runde gibt es ein Upgrade zur Wahl (UpgradeMenu). Auf der letzten Map erwacht
## stattdessen direkt vor dem Endboss die Verwandlung des Kaempfers (Taste T bei voller Ki-Leiste).
## Figuren werden nach ihrer Zeile sortiert gezeichnet (y_sort), damit weiter unten stehende
## Figuren vor den hoeheren stehen. Zu Beginn jeder Map und vor jedem Boss kommt ein Auftritt (Intro).

const ENEMY_SCENE := preload("res://scenes/enemy.tscn")

## Tastennamen der Techniken fuer die Anzeige (passend zu Game.KEYS).
const TECHNIQUE_KEYS := ["Q", "E"]
## Farben der Leisten unten.
const HP_BAR_COLOR := Color("6cd36c")
const KI_BAR_COLOR := Color("8fe8ff")
const BAR_BG_COLOR := Color("1d1a2f")
const BAR_RECT_HP := Rect2(4, 163, 52, 4)
const BAR_RECT_KI := Rect2(4, 171, 52, 4)
## Markierte Felder einer angekuendigten Boss-Attacke.
const WARNING_COLOR := Color(1, 0.25, 0.2, 0.45)
## Feine Rasterlinien ueber dem Hintergrundbild, damit man die Felder erkennt.
const GRID_LINE_COLOR := Color(0, 0, 0, 0.15)

## Kurze Pause nach Sieg oder Niederlage, bevor der Ergebnis-Bildschirm kommt.
const END_DELAY := 1.2
## Kurze Pause nach dem letzten Treffer einer Runde, bevor die Upgrade-Auswahl kommt.
const UPGRADE_DELAY := 0.6

var turn := 0
var map: MapData
var round_index := 0
## Waehrend ein Zug abgespielt wird, keine neue Eingabe.
var _busy := false
var _game_over := false
## Zwischen zwei Maps und waehrend eines Auftritts keine Eingabe.
var _between_maps := false
var _intro := false
## Waehrend Upgrade-Auswahl oder Erwachen keine Eingabe.
var _choosing := false
## Technik, fuer die gerade eine Richtung gewaehlt wird (null = keine).
var _aiming: TechniqueData = null

@onready var player: Player = $Player
@onready var status_label: Label = $StatusLabel
@onready var message_label: Label = $MessageLabel
@onready var technique_label: Label = $TechniqueLabel
@onready var round_label: Label = $RoundLabel
@onready var intro: Intro = $Intro
@onready var upgrade_menu: UpgradeMenu = $UpgradeMenu


func _ready() -> void:
	# Wird die Szene direkt gestartet (ohne Auswahl), gibt es noch keinen Run.
	if Game.run_fighter == null:
		Game.run_fighter = Game.fighter().duplicate()
	player.setup(Game.run_fighter)
	player.died.connect(_on_player_died)
	player.ki_changed.connect(_update_status)
	_start_map(0)


func _start_map(index: int) -> void:
	Game.map_index = index
	map = Game.MAPS[index]
	_start_round(0)
	_show_message("%s - %s!" % [map.display_name, map.rounds[0].display_name])
	if map.artwork:
		_intro = true
		intro.show_map(map, index + 1)
		await intro.closed
		_intro = false


func _start_round(index: int) -> void:
	round_index = index
	var round_data: RoundData = map.rounds[index]
	var boss: EnemyData = null
	for i in round_data.enemies.size():
		var enemy: Enemy = ENEMY_SCENE.instantiate()
		enemy.setup(round_data.enemies[i], round_data.cells[i])
		enemy.died.connect(_on_enemy_died)
		add_child(enemy)
		if enemy.data.is_boss:
			boss = enemy.data
	_show_message("%s!" % round_data.display_name)
	if player.fighter.round_start_ki > 0:
		player.gain_ki(player.fighter.round_start_ki)
	if boss and boss.portrait:
		_intro = true
		intro.show_boss(boss)
		await intro.closed
		_intro = false


func _process(_delta: float) -> void:
	if _game_over or _busy or _between_maps or _intro or _choosing:
		return
	if _aiming:
		_process_aiming()
		return
	for i in player.fighter.techniques.size():
		if Input.is_action_just_pressed("technique_%d" % (i + 1)):
			_select_technique(player.fighter.techniques[i])
			return
	if Input.is_action_just_pressed("transform"):
		_try_transform()
		return
	if Input.is_action_just_pressed("charge"):
		if player.is_transformed():
			_show_message("Verwandelt: kein Aufladen!")
		elif player.ki >= player.max_ki:
			_show_message("Ki ist voll!")
		else:
			_run_turn(_charge)
		return
	var dir: Vector2i = player.read_direction()
	if dir != Vector2i.ZERO:
		_move_or_attack(dir)


## Technik-Taste gedrueckt: sofort ausfuehren oder erst eine Richtung waehlen lassen.
func _select_technique(technique: TechniqueData) -> void:
	if not player.can_afford(technique):
		_show_message("Zu wenig Ki! (%d)" % player.technique_cost(technique))
		return
	if technique.needs_direction():
		_aiming = technique
		_show_message("%s: Richtung?" % technique.display_name)
		return
	_try_technique(technique, Vector2i.ZERO)


## Waehrend gezielt wird: Richtung loest aus, gleiche Taste oder Esc bricht ab.
func _process_aiming() -> void:
	if Input.is_action_just_pressed("back") or _technique_key_just_pressed():
		_aiming = null
		_show_message("Abgebrochen")
		return
	var dir: Vector2i = player.read_direction(true)
	if dir != Vector2i.ZERO:
		var technique := _aiming
		_aiming = null
		_try_technique(technique, dir)


func _technique_key_just_pressed() -> bool:
	for i in player.fighter.techniques.size():
		if Input.is_action_just_pressed("technique_%d" % (i + 1)):
			return true
	return false


## Prueft, ob die Technik ein Ziel hat. Nur dann kostet sie Ki und den Zug.
func _try_technique(technique: TechniqueData, dir: Vector2i) -> void:
	var problem := _technique_problem(technique, dir)
	if problem != "":
		player.face(dir)
		_show_message(problem)
		return
	_run_turn(_use_technique.bind(technique, dir))


func _move_or_attack(dir: Vector2i) -> void:
	var target := player.cell + dir
	# Lichtlaeufer: der Schlag wird ein Strahl durch alle Gegner in Reichweite.
	if player.form and player.form.piercing:
		var targets := _enemies_in_line(player.cell, dir, player.attack_range())
		if not targets.is_empty():
			_run_turn(_piercing_attack.bind(dir, targets))
			return
	# Mit Reichweite > 1 (Ki-Akrobat) wird auch ein Gegner weiter weg in dieser Richtung getroffen.
	var enemy := _enemy_in_line(player.cell, dir, player.attack_range())
	if enemy == null and not _is_free(target):
		# Gegen die Wand gelaufen: nur umdrehen, kein Zug verbraucht.
		player.face(dir)
		return
	if enemy:
		_run_turn(_player_attack.bind(enemy))
	else:
		_run_turn(player.move_to.bind(target))


## Ein ganzer Zug: Aktion des Spielers, dann alle Gegner.
func _run_turn(action: Callable) -> void:
	_busy = true
	var was_transformed := player.is_transformed()
	await action.call()
	await _enemy_turn()
	player.clear_stances()
	# Der Zug, in dem er sich verwandelt, kostet noch nichts.
	if was_transformed and player.is_transformed():
		_drain_form()
	turn += 1
	_update_status()
	_busy = false


func _charge() -> void:
	await player.charge()
	_show_message("Ki aufgeladen! +%d" % player.fighter.ki_charge)


## T gedrueckt: verwandeln, wenn es geht, sonst sagen, was fehlt.
func _try_transform() -> void:
	if not Game.transformation_unlocked:
		return
	if player.is_transformed():
		_show_message("Schon verwandelt!")
	elif not player.can_transform():
		_show_message("Ki-Leiste muss voll sein!")
	else:
		_run_turn(_transform)


## Verwandeln mit Ki-Explosion: Gegner rundherum nehmen Schaden und fliegen 1 Feld weg.
func _transform() -> void:
	await player.transform()
	var form := player.form
	for enemy: Unit in _enemies_around(player.cell):
		enemy.take_damage(form.burst_damage)
		if enemy.is_alive():
			await player.throw_unit(enemy, _is_free, 1, 0, (enemy.cell - player.cell).sign())
	_show_message("%s!" % form.display_name)


## Verwandlung verbrennt Ki. Ist die Leiste leer, ist sie vorbei.
func _drain_form() -> void:
	player.gain_ki(-player.form.ki_drain)
	if player.ki <= 0:
		player.revert()
		_show_message("Die Verwandlung erlischt!")


## Lichtlaeufer: Strahl in Reichweite, jeder Gegner darin nimmt normalen Schaden.
func _piercing_attack(dir: Vector2i, targets: Array[Unit]) -> void:
	player.gain_ki(player.fighter.ki_per_hit)
	player.heal(player.fighter.heal_per_hit)
	await player.beam(dir, mini(player.attack_range(), _cells_to_wall(player.cell, dir)))
	for enemy: Unit in targets:
		enemy.take_damage(player.attack)
	_show_message("Lichtstrahl! -%d x%d" % [player.attack, targets.size()])


## Warum die Technik gerade nicht geht ("" = sie geht).
func _technique_problem(technique: TechniqueData, dir: Vector2i) -> String:
	match technique.effect:
		TechniqueData.Effect.KOMBO, TechniqueData.Effect.RIESENWURF:
			if _unit_at(player.cell + dir) == null:
				return "Kein Gegner daneben!"
		TechniqueData.Effect.KI_WELLE:
			if _enemies_in_line(player.cell, dir).is_empty():
				return "Kein Gegner in der Linie!"
		TechniqueData.Effect.STAMPFER:
			if _enemies_around(player.cell).is_empty():
				return "Kein Gegner in der Naehe!"
		TechniqueData.Effect.NACHBILD:
			if _dash_target(player.cell, dir, technique.distance) == player.cell:
				return "Kein Platz!"
	return ""


## Fuehrt eine Technik aus (Ziel wurde vorher geprueft).
func _use_technique(technique: TechniqueData, dir: Vector2i) -> void:
	player.gain_ki(-player.technique_cost(technique))
	# Upgrade "Technik-Meister" macht jede Technik staerker.
	var power := technique.power + player.fighter.technique_power
	var text := technique.display_name + "!"
	match technique.effect:
		TechniqueData.Effect.KOMBO:
			var enemy := _unit_at(player.cell + dir)
			for i in technique.hits:
				if not enemy.is_alive():
					break
				await player.attack_unit(enemy, power)
			text += " -%d x%d" % [power, technique.hits]
		TechniqueData.Effect.KONTER_HALTUNG:
			player.counter_stance = power
			player.queue_redraw()
		TechniqueData.Effect.STAMPFER:
			await player.charge_flash()
			for enemy: Unit in _enemies_around(player.cell):
				enemy.take_damage(power)
				if enemy.is_alive():
					var away := (enemy.cell - player.cell).sign()
					await player.throw_unit(enemy, _is_free, technique.distance, 0, away)
			text += " -%d" % power
		TechniqueData.Effect.RIESENWURF:
			var enemy := _unit_at(player.cell + dir)
			player.face(dir)
			await player.attack_unit(enemy, power)
			text += " -%d" % power
			if enemy.is_alive():
				var slam := await player.throw_unit(enemy, _is_free, technique.distance, technique.slam_damage, dir)
				if slam > 0:
					text += "  Aufprall! -%d" % slam
		TechniqueData.Effect.KI_WELLE:
			var targets := _enemies_in_line(player.cell, dir)
			await player.beam(dir, _cells_to_wall(player.cell, dir))
			for enemy: Unit in targets:
				enemy.take_damage(power)
			text += " -%d" % power
		TechniqueData.Effect.NACHBILD:
			await player.dash_to(_dash_target(player.cell, dir, technique.distance))
			player.sure_dodge = true
			player.queue_redraw()
	_show_message(text)


## Angriff des Spielers mit den Faehigkeiten seines Kaempfers.
func _player_attack(enemy: Unit) -> void:
	var text: String
	player.gain_ki(player.fighter.ki_per_hit)
	player.heal(player.fighter.heal_per_hit)
	if _distance(player.cell, enemy.cell) > 1:
		await player.shoot(enemy)
		text = "Ki-Strahl! -%d" % player.attack
	else:
		await player.attack_unit(enemy)
		text = "Treffer! -%d" % player.attack
	if enemy.is_alive() and player.fighter.throw_distance > 0:
		var slam := await player.throw_unit(enemy, _is_free)
		text = "Wurf! -%d" % player.attack
		if slam > 0:
			text += "  Aufprall! -%d" % slam
	# Stirbt der Gegner, bleibt "Gegner besiegt!" stehen.
	if enemy.is_alive():
		_show_message(text)


func _enemy_turn() -> void:
	for enemy: Unit in _enemies():
		if not player.is_alive():
			return
		# Ein Konter kann Gegner mitten im Gegnerzug besiegen.
		if not is_instance_valid(enemy) or not enemy.is_alive():
			continue
		var text: String = await enemy.take_turn(player, _is_free)
		if text != "":
			_show_message(text)


func _enemies() -> Array[Node]:
	return get_tree().get_nodes_in_group("enemies")


## Alle Gegner in gerader Linie bis zur Wand (oder hoechstens max_range Felder weit).
func _enemies_in_line(from: Vector2i, dir: Vector2i, max_range := Grid.WIDTH) -> Array[Unit]:
	var found: Array[Unit] = []
	if dir == Vector2i.ZERO:
		return found
	var cell := from + dir
	while Grid.is_inside(cell) and _distance(from, cell) <= max_range:
		var enemy := _unit_at(cell)
		if enemy:
			found.append(enemy)
		cell += dir
	return found


## Alle Gegner auf den 8 Feldern rundherum.
func _enemies_around(center: Vector2i) -> Array[Unit]:
	var found: Array[Unit] = []
	for enemy: Unit in _enemies():
		var diff := (enemy.cell - center).abs()
		if max(diff.x, diff.y) == 1:
			found.append(enemy)
	return found


## Wie viele Felder bis zum Rand (fuer die Laenge des Strahls).
func _cells_to_wall(from: Vector2i, dir: Vector2i) -> int:
	var count := 0
	var cell := from + dir
	while Grid.is_inside(cell):
		count += 1
		cell += dir
	return count


## Weitestes freies Feld in Richtung dir, hoechstens max_cells weit.
func _dash_target(from: Vector2i, dir: Vector2i, max_cells: int) -> Vector2i:
	var target := from
	for i in max_cells:
		if not _is_free(target + dir):
			break
		target += dir
	return target


## Erster Gegner in gerader Linie, hoechstens max_range Felder weit.
func _enemy_in_line(from: Vector2i, dir: Vector2i, max_range: int) -> Unit:
	for i in range(1, max_range + 1):
		var cell := from + dir * i
		if not Grid.is_inside(cell):
			return null
		var enemy := _unit_at(cell)
		if enemy:
			return enemy
	return null


static func _distance(a: Vector2i, b: Vector2i) -> int:
	var diff := (a - b).abs()
	return diff.x + diff.y


func _unit_at(cell: Vector2i) -> Unit:
	for enemy: Unit in _enemies():
		if enemy.cell == cell:
			return enemy
	return null


func _is_free(cell: Vector2i) -> bool:
	return Grid.is_inside(cell) and cell != player.cell and _unit_at(cell) == null


func _on_enemy_died() -> void:
	# Der sterbende Gegner hat die Gruppe schon verlassen.
	if not _enemies().is_empty():
		_show_message("Gegner besiegt!")
		return
	# Zwischen den Runden sammelt der Kaempfer neue Kraft.
	player.heal_full()
	var last_map := Game.map_index + 1 >= Game.MAPS.size()
	if last_map and round_index + 1 >= map.rounds.size():
		_end_game(true, "Gewonnen!")
		return
	_choosing = true
	_show_message("Runde geschafft!")
	await get_tree().create_timer(UPGRADE_DELAY).timeout
	# Letzte Map, als Naechstes kommt der Endboss: die Verwandlung erwacht statt eines Upgrades.
	if last_map and round_index + 2 == map.rounds.size() and player.fighter.transformation:
		await _awaken()
	else:
		await _pick_upgrade()
	_choosing = false
	if round_index + 1 < map.rounds.size():
		_start_round(round_index + 1)
	else:
		_start_next_map()


func _pick_upgrade() -> void:
	var choices := Game.roll_upgrades()
	if choices.is_empty():
		return
	var upgrade := await upgrade_menu.choose(choices, player.fighter)
	Game.take_upgrade(upgrade)
	player.refresh_stats()
	player.heal_full()
	_show_message("%s!" % upgrade.display_name)


func _awaken() -> void:
	Game.transformation_unlocked = true
	await upgrade_menu.awaken(player.fighter)
	player.set_ki(player.max_ki)
	_show_message("T = %s!" % player.fighter.transformation.display_name)


## Map geschafft: kurz durchatmen, Spieler zurueck an den Start, naechste Map.
func _start_next_map() -> void:
	_between_maps = true
	_show_message("Map geschafft!")
	await get_tree().create_timer(END_DELAY).timeout
	player.face(Vector2i.DOWN)
	await player.slide_to(player.start_cell, 0.2)
	_start_map(Game.map_index + 1)
	_between_maps = false


func _on_player_died() -> void:
	_end_game(false, "Besiegt!")


func _end_game(won: bool, text: String) -> void:
	_show_message(text)
	_game_over = true
	await get_tree().create_timer(END_DELAY).timeout
	Game.end_run(won, turn)


func _update_status() -> void:
	status_label.text = "HP %d/%d  Ki %d/%d" % [player.hp, player.max_hp, player.ki, player.max_ki]
	round_label.text = "M%d %s  Zug %d" % [Game.map_index + 1, map.rounds[round_index].display_name, turn]
	var parts: PackedStringArray = []
	for i in player.fighter.techniques.size():
		var technique: TechniqueData = player.fighter.techniques[i]
		parts.append("%s %s %d" % [TECHNIQUE_KEYS[i], technique.label(), player.technique_cost(technique)])
	if not player.is_transformed():
		parts.append("F Laden")
	if Game.transformation_unlocked and player.fighter.transformation:
		parts.append("T %s" % player.fighter.transformation.label())
	technique_label.text = "  ".join(parts)
	queue_redraw()


func _show_message(text: String) -> void:
	# Nach Sieg oder Niederlage bleibt die Endnachricht stehen.
	if _game_over:
		return
	message_label.text = text
	_update_status()


## Boden: Hintergrundbild der Map mit feinem Raster, sonst Schachbrett. Dazu die Warnfelder der Bosse.
func _draw() -> void:
	var s := Grid.TILE_SIZE
	if map.background:
		draw_texture_rect(map.background, Rect2(0, 0, Grid.WIDTH * s, Grid.HEIGHT * s), false)
		for x in range(1, Grid.WIDTH):
			draw_line(Vector2(x * s, 0), Vector2(x * s, Grid.HEIGHT * s), GRID_LINE_COLOR, 1.0)
		for y in range(1, Grid.HEIGHT):
			draw_line(Vector2(0, y * s), Vector2(Grid.WIDTH * s, y * s), GRID_LINE_COLOR, 1.0)
	else:
		for y in Grid.HEIGHT:
			for x in Grid.WIDTH:
				var color := map.floor_color_a if (x + y) % 2 == 0 else map.floor_color_b
				draw_rect(Rect2(x * s, y * s, s, s), color)
	for enemy: Enemy in _enemies():
		for cell in enemy.warned_cells:
			draw_rect(Rect2(cell * s, Vector2(s, s)), WARNING_COLOR)
	_draw_bar(BAR_RECT_HP, player.hp, player.max_hp, HP_BAR_COLOR, 0)
	var ki_color := player.form.aura_color if player.form else KI_BAR_COLOR
	_draw_bar(BAR_RECT_KI, player.ki, player.max_ki, ki_color, player.max_ki)


## Leiste unten. Mit segments > 0 wird sie in einzelne Ki-Punkte geteilt.
func _draw_bar(rect: Rect2, value: int, max_value: int, color: Color, segments: int) -> void:
	draw_rect(rect, BAR_BG_COLOR)
	var filled := rect
	filled.size.x = round(rect.size.x * float(value) / max(max_value, 1))
	draw_rect(filled, color)
	for i in range(1, segments):
		var x: float = rect.position.x + round(rect.size.x * float(i) / segments)
		draw_line(Vector2(x, rect.position.y), Vector2(x, rect.end.y), BAR_BG_COLOR, 1.0)
