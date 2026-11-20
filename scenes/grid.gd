extends Node2D

enum PlayerType {
	Cpu, # Controlled By Bot
	One,
	Two,
}

@export var player_type := PlayerType.Cpu
