extends Node2D

enum ControllerType {
	Cpu, # Controlled By Bot
	PlayerOne,
	PlayerTwo,
}

@export var controller_type := ControllerType.Cpu

var _controller: Controller



func _ready() -> void:
	match controller_type:
		ControllerType.PlayerOne:
			_controller = PlayerController.new(PlayerController.PLAYER_ONE)
		ControllerType.PlayerTwo:
			_controller = PlayerController.new(PlayerController.PLAYER_TWO)
		ControllerType.Cpu:
			_controller = CpuController.new()
