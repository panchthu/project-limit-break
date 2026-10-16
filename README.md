# Project Limit Break

Rundenbasierter 2D-Roguelike im Retro-Anime-Stil. Godot 4 (GDScript), interne Aufloesung 320x180, pixelgenau hochskaliert.

## Starten
1. Godot 4 oeffnen, "Importieren" und die Datei `project.godot` waehlen.
2. F5 druecken.

Steuerung: WASD oder Pfeiltasten bewegen/waehlen, Enter oder Leertaste bestaetigen, Esc zurueck, R auf dem Ergebnis-Bildschirm = nochmal.

Im Kampf: eine Aktion pro Zug. Laufen/Angreifen mit den Richtungstasten, **F** laedt Ki auf (+3, Ki-Akrobat +4),
**Q/E** setzen die beiden Techniken des Kaempfers ein (kosten Ki; manche wollen danach eine Richtung, Esc bricht ab).
Jeder normale Treffer bringt +1 Ki. Techniken ohne Ziel werden nicht ausgefuehrt und kosten nichts.

Ablauf: Titel -> Kaempfer-Auswahl -> Run mit 3 Maps (je Runden, dann Boss) -> Sieg / Game Over -> Titel.

Gegnertypen: **Schlaeger** (Nahkampf), **Ki-Schuetze** (schiesst in gerader Linie, weicht zurueck),
**Panzer** (viel HP, Ruestung, laeuft nur jeden zweiten Zug), **Flitzer** (zwei Schritte pro Zug).
Bosse holen regelmaessig zu einer Spezialattacke aus: die Felder werden rot markiert, im naechsten Zug schlaegt sie ein.

## Ordner
- `scenes/` Szenen (.tscn)
- `scripts/` GDScript-Code
- `data/fighters/` Kaempfer als Daten (Werte, Ki, Techniken)
- `data/techniques/` Ki-Techniken als Daten (Kosten, Schaden, Reichweite)
- `data/enemies/` Gegnertypen und Bosse als Daten (Verhalten, Werte, Spezialattacke)
- `data/maps/` Maps als Daten (Bodenfarben, Runden mit Gegnern und Startfeldern); die Reihenfolge im Run steht in `Game.MAPS`
- `assets/` Grafiken, Sounds, Musik, Schriften

## Meilensteine
Der Gesamtplan (M1 bis M13) liegt in der Projekt-Roadmap.
1. Figur bewegt sich auf einem Raster
2. Gegner, einfacher Kampf, Runden mit Boss
3. Bildschirme: Titel, Kaempfer-Auswahl, Ergebnis
4. Kaempfer als Daten mit echten Unterschieden
5. Ki-Leiste und Techniken
6. Gegnertypen und Maps als Daten, kompletter Run bis zum Endboss  <- aktuell
