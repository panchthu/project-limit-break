class_name RoundData
extends Resource
## Eine Runde einer Map: welche Gegner wo auftauchen.
## enemies und cells gehoeren paarweise zusammen (erster Gegner aufs erste Feld usw.).

@export var display_name := "Runde"
@export var enemies: Array[EnemyData] = []
@export var cells: Array[Vector2i] = []
