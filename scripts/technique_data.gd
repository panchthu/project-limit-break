class_name TechniqueData
extends Resource
## Eine Ki-Technik als Daten-Datei (siehe data/techniques/*.tres).
## Was sie macht, entscheidet "effect"; die Zahlen darunter stellen sie ein.
## Welche Zahl bei welchem Effekt zaehlt, steht beim jeweiligen Effekt.

enum Effect {
	## Mehrere Schlaege auf einen Gegner direkt daneben (power Schaden, hits Mal).
	KOMBO,
	## Haltung fuer den naechsten Gegnerzug: kein Schaden, jeder Angreifer kassiert power.
	KONTER_HALTUNG,
	## Trifft alle Gegner rundherum (power) und schiebt sie distance Felder weg.
	STAMPFER,
	## Packt einen Gegner daneben (power) und wirft ihn distance Felder, Aufprall slam_damage.
	RIESENWURF,
	## Strahl in einer Richtung bis zur Wand, trifft jeden Gegner darin (power).
	KI_WELLE,
	## Sprung bis distance Felder weit, danach sicheres Ausweichen im naechsten Gegnerzug.
	NACHBILD,
}

@export var display_name := "Technik"
## Kurzer Name fuer die Leiste im Kampf (wenig Platz).
@export var short_name := ""
## Kurze Erklaerung fuer die Kaempfer-Auswahl.
@export var description := ""
@export var ki_cost := 3
@export var effect := Effect.KOMBO
@export var power := 0
@export var hits := 1
@export var distance := 0
@export var slam_damage := 0


## Muss der Spieler nach dem Tastendruck noch eine Richtung waehlen?
func needs_direction() -> bool:
	return effect in [Effect.KOMBO, Effect.RIESENWURF, Effect.KI_WELLE, Effect.NACHBILD]


func label() -> String:
	return short_name if short_name != "" else display_name
