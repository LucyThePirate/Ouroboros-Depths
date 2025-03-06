extends Node2D

signal grid_entity_initialized()
signal opened_door(cell_coord)
signal pushed_object(object_coord, direction)
signal hit()

@onready var thump_sound = $Thump
@onready var glass_thump_sound = $GlassThump
@onready var plant_thump_sound = $PlantThump

@onready var step_sound = $Step
@onready var grass_step_sound = $GrassStep
@onready var water_step_sound = $WaterStep

const CELL_SIZE = 100
var initialized = false
var grid : TileMap

var floors : TileMapLayer
var walls : TileMapLayer
var objects : TileMapLayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func move(direction : Vector2i) -> bool:
	if not initialized:
		return false
	
	var grid_coords = floors.local_to_map(global_position) + direction
	var floor_data = floors.get_cell_tile_data(grid_coords)
	
	if not floor_data:
		return false
	
	var wall_data = walls.get_cell_tile_data(grid_coords)
	if wall_data and wall_data.get_custom_data("is_solid"):
		play_thump_sound(wall_data.get_custom_data("material"))
		return false
	
	# Object interaction
	var object_data = objects.get_cell_tile_data(grid_coords)
	if object_data:
		play_thump_sound(object_data.get_custom_data("material"))
		if object_data.get_custom_data("is_door"):
			opened_door.emit(grid_coords)
			return false
		if object_data.get_custom_data("is_pushable"):
			pushed_object.emit(grid_coords, direction)
			return false
	
	# Movement
	global_position += Vector2(direction) * CELL_SIZE
	play_walk_sound(floor_data.get_custom_data("material"))
	return true


func initialize(newFloors : TileMapLayer, newWalls : TileMapLayer, newObjects : TileMapLayer):
	if initialized:
		return
	floors = newFloors
	walls = newWalls
	objects = newObjects
	initialized = true
	grid_entity_initialized.emit()


func _on_hit():
	hit.emit()
	

func play_walk_sound(material):
	match material:
		"grass":
			grass_step_sound.play()
		"water":
			water_step_sound.play()
		_:
			step_sound.play()
	
	
func play_thump_sound(material):
	match material:
		"stone":
			thump_sound.play()
		"glass":
			glass_thump_sound.play()
		"plant":
			plant_thump_sound.play()
		_:
			thump_sound.play()
