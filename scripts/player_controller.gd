class_name PlayerController
extends Controller

const PLAYER_ONE := 0
const PLAYER_TWO := 1

const _ACTION_LEFT := 0
const _ACTION_RIGHT := 1
const _ACTION_DROP := 2
const _ACTION_ROTATE := 3

var _action_set: Array[StringName]


func _init(player: int) -> void:
	assert(
		player in [PLAYER_ONE, PLAYER_TWO],
		"Maximum players are 2. Use PLAYER_ONE or PLAYER_TWO!",
	)

	var player_type := "p1" if player == PLAYER_ONE else "p2"
	_action_set[_ACTION_LEFT] = player_type + "_move_left"
	_action_set[_ACTION_RIGHT] = player_type + "_move_right"
	_action_set[_ACTION_DROP] = player_type + "_move_drop"
	_action_set[_ACTION_ROTATE] = player_type + "_move_rotate"


func _process(_delta: float) -> void:
	_direction = sign(Input.get_axis(_action_set[_ACTION_LEFT], _action_set[_ACTION_RIGHT]))

	if Input.is_action_just_pressed(_action_set[_ACTION_DROP]):
		_has_dropped = true
	if Input.is_action_just_released(_action_set[_ACTION_DROP]):
		_has_dropped = false

	if Input.is_action_just_pressed(_action_set[_ACTION_ROTATE]):
		_has_rotated = true
	if Input.is_action_just_released(_action_set[_ACTION_ROTATE]):
		_has_rotated = false
