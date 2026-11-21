class_name Board
extends Node2D

var _controller: Controller
var _grid: Grid


func _process(delta: float) -> void:
	_controller.poll(delta, self)
