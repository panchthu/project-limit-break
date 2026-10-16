class_name TransformationData
extends Resource
## Eine Verwandlung als Daten-Datei (siehe data/transformations/*.tres).
## Jeder Kaempfer hat genau eine. Sie erwacht auf der letzten Map direkt vor dem Endboss.
##
## Regeln fuer alle Verwandlungen:
## - Aktivieren (Taste T) geht nur mit voller Ki-Leiste und kostet den Zug.
##   Beim Verwandeln gibt es eine Ki-Explosion: burst_damage an alle Gegner rundherum, die fliegen 1 Feld weg.
## - Waehrend der Verwandlung verbrennt jeder Zug ki_drain Ki, und Aufladen (F) geht nicht.
## - Ki kommt nur zurueck, wenn man den Stil des Kaempfers spielt ("refuel"):
##   wer seinen Stil spielt, bleibt laenger verwandelt.
## - Bei 0 Ki endet die Verwandlung. Mit voller Leiste kann man wieder verwandeln.

enum Refuel {
	## Jeder Konter bringt Ki (Techniker).
	KONTER,
	## Jeder eingesteckte Treffer bringt Ki (Koloss).
	TREFFER,
	## Jedes Ausweichen bringt Ki (Ki-Akrobat).
	AUSWEICHEN,
}

@export var display_name := "Verwandlung"
## Kurzer Name fuer die Leiste im Kampf.
@export var short_name := ""
## Erklaerung fuer den Erwachen-Bildschirm (2 bis 3 kurze Zeilen).
@export var description := ""
## Farbe von Aura, Funken und Ki-Leiste.
@export var aura_color := Color("ffe08a")
## Eigene Posen der verwandelten Figur (wie FighterData.sprite_sheet). Ohne Bild wird das
## normale Sprite in Aura-Farbe getoent.
@export var sprite_sheet: Texture2D
## Grosses Bild fuer den Erwachen-Bildschirm und das Ergebnis (120 x 160).
@export var artwork: Texture2D
## Die Figur wird so viel groesser.
@export var sprite_scale := 1.0

@export_group("Werte waehrend der Verwandlung")
@export var bonus_attack := 0
@export var bonus_armor := 0
@export var bonus_counter := 0
@export var bonus_range := 0
@export_range(0.0, 1.0, 0.05) var bonus_dodge := 0.0
@export var bonus_slam := 0
## Konter wirkt auch gegen Ki-Schuesse (der Schuss wird zurueckgeworfen).
@export var counter_ranged := false
## Normale Angriffe werden ein Strahl, der jeden Gegner in der Linie trifft.
@export var piercing := false

@export_group("Ki")
## Ki-Verbrauch pro Zug.
@export var ki_drain := 2
@export var refuel := Refuel.KONTER
## So viel Ki bringt jedes Mal, wenn man den Stil spielt.
@export var refuel_amount := 2
## Schaden der Ki-Explosion beim Verwandeln.
@export var burst_damage := 2


func label() -> String:
	return short_name if short_name != "" else display_name
