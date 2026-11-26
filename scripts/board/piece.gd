class_name Piece
extends Resource

@export var pattern: TileMapPattern
@export var pivot := Vector2i.ZERO ## Rotation origin, calculated by half-tiles
@export var weight := 1.0 ## Chance to spawn

var source_id: int
var cells: Array[Vector2i]
var tiles: Array[Vector2i]

## 90° clockwise steps
const ROTATION_FLAGS := [
	0,
	TileSetAtlasSource.TRANSFORM_FLIP_H | TileSetAtlasSource.TRANSFORM_TRANSPOSE,
	TileSetAtlasSource.TRANSFORM_FLIP_H | TileSetAtlasSource.TRANSFORM_FLIP_V,
	TileSetAtlasSource.TRANSFORM_FLIP_V | TileSetAtlasSource.TRANSFORM_TRANSPOSE,
]

var _anchored_pivot: Vector2i # Relative to the anchor cell
var _rotated: Array # Possible rotations of this piece


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
	assert(
		posmod(pivot.x - pivot.y, 2) == 0,
		"pivot %s isn't a edge of cell. Use (even, even) or (odd, odd)" % pivot,
	)

	cells.clear()
	tiles.clear()

	var used := pattern.get_used_cells()
	assert(not used.is_empty(), "Piece pattern is empty!")
	source_id = pattern.get_cell_source_id(used[0])

	# Positions are integers, so keep archo relative to the cell holding the pivot
	var anchor := Vector2i(floori(pivot.x / 2.0), floori(pivot.y / 2.0))
	_anchored_pivot = pivot - (anchor * 2) # Each component is 0 or 1
	for cell in used:
		cells.append(cell - anchor)
		tiles.append(pattern.get_cell_atlas_coords(cell))

	_rotated.append(_calculate_rotation(0)) # Rotation: 0°
	_rotated.append(_calculate_rotation(1)) # Rotation: 90°
	_rotated.append(_calculate_rotation(2)) # Rotation: 180°
	_rotated.append(_calculate_rotation(3)) # Rotation: 270°


func is_valid() -> bool:
	return not cells.is_empty() and cells.size() == tiles.size()


func get_cells(rotation: int) -> Array[Vector2i]:
	return _rotated[posmod(rotation, 4)]


func get_blocks(rotation: int) -> PackedInt32Array:
	var out := PackedInt32Array()
	for tile in tiles:
		out.append(pack(source_id, tile, rotation))
	return out


func _calculate_rotation(rot: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []

	# Eatch rotation is 90° clockwise
	for cell in cells:
		var offset := (cell * 2) - _anchored_pivot # Use half cells
		var turned: Vector2i

		# fmt: off
		match rot:
			1: turned = Vector2i(-offset.y, offset.x)
			2: turned = Vector2i(-offset.x, -offset.y)
			3: turned = Vector2i(offset.y, -offset.x)
			_: turned = offset
		# fmt: on
		@warning_ignore("integer_division")
		out.append((turned + _anchored_pivot) / 2) # Go back to whole cells

	return out
