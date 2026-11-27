class_name CpuController
extends Controller

const REACTION_DELAY := 0.17
const ROTATION_DELAY := 0.20

var spawnpoint: Vector2i ## Active piece starting spawnpoint.
var difficulty: float ## How much skill the CPU has. Must be between 0 and 1.

var _lines_weight := 0.76
var _height_weight := -0.51
var _holes_weight := -0.36
var _bump_weight := -0.18

# State management
var _current_plan: Dictionary = { }
var _planned_piece: ActivePiece = null
var _think_timer := 0.0
var _rotation_cooldown := 0.0


func set_weights(lines: float, height: float, holes: float, bump: float) -> void:
	_lines_weight = lines
	_height_weight = height
	_holes_weight = holes
	_bump_weight = bump


func poll(delta: float, board: Board) -> void:
	_rotation_cooldown -= delta

	var piece := board.get_active_piece()
	if piece == null:
		_reset_inputs()
		return # Game is over

	# Replan if active piece is different from planned one
	if piece != _planned_piece:
		_reset_inputs()
		_current_plan = _choose(_plan(board.grid, piece.piece))
		if _current_plan.is_empty():
			return # There is nothing we can do...
		_planned_piece = piece
		_think_timer = REACTION_DELAY # Reset timer

	if _think_timer > 0.0:
		_think_timer -= delta
		return # Do nothing while thinking

	if piece.rotation != _current_plan["rotation"]:
		if _rotation_cooldown <= 0 and not _rotate_queued:
			_rotate_queued = true
			_rotation_cooldown = ROTATION_DELAY
		return

	# Try to move horizontally to match desired column
	var diff_x := int(_current_plan["column"]) - piece.pos.x
	var desired := signi(diff_x)

	_direction = _get_direction(desired, board)
	_drop_held = diff_x == 0 # Only drop down if aligned


func _reset_inputs() -> void:
	_direction = 0
	_drop_held = false
	_rotate_queued = false


func _plan(grid: Grid, piece: Piece) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	var seen: Array[int] = [] # Set of unique masks

	for rot in range(4): # Rotations are 90° steps
		var cells := piece.get_cells(rot)

		var mask = _normalize(cells)
		if mask in seen:
			continue
		seen.append(mask) # Store mask as seen before

		# Reach from maximum possible column
		var reach := 0
		for cell in cells:
			reach = maxi(reach, absi(cell.x))

		for x in range(-reach, grid.get_width() + reach):
			var result := _simulate(grid, cells, x)
			if result.is_empty():
				continue

			var score := 0.0
			if result["reached_top"]:
				score = -1.0e10 # Oof
			else:
				score = _evaluate(result["sim"], result["lines_count"])

			results.append({ "rotation": rot, "column": x, "score": score })

	results.sort_custom(_sort_descending_score)
	return results


func _sort_descending_score(a: Dictionary, b: Dictionary) -> bool:
	assert(a.has("score") and b.has("score"), "Must have 'score' key!")
	return a["score"] > b["score"]


## Picks among the top 5, the higher the difficulty the best is picked
func _choose(results: Array[Dictionary]) -> Dictionary:
	if results.is_empty():
		return { }
	var k := roundi(lerpf(5, 1, difficulty))
	return results.slice(0, k).pick_random()


func _get_direction(desired: int, board: Board) -> int:
	for dir in [-1, 0, 1]:
		if board.effects.apply_direction(dir) == desired:
			return dir

	return 0 # Just don't move if you cannot


## Normalize cells to the top-left corner (0,0), then store format as mask.
## Note: Piece cannot be bigger than 8x8 cells.
func _normalize(cells: Array[Vector2i]) -> int:
	assert(cells.size() < 64, "Piece cannot be bigger than 8x8 cells.")

	var minimum := Vector2i.MAX
	for cell in cells:
		minimum.x = mini(minimum.x, cell.x)
		minimum.y = mini(minimum.y, cell.y)

	var mask := 0
	for cell in cells:
		var shift := ((cell.x - minimum.x) + ((cell.y - minimum.y) * 8))
		mask |= 1 << shift

	return mask


## Try to lower piece at the most bottom in a simulated grid, then capture result
func _simulate(grid: Grid, cells: Array[Vector2i], pos_x: int) -> Dictionary:
	var start := Vector2i(pos_x, spawnpoint.y) # Simulate where piece always start

	if not grid.can_place(cells, start):
		return { }
	# TODO: Check sliding across walls, so CPU don't get stuck
	# trying to move behind a wall of blocks

	# Try to go all the way down
	var pos_y = spawnpoint.y
	while grid.can_place(cells, Vector2i(pos_x, pos_y + 1)):
		pos_y += 1

	var sim := grid.copy() # Do not modify original grid
	var dummy_blocks := PackedInt32Array()
	dummy_blocks.resize(cells.size())
	dummy_blocks.fill(0)
	var ok := sim.lock(cells, Vector2i(pos_x, pos_y), dummy_blocks)
	var lines_count := sim.clear_lines()

	return { "sim": sim, "lines_count": lines_count, "reached_top": not ok }


## Calculate the resulting grid, lines cleared, height achieved and bumps on
## grid, them apply weights and sum them all up for the final score
func _evaluate(sim: Grid, lines_count: int) -> float:
	var holes := 0
	var heights: Array[int] = [] # Height of each column
	heights.resize(sim.get_width())

	for x in range(sim.get_width()):
		var has_seen_filled := false # If seen a filled cell in the column
		for y in range(sim.get_height()):
			if sim.get_cell(Vector2i(x, y)) != Grid.EMPTY_CELL:
				if not has_seen_filled:
					heights[x] = sim.get_height() - y # First filled cell sets the column height
					has_seen_filled = true
			elif has_seen_filled:
				holes += 1 # Empty cell, but there something above it

	var height_sum := 0
	var bumpiness := 0

	if not heights.is_empty():
		for y in heights:
			height_sum += y
		# Calculate how much peaks the each column has
		for x in range(sim.get_width() - 1):
			bumpiness += absi(heights[x] - heights[x + 1])

	var score: float = _lines_weight * lines_count
	score += _height_weight * height_sum # Negative weight
	score += _holes_weight * holes # Negative weight
	score += _bump_weight * bumpiness # Negative weight
	return score
