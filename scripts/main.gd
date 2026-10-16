extends Node2D
## Hauptszene: zeichnet den Boden, richtet die Tasten ein und steuert die Zuege.
## Ablauf: Spieler handelt (laufen oder angreifen), danach handelt jeder Gegner.
## Die Map besteht aus Runden: sind alle Gegner einer Runde besiegt, startet die naechste.

const ENEMY_SCENE := preload("res://scenes/enemy.tscn")
const BOSS_SCENE := preload("res://scenes/boss.tscn")

## Runden dieser Map: welche Gegner wo auftauchen.
const ROUNDS := [
	{"name": "Runde 1", "spawns": [
		{"scene": ENEMY_SCENE, "cell": Vector2i(14, 2)},
		{"scene": ENEMY_SCENE, "cell": Vector2i(16, 5)},
		{"scene": ENEMY_SCENE, "cell": Vector2i(13, 8)},
	]},
	{"name": "BOSS", "spawns": [
		{"scene": BOSS_SCENE, "cell": Vector2i(17, 5)},
	]},
]

## Kurze Pause nach Sieg oder Niederlage, bevor der Ergebnis-Bildschirm kommt.
const END_DELAY := 1.2

var turn := 0
var round_index := 0
## Waehrend ein Zug abgespielt wird, keine neue Eingabe.
var _busy := false
var _game_over := false

@onready var player: Unit = $Player
@onready var status_label: Label = $StatusLabel
@onready var message_label: Label = $MessageLabel


func _ready() -> void:
	_apply_fighter(Game.fighter())
	player.died.connect(_on_player_died)
	_start_round(0)


func _start_round(index: int) -> void:
	round_index = index
	var round_data: Dictionary = ROUNDS[index]
	for spawn: Dictionary in round_data.spawns:
		var enemy: Unit = spawn.scene.instantiate()
		enemy.start_cell = spawn.cell
		enemy.died.connect(_on_enemy_died)
		add_child(enemy)
	_show_message("%s!" % round_data.name)


## Werte des gewaehlten Kaempfers auf die Spielfigur uebertragen.
func _apply_fighter(fighter: Dictionary) -> void:
	player.max_hp = fighter.max_hp
	player.attack = fighter.attack
	player.body_color = fighter.color
	player.heal_full()


func _process(_delta: float) -> void:
	if _game_over or _busy:
		return
	var dir: Vector2i = player.read_direction()
	if dir != Vector2i.ZERO:
		_take_turn(dir)


func _take_turn(dir: Vector2i) -> void:
	var target := player.cell + dir
	var enemy := _unit_at(target)
	if enemy == null and not _is_free(target):
		# Gegen die Wand gelaufen: nur umdrehen, kein Zug verbraucht.
		player.face(dir)
		return
	_busy = true
	if enemy:
		await player.attack_unit(enemy)
		if enemy.is_alive():
			_show_message("Treffer! -%d" % player.attack)
	else:
		await player.move_to(target)
	await _enemy_turn()
	turn += 1
	_update_status()
	_busy = false


func _enemy_turn() -> void:
	for enemy: Unit in _enemies():
		if not player.is_alive():
			return
		var distance: Vector2i = (player.cell - enemy.cell).abs()
		if distance.x + distance.y == 1:
			await enemy.attack_unit(player)
			_show_message("Autsch! -%d" % enemy.attack)
		else:
			var step: Vector2i = enemy.next_step(player.cell, _is_free)
			if step != Vector2i.ZERO:
				await enemy.move_to(enemy.cell + step)


func _enemies() -> Array[Node]:
	return get_tree().get_nodes_in_group("enemies")


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
	if round_index + 1 < ROUNDS.size():
		# Zwischen den Runden sammelt der Kaempfer neue Kraft.
		player.heal_full()
		_start_round(round_index + 1)
	else:
		_end_game(true, "Gewonnen!")


func _on_player_died() -> void:
	_end_game(false, "Besiegt!")


func _end_game(won: bool, text: String) -> void:
	_show_message(text)
	_game_over = true
	await get_tree().create_timer(END_DELAY).timeout
	Game.end_run(won, turn)


func _update_status() -> void:
	status_label.text = "HP %d/%d  %s  Zug %d" % [player.hp, player.max_hp, ROUNDS[round_index].name, turn]


func _show_message(text: String) -> void:
	# Nach Sieg oder Niederlage bleibt die Endnachricht stehen.
	if _game_over:
		return
	message_label.text = text
	_update_status()


## Schachbrett-Boden als Platzhalter.
func _draw() -> void:
	var s := Grid.TILE_SIZE
	for y in Grid.HEIGHT:
		for x in Grid.WIDTH:
			var color := Color("2b2640") if (x + y) % 2 == 0 else Color("332d4d")
			draw_rect(Rect2(x * s, y * s, s, s), color)
