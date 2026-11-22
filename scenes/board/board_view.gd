class_name BoardView
extends Node2D

@onready var _locked: TileMapLayer = $Locked
@onready var _ghost: TileMapLayer = $Ghost
@onready var _active: TileMapLayer = $Active


func draw_locked(grid: Grid) -> void:
	_locked.clear()

	for y in grid.get_height():
		for x in grid.get_width():
			var cell := grid.get_cell(Vector2i(x, y))
			if cell != Grid.EMPTY_CELL:
				Piece.paint(_locked, Vector2i(x, y), cell)


func draw_piece(piece: ActivePiece, grid: Grid) -> void:
	_active.clear()
	_ghost.clear()

	var blocks := piece.get_blocks()
	var ghost := piece.ghost_position(grid)
	for i in piece.cells.size():
		Piece.paint(_ghost, ghost + piece.cells[i], blocks[i])
		Piece.paint(_active, piece.pos + piece.cells[i], blocks[i])


func clear_piece() -> void:
	_active.clear()
	_ghost.clear()
