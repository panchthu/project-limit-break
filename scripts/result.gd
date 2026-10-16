extends Control
## Ergebnis nach dem Run: Sieg oder Game Over, links das Artwork des Kaempfers.
## Enter = zurueck zum Titel, R = gleicher Kaempfer nochmal.

@onready var headline_label: Label = $HeadlineLabel
@onready var info_label: Label = $InfoLabel
@onready var artwork: TextureRect = $Artwork


func _ready() -> void:
	artwork.texture = Game.fighter().artwork
	if Game.last_run_won:
		headline_label.text = "SIEG!"
		headline_label.modulate = Color("ffe08a")
	else:
		headline_label.text = "GAME OVER"
		headline_label.modulate = Color("d94d6b")
		# Bei einer Niederlage steht der Kaempfer im Schatten.
		artwork.modulate = Color(0.45, 0.4, 0.55)
	var lines := "%s\nMap %d/%d  -  %d Zuege\n%d Upgrades" % [
		Game.fighter().display_name, Game.map_index + 1, Game.MAPS.size(), Game.last_run_turns,
		Game.run_upgrades.size()]
	if Game.transformed_once:
		var form := Game.fighter().transformation
		if form.artwork:
			artwork.texture = form.artwork
		lines += "  -  %s" % Game.fighter().transformation.display_name
	info_label.text = lines


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("confirm"):
		Game.goto_title()
	elif Input.is_action_just_pressed("restart"):
		Game.start_run(Game.fighter_index)
