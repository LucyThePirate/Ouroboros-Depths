extends Node2D

@onready var grid = $TileMap as TileMap

@onready var floors = $Floors as TileMapLayer
@onready var walls = $Walls as TileMapLayer
@onready var objects = $Objects as TileMapLayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_tree().call_group("GridEntity", "initialize", floors, walls, objects)
	for entity in get_tree().get_nodes_in_group("GridEntity"):
		entity.opened_door.connect(_open_door)
		entity.pushed_object.connect(_push_tile)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _open_door(door_coords):
	objects.set_cell(door_coords, -1)
	

func _push_tile(tile_coords, direction):
	var tile = objects.get_cell_tile_data(tile_coords) as TileData
	if not tile:
		return
		
	if _is_obstructed(tile_coords + direction):
		return
		
	objects.set_cell(tile_coords + direction, objects.get_cell_source_id(tile_coords), objects.get_cell_atlas_coords(tile_coords) )
	objects.set_cell(tile_coords, -1)
		

func _is_obstructed(tile_coords) -> bool:
	var floor_tile = floors.get_cell_tile_data( tile_coords)
	if not floor_tile:
		return true
		
	var wall_tile = walls.get_cell_tile_data( tile_coords)
	if wall_tile and wall_tile.get_custom_data("is_solid"):
		return true
	
	var object_tile = objects.get_cell_tile_data( tile_coords)
	if object_tile and object_tile.get_custom_data("is_solid"):
		return true
	return false
