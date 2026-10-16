class_name MapData
extends Resource
## Eine Map als Daten-Datei (siehe data/maps/*.tres): mehrere Runden, die letzte ist der Boss.

@export var display_name := "Map"
## Die zwei Farben des Schachbrett-Bodens.
@export var floor_color_a := Color("2b2640")
@export var floor_color_b := Color("332d4d")
@export var rounds: Array[RoundData] = []
