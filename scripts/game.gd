extends Node
## Globaler Spielzustand (Autoload "Game"): Tastenbelegung, Kaempfer-Liste,
## der laufende Run und der Wechsel zwischen den Bildschirmen.

const TITLE_SCENE := "res://scenes/title.tscn"
const SELECT_SCENE := "res://scenes/character_select.tscn"
const BATTLE_SCENE := "res://scenes/main.tscn"
const RESULT_SCENE := "res://scenes/result.tscn"

## Tastenbelegung (WASD und Pfeiltasten, Enter/Leertaste bestaetigen, Esc zurueck).
const KEYS := {
	"move_up": [KEY_W, KEY_UP],
	"move_down": [KEY_S, KEY_DOWN],
	"move_left": [KEY_A, KEY_LEFT],
	"move_right": [KEY_D, KEY_RIGHT],
	"confirm": [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE],
	"back": [KEY_ESCAPE],
	"restart": [KEY_R],
}

## Die spielbaren Kaempfer. Werte und Faehigkeiten stehen in den Daten-Dateien.
const FIGHTERS: Array[FighterData] = [
	preload("res://data/fighters/techniker.tres"),
	preload("res://data/fighters/koloss.tres"),
	preload("res://data/fighters/ki_akrobat.tres"),
]

## Index in FIGHTERS des gewaehlten Kaempfers.
var fighter_index := 0
## Ergebnis des letzten Runs (fuer den Ergebnis-Bildschirm).
var last_run_won := false
var last_run_turns := 0


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
	get_tree().change_scene_to_file(BATTLE_SCENE)


func end_run(won: bool, turns: int) -> void:
	last_run_won = won
	last_run_turns = turns
	get_tree().change_scene_to_file(RESULT_SCENE)


func _setup_input() -> void:
	for action: String in KEYS:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		for key: Key in KEYS[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			InputMap.action_add_event(action, event)
