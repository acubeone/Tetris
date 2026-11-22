class_name Board
extends Node2D

signal piece_locked
signal gameover

signal line_cleared(line: PackedInt32Array)
signal next_changed(piece: Piece)
signal reserved_changed(piece: Piece)
signal effect_started(effect: BoardEffect)
signal effect_ended(effect: BoardEffect)

enum PlayerKind {
	CPU,
	PLAYER_ONE,
	PLAYER_TWO,
}

const SOFT_DROP_MULTIPLIER := 6.0
const SOFT_DROP_MIN_INTERVAL := 0.06
const MIN_FALL_INTERVAL := 0.01

const AUTOREPEAT_DELAY := 0.15
const AUTOREPEAT_INTERVAL := 0.05

@export var pieces: Array[Piece]
@export var base_fall_interval := 0.8 ## Time in seconds

var controller: Controller

var grid := Grid.new()
var effects: EffectRunner

var _active_piece: ActivePiece # If this is null, then it's gameover!
var _next_piece: Piece
var _reserved_piece: Piece

var _fall_timer := 0.0
var _step_timer := 0.0
var _prev_dir := 0

@onready var _view: BoardView = $BoardView


static func make_controller(kind: PlayerKind) -> Controller:
	match kind:
		PlayerKind.PLAYER_ONE:
			return PlayerController.new(PlayerController.PLAYER_ONE)
		PlayerKind.PLAYER_TWO:
			return PlayerController.new(PlayerController.PLAYER_TWO)
		_:
			return CpuController.new()


func _init() -> void:
	effects = EffectRunner.new(self)
	effects.started.connect(effect_started.emit)
	effects.ended.connect(effect_ended.emit)


func _ready() -> void:
	assert(controller != null, "Controller is not set in board!")
	assert(not pieces.is_empty(), "Pieces pool is empty!")

	for piece in pieces:
		piece.setup()

	grid.changed.connect(_render_locked)
	grid.line_cleared.connect(_line_cleared)

	_next_piece = _pick_random()
	_place(take_next())


func _process(delta: float) -> void:
	if not is_playing():
		return
	controller.poll(delta, self)


func _physics_process(delta: float) -> void:
	if not is_playing():
		return

	effects.tick(delta)
	if not is_playing():
		return # An effect can lead to a gameover

	_step_horizontal(delta)
	if controller.consume_rotate():
		rotate_piece()
	_step_gravity(delta)

	if is_playing(): # Locking can do a gameover
		_view.draw_piece(_active_piece, grid)


func is_playing() -> bool:
	return _active_piece != null


func add_effect(effect: BoardEffect) -> void:
	if is_playing():
		effects.add(effect)


func rotate_piece() -> bool:
	return is_playing() and _active_piece.try_rotate(grid)


func reset_piece() -> void:
	if not is_playing():
		return

	var spawn := _spawn_pos()
	if grid.can_place(_active_piece.cells, spawn):
		_active_piece.pos = spawn
		_fall_timer = 0.0


## Stores `current` and returns the next piece. If slot was empty, returns
## a new one
func swap_reserved(current: Piece) -> Piece:
	var next := _reserved_piece
	_reserved_piece = current
	reserved_changed.emit(_reserved_piece)
	return next if next != null else take_next()


func take_next() -> Piece:
	var piece := _next_piece
	_next_piece = _pick_random()
	next_changed.emit(_next_piece)
	return piece


func peek_next() -> Piece:
	return _next_piece


func peek_reserved() -> Piece:
	return _reserved_piece


func _step_horizontal(delta: float) -> void:
	var dir := effects.apply_direction(controller.get_direction())
	var step := _step(delta, dir)
	if step != 0:
		_active_piece.try_move(grid, Vector2i(step, 0))


# Only apply gravity if timer reaches accumulated interval.
# If it can't move down, lock tile in place
func _step_gravity(delta: float) -> void:
	_fall_timer += minf(delta, 0.1)
	var interval := _fall_interval()
	if _fall_timer < interval:
		return # Do not go down

	# Keep left-over time
	_fall_timer = minf(_fall_timer - interval, interval)
	if not _active_piece.try_move(grid, Vector2i.DOWN):
		_lock_piece()


# Check next step, always return: -1, 0, or 1
func _step(delta: float, dir: int) -> int:
	if dir == 0:
		_prev_dir = 0
		return 0 # Nothing changed
	if dir != _prev_dir:
		_prev_dir = dir
		_step_timer = AUTOREPEAT_DELAY
		return dir

	_step_timer -= delta
	if _step_timer <= 0.0:
		_step_timer = AUTOREPEAT_INTERVAL
		return dir
	return 0


# The fall interval is the accumulated effects, or the soft-drop
# when drop is held. Also, fall interval is always 100ms
func _fall_interval() -> float:
	var interval := effects.apply_fall_interval(base_fall_interval)
	if controller.is_drop_held():
		var soft := maxf(interval / SOFT_DROP_MULTIPLIER, SOFT_DROP_MIN_INTERVAL)
		interval = minf(interval, soft)
	return maxf(interval, MIN_FALL_INTERVAL)


func _place(piece: Piece) -> void:
	effects.end_piece_bound() # Any new placed piece ends the piece-bounded effects
	_active_piece = ActivePiece.new(piece, _spawn_pos())
	_fall_timer = 0.0

	if not grid.can_place(_active_piece.cells, _active_piece.pos):
		_end_game() # Oh no


func _lock_piece() -> void:
	var alive := _active_piece.lock_into(grid)
	piece_locked.emit()
	grid.clear_lines()
	if alive:
		_place(take_next())
	else:
		_end_game()


func _end_game() -> void:
	_active_piece = null
	effects.end_all()
	_view.clear_piece()
	gameover.emit()


func _spawn_pos() -> Vector2i:
	return Vector2i(grid.get_width() >> 1, 0) # Always in the middle


func _pick_random() -> Piece:
	var weights := PackedFloat32Array()
	for piece in pieces:
		weights.append(piece.weight)

	var index := GameRng.pieces.rand_weighted(weights)
	return pieces[index]


func _render_locked() -> void:
	_view.draw_locked(grid)


func _line_cleared(line: PackedInt32Array) -> void:
	line_cleared.emit(line)
