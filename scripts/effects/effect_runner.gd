class_name EffectRunner
extends RefCounted

signal started(effect: BoardEffect)
signal ended(effect: BoardEffect)

var _board: Board
var _active: Array[BoardEffect] = []


func _init(board: Board) -> void:
	_board = board


func add(effect: BoardEffect) -> void:
	if not effect.stackable:
		for active in _active:
			if active.get_script() == effect.get_script():
				active.elapsed = 0.0 # Rest instead of stacking
				return

	var e := effect.duplicate() as BoardEffect
	_active.append(e)
	started.emit(e)
	e.start(_board)
	if e.is_instant():
		end(e) # End it instantly


func tick(delta: float) -> void:
	for effect: BoardEffect in _active.duplicate(): # Duplicate, since effect can finish early
		if not _active.has(effect):
			continue # Ended earlier than this loop, too bad
		effect.tick(delta, _board)
		effect.elapsed += delta
		if effect.duration > 0.0 and effect.elapsed >= effect.duration:
			end(effect)


func end_piece_bound() -> void:
	for effect: BoardEffect in _active.duplicate():
		if effect.bounded:
			end(effect)


func end_all() -> void:
	for effect: BoardEffect in _active.duplicate():
		end(effect)


func end(effect: BoardEffect) -> void:
	if not _active.has(effect):
		return
	_active.erase(effect)
	effect.finish(_board)
	ended.emit(effect)


func get_actives() -> Array[BoardEffect]:
	return _active.duplicate()


## Accumulate fall interval from all active effects
func apply_fall_interval(base: float) -> float:
	for effect in _active:
		base = effect.modify_fall_interval(base)
	return base


## Accumulate direction from all active effects
func apply_direction(direction: int) -> int:
	for effect in _active:
		direction = effect.modify_direction(direction)
	return direction
