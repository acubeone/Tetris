class_name Piece
extends Resource

@export var pattern: TileMapPattern
@export var pivot := Vector2i.ZERO ## Rotation origin
@export var weight := 1.0 ## Chance to spawn

var source_id: int
var cells: Array[Vector2i]
var tiles: Array[Vector2i]

## 90° clockwise steps
const ROTATION_FLAGS := [
	0,
	TileSetAtlasSource.TRANSFORM_FLIP_H | TileSetAtlasSource.TRANSFORM_TRANSPOSE,
	0,
	TileSetAtlasSource.TRANSFORM_FLIP_H | TileSetAtlasSource.TRANSFORM_TRANSPOSE,
]


## Bitlayout:
## source(12) | atlas.x(8) | atlas.y(8) | rotation (4)
static func pack(source: int, atlas: Vector2i, rotation: int) -> int:
	return (source << 20) | (atlas.x << 12) | (atlas.y << 4) | posmod(rotation, 4)


static func paint(layer: TileMapLayer, pos: Vector2i, block: int) -> void:
	var atlas_x := (block >> 12) & 0xff
	var atlas_y := (block >> 4) & 0xff
	var source := (block >> 20) & 0x0fff
	var rotation := block & 0x03
	layer.set_cell(pos, source, Vector2i(atlas_x, atlas_y), ROTATION_FLAGS[rotation])


func setup() -> void:
	cells.clear()
	tiles.clear()

	var used := pattern.get_used_cells()
	assert(not used.is_empty(), "Piece pattern is empty!")
	source_id = pattern.get_cell_source_id(used[0])
	for cell in used:
		cells.append(cell - pivot)
		tiles.append(pattern.get_cell_atlas_coords(cell))


func is_valid() -> bool:
	return not cells.is_empty() and cells.size() == tiles.size()


func get_cells(rotation: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var rot := posmod(rotation, 4) # Rotate 90° clockwise

	for cell in cells:
		# fmt: off
		match rot:
			0: out.append(cell)
			1: out.append(Vector2i(-cell.y, cell.x))
			2: out.append(Vector2i(-cell.x, -cell.y))
			3: out.append(Vector2i(cell.y, -cell.x))
		# fmt: on

	return out


func get_blocks(rotation: int) -> PackedInt32Array:
	var out := PackedInt32Array()
	for tile in tiles:
		out.append(pack(source_id, tile, rotation))
	return out
