extends Node2D

var bounds = Vector2i(50, 50)
var timer: float

@onready var tile_map: TileMap = $TileMap

const SLIDE_CHECK = [Vector2i(-1, 1), Vector2i(1, 1)]

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	timer += delta
	if timer > 0.2:
		timer = 0
		var all_tiles = tile_map.get_used_cells(0) + tile_map.get_used_cells(1)
		for cell in tile_map.get_used_cells(0):
			# this is really bad
			if !Vector2i(cell.x, cell.y + 1) in all_tiles:
				tile_map.set_cell(0, Vector2i(cell.x, cell.y + 1), 0, Vector2i.ZERO)
				tile_map.erase_cell(0, cell)
			else:
				for pos in SLIDE_CHECK:
					if !cell + pos in all_tiles:
						tile_map.set_cell(0, cell + pos, 0, Vector2i(0, 0))
						tile_map.erase_cell(0, cell)
					break
	
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var mouse_pos = tile_map.local_to_map(get_local_mouse_position() / tile_map.scale)
		tile_map.set_cell(0, mouse_pos, 0, Vector2i.ZERO)
	elif Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		var mouse_pos = tile_map.local_to_map(get_local_mouse_position() / tile_map.scale)
		tile_map.erase_cell(0, mouse_pos)
				
