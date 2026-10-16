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

## Platzhalter-Kaempfer. In M4 werden daraus eigene Daten-Dateien mit Spezialfaehigkeiten.
const FIGHTERS := [
	{"name": "Techniker", "max_hp": 20, "attack": 3, "color": Color("f2a541"),
		"description": "Ausgewogen. Konter und Combos."},
	{"name": "Koloss", "max_hp": 28, "attack": 2, "color": Color("5b8def"),
		"description": "Viel HP. Griffe und Wuerfe."},
	{"name": "Ki-Akrobat", "max_hp": 14, "attack": 4, "color": Color("4fd1a5"),
		"description": "Wenig HP. Ki-Strahlen auf Distanz."},
]

## Index in FIGHTERS des gewaehlten Kaempfers.
var fighter_index := 0
## Ergebnis des letzten Runs (fuer den Ergebnis-Bildschirm).
var last_run_won := false
var last_run_turns := 0


func _ready() -> void:
	_setup_input()


func fighter() -> Dictionary:
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
