## This was written by Claude, I don't know what happens here, and I
## don't want to now either.
## Is just like "Black Magic"
@tool
class_name PiecePainter
extends TileMapLayer

@export var piece_name := ""
@export var pivot := Vector2i.ZERO
@export var weight := 1.0
@export_dir var save_path := "res://assets/pieces"
@export_tool_button("Save Piece") var save := _save_piece


func _save_piece() -> void:
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
	piece.pivot = pivot - get_used_rect().position # pattern coords start at the top-left
	piece.weight = weight

	DirAccess.make_dir_recursive_absolute(save_path)
	var path := save_path + "/%s.tres" % piece_name
	piece.take_over_path(path) # keeps the editor from showing a stale copy on re-save
	var err := ResourceSaver.save(piece, path)
	if err == OK:
		print("Saved %s (%d cells)" % [path, used.size()])
	else:
		push_error("Could not save %s (error %d)" % [path, err])
