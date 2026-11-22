@abstract
class_name Controller
extends Resource

var _direction: int
var _drop_held: bool
var _rotate_queued: bool


func get_direction() -> int:
	return _direction


func is_drop_held() -> bool:
	return _drop_held


func consume_rotate() -> bool:
	var rotate := _rotate_queued
	_rotate_queued = false
	return rotate


## Called every frame by the board. The CPU can use the `board` to decide what
## to do.
@abstract func poll(delta: float, board: Board) -> void
