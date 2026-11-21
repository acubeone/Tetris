class_name Block
extends RefCounted

## 90° clockwise steps
const ROTATION_FLAGS := [
	0,
	TileSetAtlasSource.TRANSFORM_FLIP_H | TileSetAtlasSource.TRANSFORM_TRANSPOSE,
	TileSetAtlasSource.TRANSFORM_FLIP_H | TileSetAtlasSource.TRANSFORM_FLIP_V,
	TileSetAtlasSource.TRANSFORM_FLIP_V | TileSetAtlasSource.TRANSFORM_TRANSPOSE,
]


## Bitlayout:
## source(12) | atlas.x(8) | atlas.y(8) | rotation (4)
static func pack(source_id: int, atlas: Vector2i, rotation: int) -> int:
	return (source_id << 20) | (atlas.x << 12) | (atlas.y << 4) | posmod(rotation, 4)


static func paint(layer: TileMapLayer, pos: Vector2i, block: int) -> void:
	var atlas_x := (block >> 12) & 0xff
	var atlas_y := (block >> 4) & 0xff
	var source_id := (block >> 20) & 0x0fff
	var rotation := block & 0x03
	layer.set_cell(pos, source_id, Vector2i(atlas_x, atlas_y), ROTATION_FLAGS[rotation])
