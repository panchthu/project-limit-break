class_name EnemyData
extends Resource
## Ein Gegnertyp als Daten-Datei (siehe data/enemies/*.tres).
## "behavior" entscheidet, wie er sich im Gegnerzug verhaelt.
## Bosse haben zusaetzlich eine Spezialattacke, die einen Zug vorher angezeigt wird.

enum Behavior {
	## Laeuft auf den Spieler zu und schlaegt zu, wenn er daneben steht.
	NAHKAMPF,
	## Schiesst Ki in gerader Linie (bis attack_range Felder), haelt Abstand.
	FERNKAMPF,
	## Wie Nahkampf, laeuft aber nur jeden zweiten Zug. Dafuer Ruestung.
	TANK,
	## Wie Nahkampf, aber steps Schritte pro Zug.
	SCHNELL,
}

## Felder, die die Spezialattacke eines Bosses trifft.
enum Pattern {
	## Kein Spezialangriff.
	KEINER,
	## Alle Felder bis special_size rund um den Boss.
	UMKREIS,
	## Ganze Zeile und Spalte des Bosses.
	KREUZ,
	## Jedes zweite Feld wie ein Schachbrett, und zwar das, auf dem der Spieler gerade steht.
	SCHACHBRETT,
}

@export var display_name := "Gegner"
@export var max_hp := 6
@export var attack := 2
## Akzentfarbe (Ersatz, falls kein Sprite da ist).
@export var color := Color.WHITE
## Eine Pose, der Gegner schaut im Bild nach links.
@export var sprite: Texture2D
@export var behavior := Behavior.NAHKAMPF
## Reichweite des Ki-Schusses (nur FERNKAMPF).
@export var attack_range := 1
## Schritte pro Zug (SCHNELL laeuft mehr als einen).
@export var steps := 1
## So viel weniger Schaden pro Treffer (mindestens 1 kommt immer durch).
@export var armor := 0

@export_group("Boss")
## Bosse bekommen einen goldenen Schatten und einen Auftritt vor dem Kampf.
@export var is_boss := false
## Breites Bild fuer den Boss-Auftritt (256 x 144).
@export var portrait: Texture2D
@export var special_name := ""
@export var special_pattern := Pattern.KEINER
## Groesse des Musters (bei UMKREIS der Radius).
@export var special_size := 1
@export var special_damage := 0
## Alle so viele Zuege holt der Boss aus (Warnung), im Zug danach schlaegt er zu.
@export var special_every := 3
