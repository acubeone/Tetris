extends Node

enum GameType {
	PlayerVsPlayer = _PLAYER | (_PLAYER << 1),
	PlayerVsCpu = _PLAYER | (_CPU << 1),
	CpuVsCpu = _CPU | (_CPU << 1),
}

const BOARD_SCENE := preload("res://scenes/board/board.tscn")
const _PLAYER := 1 << 0
const _CPU := 1 << 1

@export var pieces: Array[Piece]

@export var game_type := GameType.PlayerVsPlayer

var board_one: Board
var board_two: Board

@onready var board_one_pos: Marker2D = $BoardOne
@onready var board_two_pos: Marker2D = $BoardTwo


func _ready() -> void:
	var controller_one: Controller
	var controller_two: Controller

	if (game_type & _PLAYER) != 0:
		controller_one = PlayerController.new(PlayerController.PLAYER_ONE)
	else:
		controller_one = CpuController.new()

	if (game_type & (_PLAYER << 1)) != 0:
		controller_two = PlayerController.new(PlayerController.PLAYER_TWO)
	else:
		controller_two = CpuController.new()

	board_one = _make_board(controller_one, board_one_pos.position)
	board_two = _make_board(controller_two, board_two_pos.position)

	if is_instance_of(controller_one, CpuController):
		controller_one.spawnpoint = board_one.get_spawnpoint()
		controller_one.difficulty = 1.0 # TODO: Add difficulty selection
	if is_instance_of(controller_two, CpuController):
		controller_two.spawnpoint = board_two.get_spawnpoint()
		controller_two.difficulty = 1.0 # TODO: Add difficulty selection


func _make_board(controller: Controller, pos: Vector2) -> Board:
	var board := BOARD_SCENE.instantiate() as Board
	board.controller = controller
	board.pieces = pieces
	board.position = pos
	add_child(board)
	return board
