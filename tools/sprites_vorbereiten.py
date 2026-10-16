"""Macht aus den grossen KI-Bildern die kleinen Spiel-Grafiken in assets/.

Aufruf (aus dem Repo-Ordner):
    python3 tools/sprites_vorbereiten.py <ordner-mit-den-grossen-bildern>

Der Quellordner hat denselben Aufbau wie limit-break-assets/ im Projekt:
    sprites/helden/<name>/0_idle.png ... 6_ko.png   (7 Posen pro Held)
    sprites/gegner/<name>.png, sprites/bosse/<name>.png   (eine Pose)
    artworks/helden/<name>.png, artworks/bosse/<name>_portrait.png
    maps/<name>.png   (Hintergrund einer Map, optional)

Braucht Pillow und numpy. Neue Figur? Einfach unten in HOEHEN eintragen.
"""

import os
import sys

import numpy as np
from PIL import Image

REPO = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
OUT = os.path.join(REPO, "assets")

## Hoehe in Spielpixeln (ein Feld = 16). Bosse sind deutlich groesser.
HOEHEN = {
    "helden/techniker": 30,
    "helden/koloss": 32,
    "helden/ki_akrobat": 30,
    "gegner/schlaeger": 30,
    "gegner/ki_schuetze": 28,
    "gegner/panzer": 31,
    "gegner/flitzer": 24,
    "bosse/felsbrecher": 48,
    "bosse/sturmauge": 46,
    "bosse/schattenkaiser": 48,
}
POSEN = ["idle", "gehen", "angriff1", "angriff2", "spezial", "treffer", "ko"]
## Artworks der Helden (Auswahl und Ergebnis) und Boss-Portraets (Boss-Intro).
ARTWORK_GROESSE = (120, 160)
PORTRAIT_GROESSE = (256, 144)
## Map-Hintergruende fuellen das Spielfeld (20 x 10 Felder).
MAPS = ["bambustal", "wuestenruine", "himmelsturm"]
MAP_GROESSE = (320, 160)


def verkleinern(im: Image.Image, faktor: float) -> np.ndarray:
    """Weich verkleinern, dann Alpha hart machen (keine halbdurchsichtigen Pixel)."""
    w = max(1, round(im.width * faktor))
    h = max(1, round(im.height * faktor))
    a = np.array(im.convert("RGBA").resize((w, h), Image.Resampling.BOX))
    a[:, :, 3] = np.where(a[:, :, 3] >= 128, 255, 0)
    return a


def speichern(a: np.ndarray, pfad: str) -> None:
    os.makedirs(os.path.dirname(pfad), exist_ok=True)
    Image.fromarray(a).save(pfad, optimize=True)


def zuschneiden(im: Image.Image, groesse: tuple[int, int], oben: float = 0.5) -> Image.Image:
    """Auf das Seitenverhaeltnis zuschneiden (oben = wo vertikal geschnitten wird), dann skalieren."""
    ziel = groesse[0] / groesse[1]
    w, h = im.size
    if w / h > ziel:
        neu_w = round(h * ziel)
        x = (w - neu_w) // 2
        im = im.crop((x, 0, x + neu_w, h))
    else:
        neu_h = round(w / ziel)
        y = round((h - neu_h) * oben)
        im = im.crop((0, y, w, y + neu_h))
    return im.convert("RGB").resize(groesse, Image.Resampling.LANCZOS)


def held(quelle: str, name: str, hoehe: int) -> None:
    """7 Posen in einen Streifen mit gleich grossen Zellen, Fuesse unten mittig."""
    bilder = [Image.open(f"{quelle}/sprites/helden/{name}/{i}_{p}.png") for i, p in enumerate(POSEN)]
    faktor = hoehe / bilder[0].height
    posen = [verkleinern(b, faktor) for b in bilder]
    zelle_w = max(p.shape[1] for p in posen)
    zelle_h = max(p.shape[0] for p in posen)
    streifen = np.zeros((zelle_h, zelle_w * len(posen), 4), np.uint8)
    for i, p in enumerate(posen):
        x = i * zelle_w + (zelle_w - p.shape[1]) // 2
        streifen[zelle_h - p.shape[0]:, x:x + p.shape[1]] = p
    speichern(streifen, f"{OUT}/sprites/helden/{name}.png")
    print(f"helden/{name}: {len(posen)} Posen, Zelle {zelle_w}x{zelle_h}")


def main() -> None:
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    quelle = sys.argv[1]
    for key, hoehe in HOEHEN.items():
        art, name = key.split("/")
        if art == "helden":
            held(quelle, name, hoehe)
            os.makedirs(f"{OUT}/artworks/helden", exist_ok=True)
            zuschneiden(Image.open(f"{quelle}/artworks/{key}.png"), ARTWORK_GROESSE).save(
                f"{OUT}/artworks/{key}.png", optimize=True)
            continue
        bild = Image.open(f"{quelle}/sprites/{key}.png")
        a = verkleinern(bild, hoehe / bild.height)
        speichern(a, f"{OUT}/sprites/{key}.png")
        print(f"{key}: {a.shape[1]}x{a.shape[0]}")
        if art == "bosse":
            os.makedirs(f"{OUT}/artworks/bosse", exist_ok=True)
            zuschneiden(Image.open(f"{quelle}/artworks/{key}_portrait.png"), PORTRAIT_GROESSE, oben=0.3).save(
                f"{OUT}/artworks/{key}.png", optimize=True)
    for name in MAPS:
        pfad = f"{quelle}/maps/{name}.png"
        if not os.path.exists(pfad):
            print(f"maps/{name}: noch kein Bild")
            continue
        os.makedirs(f"{OUT}/maps", exist_ok=True)
        zuschneiden(Image.open(pfad), MAP_GROESSE).save(f"{OUT}/maps/{name}.png", optimize=True)
        print(f"maps/{name}: {MAP_GROESSE[0]}x{MAP_GROESSE[1]}")


if __name__ == "__main__":
    main()
