class_name PlayerController
extends Controller

const PLAYER_ONE := 0
const PLAYER_TWO := 1

@export_enum("P1:0", "P2:1") var player: int

var _move_left: StringName
var _move_right: StringName
var _action_drop: StringName
var _action_rotate: StringName


func _init() -> void:
	assert(player in [PLAYER_ONE, PLAYER_TWO], "Use PLAYER_ONE or PLAYER_TWO!")

	var player_name := "p1" if player == PLAYER_ONE else "p2"
	_move_left = StringName(player_name + "_move_left")
	_move_right = StringName(player_name + "_move_right")
	_action_drop = StringName(player_name + "_action_drop")
	_action_rotate = StringName(player_name + "_action_rotate")


func poll(_delta: float, _board: Board) -> void:
	@warning_ignore("narrowing_conversion")
	_direction = signi(Input.get_axis(_move_left, _move_right))
	_drop_held = Input.is_action_pressed(_action_drop)

	if Input.is_action_just_pressed(_action_rotate):
		_rotate_queued = true
