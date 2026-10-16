extends Node2D
## Hauptszene: zeichnet den Boden, richtet die Tasten ein und zaehlt die Zuege.

## Tastenbelegung (WASD und Pfeiltasten).
const KEYS := {
	"move_up": [KEY_W, KEY_UP],
	"move_down": [KEY_S, KEY_DOWN],
	"move_left": [KEY_A, KEY_LEFT],
	"move_right": [KEY_D, KEY_RIGHT],
}

var turn := 0

@onready var player := $Player
@onready var turn_label: Label = $TurnLabel


func _ready() -> void:
	_setup_input()
	player.moved.connect(_on_player_moved)
	_update_label()


func _setup_input() -> void:
	for action: String in KEYS:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		for key: Key in KEYS[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			InputMap.action_add_event(action, event)


func _on_player_moved(_cell: Vector2i) -> void:
	turn += 1
	_update_label()


func _update_label() -> void:
	turn_label.text = "Zug %d" % turn


## Schachbrett-Boden als Platzhalter.
func _draw() -> void:
	var s := Grid.TILE_SIZE
	for y in Grid.HEIGHT:
		for x in Grid.WIDTH:
			var color := Color("2b2640") if (x + y) % 2 == 0 else Color("332d4d")
			draw_rect(Rect2(x * s, y * s, s, s), color)
