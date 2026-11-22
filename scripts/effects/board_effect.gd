@abstract
class_name BoardEffect
extends Resource

@export var display_name := ""
@export var icon: Texture2D
@export_range(0.0, 30.0, 0.1, "or_greater") var duration := 0.0 ## Seconds, 0 = no time
@export var bounded := false # Ends when current piece locks
@export var stackable := false # false: re-adding resets the timer instead

var elapsed := 0.0


## Duration 0 and not bounded to current piece means: "Fire only once"
func is_instant() -> bool:
	return duration <= 0.0 and not bounded


func modify_fall_interval(interval: float) -> float:
	return interval


func modify_direction(direction: int) -> int:
	return direction


@abstract func start(_board: Board) -> void


@abstract func tick(_delta: float, _board: Board) -> void


@abstract func finish(_board: Board) -> void
