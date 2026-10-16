class_name FighterData
extends Resource
## Ein spielbarer Kaempfer als Daten-Datei (siehe data/fighters/*.tres).
## Die Faehigkeiten stecken in einfachen Zahlen: 0 heisst "hat er nicht".
## Upgrades (data/upgrades) erhoehen im laufenden Run einfach dieselben Werte.

@export var display_name := "Kaempfer"
## Kurzer Satz fuer die Kaempfer-Auswahl.
@export var description := ""
@export var max_hp := 20
@export var attack := 3
## Akzentfarbe (Ersatz, falls kein Sprite da ist).
@export var color := Color.WHITE
## Alle Posen nebeneinander in gleich grossen Zellen, Reihenfolge wie Unit.Pose.
## Der Held schaut im Bild nach rechts.
@export var sprite_sheet: Texture2D
## Grosses Bild fuer Kaempfer-Auswahl und Ergebnis (120 x 160).
@export var artwork: Texture2D

@export_group("Spezialfaehigkeit")
@export var ability_name := ""
## Kurze Erklaerung fuer die Kaempfer-Auswahl.
@export var ability_text := ""
## Konter: Schaden, mit dem er sofort zurueckschlaegt, wenn er getroffen wird.
@export var counter_damage := 0
## Super-Armor: so viel weniger Schaden pro Treffer (mindestens 1 kommt immer durch).
@export var armor := 0
## Wurf: so viele Felder fliegt ein getroffener Gegner weg.
@export var throw_distance := 0
## Wurf: Extra-Schaden, wenn der Gegner gegen eine Wand oder einen anderen Gegner knallt.
@export var throw_slam_damage := 0
## Reichweite in Feldern. 1 = nur Nahkampf, mehr = Ki-Strahl in gerader Linie.
@export var attack_range := 1
## Ausweichen: Chance (0 bis 1), einem Angriff komplett zu entgehen.
@export_range(0.0, 1.0, 0.05) var dodge_chance := 0.0

@export_group("Ki")
## Groesse der Ki-Leiste.
@export var max_ki := 10
## Ki zu Beginn des Runs.
@export var start_ki := 0
## Ki pro Aufladen (kostet den ganzen Zug).
@export var ki_charge := 3
## Ki fuer jeden normalen Treffer.
@export var ki_per_hit := 1
## Techniken auf Q und E (in dieser Reihenfolge).
@export var techniques: Array[TechniqueData] = []

@export_group("Upgrades")
## Diese Werte sind beim Start 0 und wachsen nur durch Upgrades.
## Techniken kosten so viel Ki weniger (mindestens 1).
@export var technique_discount := 0
## Techniken machen so viel mehr Schaden.
@export var technique_power := 0
## HP zurueck bei jedem normalen Treffer.
@export var heal_per_hit := 0
## Ki zu Beginn jeder Runde.
@export var round_start_ki := 0

@export_group("Verwandlung")
## Erwacht auf der letzten Map vor dem Endboss (Taste T bei voller Ki-Leiste).
@export var transformation: TransformationData
