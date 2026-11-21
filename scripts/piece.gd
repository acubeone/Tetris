class_name Piece
extends Resource

@export var pattern: TileMapPattern
@export var pivot := Vector2i.ZERO ## Rotation origin
@export var weight := 1.0 ## Chance to spawn

var source_id: int
var cells: Array[Vector2i]
var tiles: Array[Vector2i]


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
		out.append(Block.pack(source_id, tile, rotation))
	return out
