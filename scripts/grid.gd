class_name Grid
## Gemeinsame Raster-Konstanten und Umrechnung Feld <-> Pixel.

const TILE_SIZE := 16
## 20 x 10 Felder = 320 x 160 Pixel. Die unteren 20 Pixel bleiben fuer die Anzeige frei.
const WIDTH := 20
const HEIGHT := 10


## Pixelposition der oberen linken Ecke eines Feldes.
static func cell_to_world(cell: Vector2i) -> Vector2:
	return Vector2(cell * TILE_SIZE)


static func is_inside(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < WIDTH and cell.y < HEIGHT
