extends Node

var main_seed: int = 0

var pieces := RandomNumberGenerator.new()
var events := RandomNumberGenerator.new()


func reset(custom_seed: int = -1) -> int:
	if custom_seed == -1:
		randomize()
		main_seed = randi()
	else:
		main_seed = custom_seed

	# Derive seed into deterministic sub-seeds
	pieces.seed = hash(main_seed + 1)
	events.seed = hash(main_seed + 2)
	return main_seed
