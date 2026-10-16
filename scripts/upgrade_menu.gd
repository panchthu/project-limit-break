class_name UpgradeMenu
extends CanvasLayer
## Auswahl zwischen den Runden, ueber dem Kampf eingeblendet.
## choose(): 3 Upgrade-Karten, links/rechts waehlen, Enter nimmt das Upgrade.
## awaken(): die Verwandlung des Kaempfers erwacht (vor dem Endboss), Enter geht weiter.
## Die Knoten werden im Code gebaut, die Szene ist nur ein leerer CanvasLayer.

signal _confirmed

const CARD_SIZE := Vector2(92, 104)
const CARD_TOP := 28.0
const BACKGROUND := Color(0.063, 0.047, 0.11, 0.92)
const CARD_COLOR := Color("1d1a2f")
const GOLD := Color("ffe08a")
const MUTED := Color(0.6, 0.57, 0.75)
## Erst nach dieser Zeit zaehlen Tasten (sonst rutscht ein Tastendruck aus dem Kampf durch).
const INPUT_DELAY := 0.4
const FADE_TIME := 0.2

var _root: Control
var _cards: Array[Panel] = []
var _choices: Array[UpgradeData] = []
var _selected := 0
var _open := false
var _time := 0.0
## Fuer den Erwachen-Bildschirm: Farbe der Aura hinter dem Artwork (transparent = keine).
var _aura_color := Color.TRANSPARENT
var _artwork_rect := Rect2()


func _ready() -> void:
	layer = 2
	visible = false


## Zeigt die Karten und wartet, bis eins genommen wird.
func choose(choices: Array[UpgradeData], fighter: FighterData) -> UpgradeData:
	_build()
	_choices = choices
	_selected = 0
	_add_label("UPGRADE WAEHLEN", Rect2(0, 6, 320, 16), 12, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	var total_width := choices.size() * CARD_SIZE.x + (choices.size() - 1) * 11.0
	var left := roundf((320.0 - total_width) / 2.0)
	for i in choices.size():
		_cards.append(_build_card(choices[i], Vector2(left + i * (CARD_SIZE.x + 11.0), CARD_TOP)))
	_add_label("HP %d   Angriff %d   Ki %d   Ruestung %d" % [fighter.max_hp, fighter.attack, fighter.max_ki, fighter.armor],
		Rect2(0, 140, 320, 12), 8, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	_add_label("Links/Rechts waehlen   Enter nehmen", Rect2(0, 158, 320, 12), 8, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	_refresh_cards()
	await _show_and_wait()
	return _choices[_selected]


## Die Verwandlung erwacht: Artwork mit Aura, Name und Erklaerung.
func awaken(fighter: FighterData) -> void:
	_build()
	var form := fighter.transformation
	_aura_color = form.aura_color
	_artwork_rect = Rect2(24, 14, 96, 128)
	var picture := TextureRect.new()
	picture.texture = form.artwork if form.artwork else fighter.artwork
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	picture.position = _artwork_rect.position
	picture.size = _artwork_rect.size
	if not form.artwork:
		picture.modulate = form.aura_color.lerp(Color.WHITE, 0.5)
	_root.add_child(picture)
	_add_label("ERWACHEN!", Rect2(132, 14, 180, 20), 16, GOLD)
	_add_label(form.display_name, Rect2(132, 36, 180, 16), 12, form.aura_color)
	_add_label(form.description, Rect2(132, 56, 180, 40), 8, Color.WHITE)
	_add_label("T bei voller Ki-Leiste: verwandeln.\nKostet %d Ki pro Zug, Aufladen geht dann nicht.\nBei 0 Ki ist es vorbei." % form.ki_drain,
		Rect2(132, 104, 180, 34), 8, MUTED)
	_add_label("Deine Ki-Leiste ist voll. Enter = zum Endboss", Rect2(0, 158, 320, 12), 8, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	await _show_and_wait()


func _process(delta: float) -> void:
	if not _open:
		return
	_time += delta
	if _aura_color.a > 0.0:
		_root.queue_redraw()
	if _time < INPUT_DELAY:
		return
	if not _cards.is_empty():
		if Input.is_action_just_pressed("move_left"):
			_selected = wrapi(_selected - 1, 0, _cards.size())
			_refresh_cards()
		elif Input.is_action_just_pressed("move_right"):
			_selected = wrapi(_selected + 1, 0, _cards.size())
			_refresh_cards()
	if Input.is_action_just_pressed("confirm"):
		_open = false
		_confirmed.emit()


func _show_and_wait() -> void:
	_time = 0.0
	_open = true
	visible = true
	_root.modulate.a = 0.0
	create_tween().tween_property(_root, "modulate:a", 1.0, FADE_TIME)
	await _confirmed
	var tween := create_tween()
	tween.tween_property(_root, "modulate:a", 0.0, FADE_TIME)
	await tween.finished
	visible = false
	_root.queue_free()
	_root = null


## Leere Flaeche (der dunkle Hintergrund kommt aus _draw_root).
func _build() -> void:
	_cards.clear()
	_aura_color = Color.TRANSPARENT
	_root = Control.new()
	_root.size = Vector2(320, 180)
	_root.draw.connect(_draw_root)
	add_child(_root)


func _build_card(upgrade: UpgradeData, at: Vector2) -> Panel:
	var card := Panel.new()
	card.position = at
	card.size = CARD_SIZE
	_root.add_child(card)
	_add_label(upgrade.display_name, Rect2(4, 6, CARD_SIZE.x - 8, 24), 8, upgrade.color, HORIZONTAL_ALIGNMENT_CENTER, card)
	_add_label(upgrade.description, Rect2(5, 32, CARD_SIZE.x - 10, 50), 8, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, card)
	var taken := Game.run_upgrades.count(upgrade)
	var footer := ""
	if upgrade.fighter:
		footer = "Nur " + upgrade.fighter.display_name
	elif upgrade.weight <= 1:
		footer = "Selten"
	if taken > 0:
		footer = "Schon %dx" % taken if footer == "" else footer + "  %dx" % taken
	_add_label(footer, Rect2(4, CARD_SIZE.y - 16, CARD_SIZE.x - 8, 12), 8, MUTED, HORIZONTAL_ALIGNMENT_CENTER, card)
	return card


## Rahmen: gewaehlte Karte hell und dick, die anderen gedimmt.
func _refresh_cards() -> void:
	for i in _cards.size():
		var chosen := i == _selected
		var style := StyleBoxFlat.new()
		style.bg_color = CARD_COLOR.lightened(0.08) if chosen else CARD_COLOR
		style.border_color = _choices[i].color if chosen else _choices[i].color.darkened(0.55)
		style.set_border_width_all(2 if chosen else 1)
		_cards[i].add_theme_stylebox_override("panel", style)
		_cards[i].modulate = Color.WHITE if chosen else Color(0.7, 0.7, 0.8)
		_cards[i].position.y = CARD_TOP - (3.0 if chosen else 0.0)


func _add_label(text: String, rect: Rect2, font_size: int, color: Color,
		align := HORIZONTAL_ALIGNMENT_LEFT, parent: Control = null) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = align
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	# Feste Breite, damit lange Texte umbrechen statt ueber den Rand zu laufen.
	label.custom_minimum_size.x = rect.size.x
	(parent if parent else _root).add_child(label)
	label.position = rect.position
	label.size = rect.size
	return label


## Dunkler Hintergrund, beim Erwachen dazu eine pulsierende Aura hinter dem Artwork.
func _draw_root() -> void:
	_root.draw_rect(Rect2(Vector2.ZERO, _root.size), BACKGROUND)
	if _aura_color.a <= 0.0:
		return
	var center := _artwork_rect.get_center()
	var pulse := sin(_time * 5.0) * 3.0
	for i in 4:
		var radius := Vector2(46 + pulse + i * 7, 64 + pulse + i * 7)
		_root.draw_set_transform(center, 0.0, radius / 10.0)
		_root.draw_circle(Vector2.ZERO, 10.0, Color(_aura_color, 0.2 - i * 0.04))
	_root.draw_set_transform(Vector2.ZERO)
