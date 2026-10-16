class_name Intro
extends CanvasLayer
## Kurzer Auftritt mit grossem Bild: zu Beginn jeder Map und vor jedem Bosskampf.
## Geht nach DURATION von selbst weiter, Enter ueberspringt.

signal closed

const DURATION := 2.6
## Erst nach dieser Zeit zaehlt Enter (sonst rutscht ein Tastendruck aus dem Kampf durch).
const SKIP_DELAY := 0.3
const FADE_TIME := 0.2

var _time := 0.0
var _open := false

@onready var root: Control = $Root
@onready var picture: TextureRect = $Root/Picture
@onready var tag_label: Label = $Root/TagLabel
@onready var name_label: Label = $Root/NameLabel
@onready var info_label: Label = $Root/InfoLabel


func _ready() -> void:
	visible = false


func show_boss(data: EnemyData) -> void:
	_show(data.portrait, "BOSS", Color("d94d6b"), data.display_name, "Spezialattacke: %s" % data.special_name)


func show_map(map: MapData, number: int) -> void:
	_show(map.artwork, "MAP %d" % number, Color("8fe8ff"), map.display_name,
		"%d Runden, dann der Boss" % (map.rounds.size() - 1))


## tag steht klein oben links im Bild, darunter Name und eine Zeile Info.
func _show(texture: Texture2D, tag: String, tag_color: Color, title: String, info: String) -> void:
	picture.texture = texture
	tag_label.text = tag
	tag_label.add_theme_color_override("font_color", tag_color)
	name_label.text = title
	info_label.text = info
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
