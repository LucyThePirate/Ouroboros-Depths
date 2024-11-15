extends Node2D

signal grid_entity_initialized()
signal opened_door(cell_coord)
signal pushed_object(object_coord, direction)

const CELL_SIZE = 100
var initialized = false
var grid : TileMap

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func move(direction : Vector2i) -> bool:
	if not initialized:
		return false
	
	var grid_coords = grid.local_to_map(global_position) + direction
	var floor_data = grid.get_cell_tile_data(0, grid_coords)
	
	if not floor_data:
		return false
	
	var wall_data = grid.get_cell_tile_data(1, grid_coords)
	if wall_data and wall_data.get_custom_data("is_solid"):
		return false
	
	# Object interaction
	var object_data = grid.get_cell_tile_data(2, grid_coords)
	if object_data:
		if object_data.get_custom_data("is_door"):
			opened_door.emit(grid_coords)
			return true
		if object_data.get_custom_data("is_pushable"):
			pushed_object.emit(grid_coords, direction)
			return true
	
	# Movement
	global_position += Vector2(direction) * CELL_SIZE
	return true


func initialize(newGrid : TileMap):
	if initialized:
		return
	grid = newGrid
	initialized = true
	grid_entity_initialized.emit()
