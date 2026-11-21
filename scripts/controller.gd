@abstract
class_name Controller
extends Resource

var _direction: int
var _has_dropped: bool
var _has_rotated: bool


func get_direction() -> int:
	return _direction


func has_drop_pressed() -> bool:
	var dropped := _has_dropped
	_has_dropped = false
	return dropped


func has_rotate_pressed() -> bool:
	var rotated := _has_rotated
	_has_rotated = false
	return rotated
