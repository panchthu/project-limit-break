class_name BossIntro
extends CanvasLayer
## Auftritt vor dem Bosskampf: Portraet, Name und Spezialattacke des Bosses.
## Geht nach DURATION von selbst weiter, Enter ueberspringt.

signal closed

const DURATION := 2.6
## Erst nach dieser Zeit zaehlt Enter (sonst rutscht ein Tastendruck aus dem Kampf durch).
const SKIP_DELAY := 0.3
const FADE_TIME := 0.2

var _time := 0.0
var _open := false

@onready var root: Control = $Root
@onready var portrait: TextureRect = $Root/Portrait
@onready var name_label: Label = $Root/NameLabel
@onready var special_label: Label = $Root/SpecialLabel


func _ready() -> void:
	visible = false


func show_boss(data: EnemyData) -> void:
	portrait.texture = data.portrait
	name_label.text = data.display_name
	special_label.text = "Spezialattacke: %s" % data.special_name
	_time = 0.0
	_open = true
	visible = true
	root.modulate.a = 0.0
	create_tween().tween_property(root, "modulate:a", 1.0, FADE_TIME)


func _process(delta: float) -> void:
	if not _open:
		return
	_time += delta
	if _time >= DURATION or (_time >= SKIP_DELAY and Input.is_action_just_pressed("confirm")):
		_close()


func _close() -> void:
	_open = false
	var tween := create_tween()
	tween.tween_property(root, "modulate:a", 0.0, FADE_TIME)
	await tween.finished
	visible = false
	closed.emit()
