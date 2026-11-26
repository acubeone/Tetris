## I have asked Claude to do most of this code, I could do everything manually,
## but I don't want to. In the end, I understand what this do anyways.
@tool
class_name PiecePainter
extends TileMapLayer

var piece_name := ""
var weight := 1.0
var save_path := "res://assets/pieces"
var pivot := Vector2i.ZERO:
	set(val):
		pivot = val
		_update_marker()
		update_configuration_warnings()

@onready var _pivot_marker := $PivotMarker


func _ready() -> void:
	if not Engine.is_editor_hint():
		return

	_update_marker()
	update_configuration_warnings()


# Shows a yellow warning triangle on the node in the scene dock
func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	if tile_set == null:
		warnings.append("Assign a TileSet so the pivot marker can be placed.")
	if posmod(pivot.x - pivot.y, 2) != 0:
		warnings.append(
			"pivot2 %s is on a cell edge. Use (even, even) for a cell center or (odd, odd) for a corner."
			% pivot,
		)
	return warnings


func _get_property_list() -> Array[Dictionary]:
	var props: Array[Dictionary] = [
		{ "name": &"PiecePainter", "type": TYPE_NIL, "usage": PROPERTY_USAGE_CATEGORY },
		{ "name": &"piece_name", "type": TYPE_STRING, "usage": PROPERTY_USAGE_DEFAULT },
		{ "name": &"Settings", "type": TYPE_NIL, "usage": PROPERTY_USAGE_GROUP },
		{ "name": &"weight", "type": TYPE_FLOAT, "usage": PROPERTY_USAGE_DEFAULT },
		{ "name": &"pivot", "type": TYPE_VECTOR2I, "usage": PROPERTY_USAGE_DEFAULT },
		{
			"name": &"save_path",
			"type": TYPE_STRING,
			"usage": PROPERTY_USAGE_DEFAULT,
			"hint": PROPERTY_HINT_DIR,
		},
		{
			"name": &"Save Piece",
			"type": TYPE_CALLABLE,
			"usage": PROPERTY_USAGE_EDITOR,
			"hint": PROPERTY_HINT_TOOL_BUTTON,
			"hint_string": "Save Piece",
		},
	]

	return props


func _get(property: StringName) -> Variant:
	if property == &"Save Piece":
		return _save_piece
	return null


func _save_piece() -> void:
	if posmod(pivot.x - pivot.y, 2) != 0:
		push_error("pivot2 %s is on a cell edge. Use (even, even) or (odd, odd)." % pivot)
		return
	if piece_name.strip_edges().is_empty():
		push_warning("Piece Name cannot be empty.")
		return

	var used := get_used_cells()
	if used.is_empty():
		push_warning("Nothing painted.")
		return

	var source := get_cell_source_id(used[0])
	for c in used:
		if get_cell_source_id(c) != source:
			push_error("All cells must come from the same TileSet source (error at %s)." % c)
			return
		if get_cell_alternative_tile(c) != 0:
			push_error("Cell %s uses an alternative tile. Paint unrotated, default tiles only." % c)
			return

	var piece := Piece.new()
	piece.pattern = get_pattern(used)
	piece.pivot = pivot - (get_used_rect().position * 2)
	piece.weight = weight

	DirAccess.make_dir_recursive_absolute(save_path)
	var path := save_path.path_join("%s.tres" % piece_name)
	piece.take_over_path(path)
	var err := ResourceSaver.save(piece, path)
	if err == OK:
		print("Saved %s (%d cells)" % [path, used.size()])
	else:
		push_error("Could not save %s (error %d)" % [path, err])


func _update_marker() -> void:
	# Setters also run while the scene loads, before the node is in the tree
	if not is_inside_tree() or tile_set == null:
		return
	if not Engine.is_editor_hint():
		return

	_pivot_marker.position = Vector2(pivot + Vector2i.ONE) * Vector2(tile_set.tile_size) * 0.5
