extends Node
## Globaler Spielzustand (Autoload "Game"): Tastenbelegung, Kaempfer- und Map-Liste,
## der laufende Run und der Wechsel zwischen den Bildschirmen.

const TITLE_SCENE := "res://scenes/title.tscn"
const SELECT_SCENE := "res://scenes/character_select.tscn"
const BATTLE_SCENE := "res://scenes/main.tscn"
const RESULT_SCENE := "res://scenes/result.tscn"

## Tastenbelegung (WASD und Pfeiltasten, Enter/Leertaste bestaetigen, Esc zurueck,
## Q/E Techniken, F Ki aufladen, T verwandeln).
const KEYS := {
	"move_up": [KEY_W, KEY_UP],
	"move_down": [KEY_S, KEY_DOWN],
	"move_left": [KEY_A, KEY_LEFT],
	"move_right": [KEY_D, KEY_RIGHT],
	"confirm": [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE],
	"back": [KEY_ESCAPE],
	"restart": [KEY_R],
	"technique_1": [KEY_Q],
	"technique_2": [KEY_E],
	"charge": [KEY_F],
	"transform": [KEY_T],
}

## Die spielbaren Kaempfer. Werte und Faehigkeiten stehen in den Daten-Dateien.
const FIGHTERS: Array[FighterData] = [
	preload("res://data/fighters/techniker.tres"),
	preload("res://data/fighters/koloss.tres"),
	preload("res://data/fighters/ki_akrobat.tres"),
]

## Die Maps eines Runs, in dieser Reihenfolge. Runden und Gegner stehen in den Daten-Dateien.
const MAPS: Array[MapData] = [
	preload("res://data/maps/map_1_bambustal.tres"),
	preload("res://data/maps/map_2_wuestenruine.tres"),
	preload("res://data/maps/map_3_himmelsturm.tres"),
]

## Alle Upgrades, die zwischen den Runden auftauchen koennen.
const UPGRADES: Array[UpgradeData] = [
	preload("res://data/upgrades/zaeher_koerper.tres"),
	preload("res://data/upgrades/harte_faust.tres"),
	preload("res://data/upgrades/tiefe_atmung.tres"),
	preload("res://data/upgrades/kampfrausch.tres"),
	preload("res://data/upgrades/ki_speicher.tres"),
	preload("res://data/upgrades/ki_fokus.tres"),
	preload("res://data/upgrades/technik_meister.tres"),
	preload("res://data/upgrades/eiserne_haut.tres"),
	preload("res://data/upgrades/vorbereitung.tres"),
	preload("res://data/upgrades/lebensfunke.tres"),
	preload("res://data/upgrades/reflexe.tres"),
	preload("res://data/upgrades/scharfer_konter.tres"),
	preload("res://data/upgrades/weitwurf.tres"),
	preload("res://data/upgrades/weitsicht.tres"),
]
## So viele Upgrades stehen nach jeder Runde zur Wahl.
const UPGRADE_CHOICES := 3

## Index in FIGHTERS des gewaehlten Kaempfers.
var fighter_index := 0
## Index in MAPS der aktuellen Map.
var map_index := 0
## Ergebnis des letzten Runs (fuer den Ergebnis-Bildschirm).
var last_run_won := false
var last_run_turns := 0
## Kopie des gewaehlten Kaempfers fuer diesen Run. Upgrades aendern nur diese Kopie.
var run_fighter: FighterData
## Genommene Upgrades in diesem Run (in Reihenfolge).
var run_upgrades: Array[UpgradeData] = []
## Ist die Verwandlung in diesem Run schon erwacht?
var transformation_unlocked := false
## Hat sich der Kaempfer in diesem Run mindestens einmal verwandelt?
var transformed_once := false


func _ready() -> void:
	_setup_input()


func fighter() -> FighterData:
	return FIGHTERS[fighter_index]


func goto_title() -> void:
	get_tree().change_scene_to_file(TITLE_SCENE)


func goto_select() -> void:
	get_tree().change_scene_to_file(SELECT_SCENE)


func start_run(index: int) -> void:
	fighter_index = index
	map_index = 0
	run_fighter = fighter().duplicate()
	run_upgrades.clear()
	transformation_unlocked = false
	transformed_once = false
	get_tree().change_scene_to_file(BATTLE_SCENE)


func end_run(won: bool, turns: int) -> void:
	last_run_won = won
	last_run_turns = turns
	get_tree().change_scene_to_file(RESULT_SCENE)


## Bis zu count verschiedene Upgrades zufaellig ziehen (seltene seltener).
## Upgrades fuer andere Kaempfer und solche, die schon oft genug genommen wurden, fallen raus.
func roll_upgrades(count := UPGRADE_CHOICES) -> Array[UpgradeData]:
	var pool: Array[UpgradeData] = []
	for upgrade in UPGRADES:
		if upgrade.fighter and upgrade.fighter != fighter():
			continue
		if upgrade.max_picks > 0 and run_upgrades.count(upgrade) >= upgrade.max_picks:
			continue
		pool.append(upgrade)
	var picked: Array[UpgradeData] = []
	while picked.size() < count and not pool.is_empty():
		var total := 0
		for upgrade in pool:
			total += upgrade.weight
		var roll := randi_range(1, total)
		for upgrade in pool:
			roll -= upgrade.weight
			if roll <= 0:
				picked.append(upgrade)
				pool.erase(upgrade)
				break
	return picked


func take_upgrade(upgrade: UpgradeData) -> void:
	upgrade.apply_to(run_fighter)
	run_upgrades.append(upgrade)


func _setup_input() -> void:
	for action: String in KEYS:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		for key: Key in KEYS[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			InputMap.action_add_event(action, event)
