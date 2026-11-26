class_name Grid
extends RefCounted

signal changed ## Always emitted when grid is dirty
signal line_cleared(line: PackedInt32Array) ## Always called after each line cleared

const EMPTY_CELL := -1

var _width: int
var _height: int

var _cells: PackedInt32Array


func _init(width: int = 10, height: int = 20) -> void:
	_width = width
	_height = height

	_cells.resize(_width * _height)
	_cells.fill(EMPTY_CELL)


func get_cell(pos: Vector2i) -> int:
	return _cells[pos.x + (pos.y * _width)]


## Any cell outside grid counts as 'Occupied'. But cells above 0, are
## counted as 'Empty', so cells can spawn partially hidden
func is_empty(pos: Vector2i) -> bool:
	if pos.x < 0 or pos.x >= _width or pos.y >= _height:
		return false
	return pos.y < 0 or _cells[pos.x + (pos.y * _width)] == EMPTY_CELL


## Check all cells positions and return false if any collisions are found
func can_place(cells: Array[Vector2i], origin: Vector2i) -> bool:
	if cells.is_empty():
		return false

	for cell in cells:
		if not is_empty(origin + cell):
			return false
	return true


func lock(cells: Array[Vector2i], origin: Vector2i, blocks: PackedInt32Array) -> bool:
	var success := true

	for i in cells.size():
		var pos := origin + cells[i]

		# If cell is above grid, it cannot be locked :C
		if pos.y < 0:
			success = false
			continue

		_cells[pos.x + (pos.y * _width)] = blocks[i]

	changed.emit()
	return success


func clear_lines() -> int:
	var cleared := 0
	var y := _height - 1
	while y >= 0: # Walk bottom to top
		if !_is_row_complete(y):
			y -= 1
			continue # Check next row

		# Delete row and recheck the current row again
		var row := _get_row(y)
		_delete_row(y)
		line_cleared.emit(row)
		cleared += 1

	if cleared > 0:
		changed.emit()
	return cleared


func get_width() -> int:
	return _width


func get_height() -> int:
	return _height


## Check if current row is filled
func _is_row_complete(y: int) -> bool:
	assert(
		y >= 0 and y < _height,
		"row %d out of range (height %d, cells %d)" % [y, _height, _cells.size()],
	)

	for x in _width:
		if _cells[x + (y * _width)] == EMPTY_CELL:
			return false
	return true


func _get_row(y: int) -> PackedInt32Array:
	return _cells.slice(y * _width, (y + 1) * _width)


## DELETES the entire row :3
func _delete_row(row: int) -> void:
	# Go from bottom to top, where top is 0, and bottom is current row,
	# then copy the row above onto the current.
	for y in range(row, 0, -1):
		for x in _width:
			_cells[x + (y * _width)] = _cells[x + ((y - 1) * _width)]

	# Just clears the top row
	for x in _width:
		_cells[x] = EMPTY_CELL
