extends Node2D

var bounds = Vector2i(50, 50)

var timer: float

@onready var tile_map: TileMap = $TileMap


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	timer += delta
	if timer > 1:
		timer = 0
		for cell in tile_map.get_used_cells(0):
			if !Vector2i(cell.x, cell.y + 1) in tile_map.get_used_cells(0):
				if !Vector2i(cell.x, cell.y + 1) in tile_map.get_used_cells(1):
					tile_map.set_cell(0, Vector2i(cell.x, cell.y + 1), 0, Vector2i(0, 0))
					tile_map.erase_cell(0, cell)
					
				
