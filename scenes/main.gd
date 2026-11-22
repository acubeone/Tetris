extends Node

const BOARD_SCENE := preload("res://scenes/board/board.tscn")

@export var pieces: Array[Piece]

var board_one: Board
var board_two: Board

@onready var board_one_pos: Marker2D = $BoardOne
@onready var board_two_pos: Marker2D = $BoardTwo


func _ready() -> void:
	board_one = _make_board(
		Board.make_controller(Board.PlayerKind.PLAYER_ONE),
		board_one_pos.position,
	)
	board_two = _make_board(
		Board.make_controller(Board.PlayerKind.PLAYER_TWO),
		board_two_pos.position,
	)


func _make_board(controller: Controller, pos: Vector2) -> Board:
	var board := BOARD_SCENE.instantiate() as Board
	board.controller = controller
	board.pieces = pieces
	board.position = pos
	add_child(board)
	return board
