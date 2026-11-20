class_name PlayerController
extends Controller

const ACTION_LEFT := 0
const ACTION_RIGHT := 1
const ACTION_DROP := 2
const ACTION_ROTATE := 3

@export_enum("p1", "p2") var player_type: String

var _action_set: Array[StringName]


func _ready() -> void:
	_action_set[ACTION_LEFT] = player_type + "_move_left"
	_action_set[ACTION_RIGHT] = player_type + "_move_right"
	_action_set[ACTION_DROP] = player_type + "_move_drop"
	_action_set[ACTION_ROTATE] = player_type + "_move_rotate"


func _process(_delta: float) -> void:
	_direction = sign(Input.get_axis(_action_set[ACTION_LEFT], _action_set[ACTION_RIGHT]))
