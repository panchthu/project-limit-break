class_name UpgradeData
extends Resource
## Ein Upgrade zwischen den Runden als Daten-Datei (siehe data/upgrades/*.tres).
## Nach jeder Runde gibt es 3 zufaellige Upgrades zur Auswahl, eins wird genommen.
## Es erhoeht einen Wert des Kaempfers fuer den Rest des Runs ("stat" um "amount").

enum Stat {
	## Mehr maximale HP.
	MAX_HP,
	## Mehr Schaden pro normalem Schlag.
	ATTACK,
	## Groessere Ki-Leiste.
	MAX_KI,
	## Mehr Ki pro Aufladen.
	KI_CHARGE,
	## Mehr Ki pro normalem Treffer.
	KI_PER_HIT,
	## Techniken kosten weniger Ki (mindestens 1).
	TECHNIQUE_DISCOUNT,
	## Techniken machen mehr Schaden.
	TECHNIQUE_POWER,
	## Super-Armor: weniger Schaden pro Treffer.
	ARMOR,
	## Ausweichen: amount Prozentpunkte mehr.
	DODGE,
	## Konter: mehr Schaden beim Zurueckschlagen.
	COUNTER,
	## Wurf: Gegner fliegen weiter und der Aufprall tut mehr weh.
	THROW,
	## Reichweite des Ki-Strahls.
	RANGE,
	## HP zurueck bei jedem normalen Treffer.
	HEAL_PER_HIT,
	## Ki zu Beginn jeder Runde.
	ROUND_START_KI,
}

@export var display_name := "Upgrade"
## Kurze Erklaerung auf der Karte (2 bis 3 kurze Zeilen).
@export var description := ""
@export var stat := Stat.MAX_HP
@export var amount := 1
## Nur fuer diesen Kaempfer (leer = fuer alle).
@export var fighter: FighterData
## So oft kann man es pro Run nehmen (0 = beliebig oft).
@export var max_picks := 0
## Wie oft es im Vergleich zu anderen auftaucht (3 = normal, 1 = selten).
@export var weight := 3
## Farbe des Kartenrands.
@export var color := Color("8fe8ff")


## Erhoeht den Wert im Kaempfer des laufenden Runs.
func apply_to(data: FighterData) -> void:
	match stat:
		Stat.MAX_HP:
			data.max_hp += amount
		Stat.ATTACK:
			data.attack += amount
		Stat.MAX_KI:
			data.max_ki += amount
		Stat.KI_CHARGE:
			data.ki_charge += amount
		Stat.KI_PER_HIT:
			data.ki_per_hit += amount
		Stat.TECHNIQUE_DISCOUNT:
			data.technique_discount += amount
		Stat.TECHNIQUE_POWER:
			data.technique_power += amount
		Stat.ARMOR:
			data.armor += amount
		Stat.DODGE:
			data.dodge_chance = minf(data.dodge_chance + amount / 100.0, 0.75)
		Stat.COUNTER:
			data.counter_damage += amount
		Stat.THROW:
			data.throw_distance += 1
			data.throw_slam_damage += amount
		Stat.RANGE:
			data.attack_range += amount
		Stat.HEAL_PER_HIT:
			data.heal_per_hit += amount
		Stat.ROUND_START_KI:
			data.round_start_ki += amount
