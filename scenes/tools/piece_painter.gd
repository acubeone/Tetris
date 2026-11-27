## I have asked Claude to do most of this code, I could do everything manually,
## but I don't want to
@tool
class_name PiecePainter
extends TileMapLayer

const MARKER_NAME := "PivotMarker"
const PREVIEW_NAME := "Preview"

@export_group("Piece")
@export var piece_name := "carrot"
@export var weight := 1.0
## Pivot in HALF tiles, in the coordinates you painted.
## (even, even) = center of a cell, (odd, odd) = corner shared by four cells.
@export var pivot := Vector2i.ZERO:
	set(value):
		pivot = value
		_queue_refresh()

@export_group("Files")
@export_dir var save_dir := "res://pieces"
@export var piece_to_edit: Piece ## drop an existing .tres here, then press "Load piece"

@export_group("Actions")
@export_tool_button("Load piece") var load_button = _load_piece
@export_tool_button("Save piece") var save_button = _save_piece
@export_tool_button("Clear") var clear_button = _clear_all
@export_tool_button("Refresh preview") var refresh_button = _refresh

var _refresh_queued := false


func _ready() -> void:
	if not Engine.is_editor_hint():
		return
	if not changed.is_connected(_queue_refresh):
		changed.connect(_queue_refresh) # fires while you paint
	_queue_refresh()


func _get_configuration_warnings() -> PackedStringArray:
	var problem := _validate()
	return PackedStringArray([problem]) if problem != "" else PackedStringArray()


# --- validation ------------------------------------------------------------
## Returns "" when the painted piece is valid, otherwise what is wrong.
func _validate() -> String:
	if tile_set == null:
		return "Assign a TileSet."
	var used := get_used_cells()
	if used.is_empty():
		return "Nothing painted."
	if posmod(pivot.x - pivot.y, 2) != 0:
		return "pivot %s is on a cell edge. Use (even, even) or (odd, odd)." % pivot

	var source := get_cell_source_id(used[0])
	for c in used:
		if get_cell_source_id(c) != source:
			return "Mixed TileSet sources at %s." % c
		if get_cell_alternative_tile(c) != 0:
			return "Cell %s uses an alternative tile. Paint unrotated, default tiles only." % c
	return ""


# --- refresh (coalesced: painting fires many change events) ------------------
func _queue_refresh() -> void:
	if _refresh_queued or not Engine.is_editor_hint() or not is_inside_tree():
		return
	_refresh_queued = true
	_refresh.call_deferred()


func _refresh() -> void:
	_refresh_queued = false
	update_configuration_warnings()
	_update_pivot_marker()
	_rebuild_preview()


func _update_pivot_marker() -> void:
	if tile_set == null:
		return
	var marker := _get_marker(self, MARKER_NAME, true)
	# Cell centers sit at even pivot, shared corners at odd pivot
	marker.position = Vector2(pivot + Vector2i.ONE) * Vector2(tile_set.tile_size) * 0.5


# --- preview: the four orientations, to the right of the painting ------------
func _rebuild_preview() -> void:
	var preview := _get_preview()
	preview.clear()
	for r in 4:
		_get_marker(preview, "Pivot%d" % r, false).visible = false
	if _validate() != "":
		return

	var piece := _build_piece()
	var tile := Vector2(tile_set.tile_size)

	# Bounds over all four orientations, so the slots never overlap
	var lo := Vector2i.MAX
	var hi := Vector2i.MIN
	for r in 4:
		for c in piece.get_cells(r):
			lo = lo.min(c)
			hi = hi.max(c)

	var rect := get_used_rect()
	var spacing := hi.x - lo.x + 2 # one empty column between orientations
	var start := Vector2i(rect.end.x + 2, rect.position.y) - lo

	for r in 4:
		var cells := piece.get_cells(r)
		var blocks := piece.get_blocks(r)
		var origin := start + Vector2i(r * spacing, 0) # cell where the anchor lands
		for i in cells.size():
			Piece.paint(preview, origin + cells[i], blocks[i])

		var marker := _get_marker(preview, "Pivot%d" % r, false)
		marker.visible = true
		marker.position = (
			Vector2(origin) + (Vector2(piece.get_anchored_pivot()) + Vector2.ONE) * 0.5
		) * tile


# What you see in the preview is what the game gets: it uses the real Piece code
func _build_piece() -> Piece:
	var piece := Piece.new()
	piece.pattern = get_pattern(get_used_cells())
	piece.pivot = pivot - get_used_rect().position * 2
	piece.weight = weight
	piece.setup()
	return piece


func _get_preview() -> TileMapLayer:
	var preview := get_node_or_null(PREVIEW_NAME) as TileMapLayer
	if preview == null:
		preview = TileMapLayer.new()
		preview.name = PREVIEW_NAME
		add_child(preview) # no owner: never saved into the scene
	preview.tile_set = tile_set
	return preview


## persist = true saves the marker in the scene, false keeps it editor-only
func _get_marker(parent: Node, marker_name: String, persist: bool) -> Marker2D:
	var marker := parent.get_node_or_null(marker_name) as Marker2D
	if marker == null:
		marker = Marker2D.new()
		marker.name = marker_name
		marker.gizmo_extents = 6.0 # default covers a whole 16 px tile
		parent.add_child(marker)
		if persist:
			marker.owner = get_tree().edited_scene_root
	return marker


# --- actions -----------------------------------------------------------------
func _load_piece() -> void:
	if piece_to_edit == null:
		push_warning("Drop a Piece resource into 'piece_to_edit' first.")
		return
	clear()
	set_pattern(Vector2i.ZERO, piece_to_edit.pattern) # patterns start at (0,0)
	pivot = piece_to_edit.pivot
	weight = piece_to_edit.weight
	piece_name = piece_to_edit.resource_path.get_file().get_basename()
	save_dir = piece_to_edit.resource_path.get_base_dir()
	_queue_refresh()


func _save_piece() -> void:
	var problem := _validate()
	if problem != "":
		push_error("Not saved: " + problem)
		return
	if piece_name.is_empty():
		push_error("Not saved: piece_name is empty.")
		return

	DirAccess.make_dir_recursive_absolute(save_dir)
	var path := save_dir.path_join(piece_name + ".tres")

	# Update in place, so fields you set by hand in the .tres survive
	var piece: Piece = null
	if ResourceLoader.exists(path):
		piece = load(path) as Piece
	var created := piece == null
	if created:
		piece = Piece.new()
		piece.take_over_path(path)

	piece.pattern = get_pattern(get_used_cells())
	piece.pivot = pivot - get_used_rect().position * 2
	piece.weight = weight

	var err := ResourceSaver.save(piece, path)
	if err != OK:
		push_error("Could not save %s (error %d)" % [path, err])
		return
	piece.emit_changed()
	EditorInterface.get_resource_filesystem().update_file(path)
	print("%s %s (%d cells)" % ["Created" if created else "Updated", path, get_used_cells().size()])


func _clear_all() -> void:
	clear()
	piece_to_edit = null
	piece_name = ""
	weight = 1.0
	pivot = Vector2i.ZERO
	_queue_refresh()
