class_name ActivePiece
extends RefCounted

const KICKS: Array[int] = [0, -1, 1, -2, 2]

var cells: Array[Vector2i]
var piece: Piece
var rotation := 0
var pos: Vector2i


func _init(p: Piece, spawn: Vector2i) -> void:
	piece = p
	cells = p.get_cells(0)
	pos = spawn


## Move into direction if possible
func try_move(grid: Grid, dir: Vector2i) -> bool:
	if not grid.can_place(cells, pos + dir):
		return false

	pos += dir
	return true


## Rotate 90° clockwise if possible
func try_rotate(grid: Grid) -> bool:
	var rot := posmod(rotation + 1, 4)
	var rotated := piece.get_cells(rot)

	# Try to move piece slightly to try to rotate
	for kick in KICKS:
		if !grid.can_place(rotated, pos + Vector2i(kick, 0)):
			continue

		rotation = rot
		cells = rotated
		pos.x += kick
		return true

	return false


## Project piece into the lowest placeable location
func ghost_position(grid: Grid) -> Vector2i:
	var _pos := pos
	while grid.can_place(cells, _pos + Vector2i.DOWN):
		_pos.y += 1
	return _pos


func lock_into(grid: Grid) -> bool:
	return grid.lock(cells, pos, get_blocks())


func get_blocks() -> PackedInt32Array:
	return piece.get_blocks(rotation)
