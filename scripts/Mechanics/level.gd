extends Node2D

@onready var grid = $TileMap as TileMap

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_tree().call_group("GridEntity", "initialize", grid)
	for entity in get_tree().get_nodes_in_group("GridEntity"):
		entity.opened_door.connect(_open_door)
		entity.pushed_object.connect(_push_tile)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _open_door(door_coords):
	grid.set_cell(2, door_coords, -1)
	

func _push_tile(tile_coords, direction):
	var tile = grid.get_cell_tile_data(2, tile_coords) as TileData
	if not tile:
		return
		
	if _is_obstructed(tile_coords + direction):
		return
		
	grid.set_cell(2, tile_coords + direction, 2, Vector2i(0,2), 0)
	grid.set_cell(2, tile_coords, -1)
		

func _is_obstructed(tile_coords) -> bool:
	var floor_tile = grid.get_cell_tile_data(0, tile_coords)
	if not floor_tile:
		return true
		
	var wall_tile = grid.get_cell_tile_data(1, tile_coords)
	if wall_tile and wall_tile.get_custom_data("is_solid"):
		return true
	
	var object_tile = grid.get_cell_tile_data(2, tile_coords)
	if object_tile and object_tile.get_custom_data("is_solid"):
		return true
	return false
