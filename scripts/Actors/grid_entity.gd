extends Node2D

class_name GridEntity

signal grid_entity_initialized()
signal opened_door(cell_coord)
signal pushed_object(object_coord, direction)
signal hit()
signal died()
signal turn_ended()
signal turn_started()

@onready var thump_sound = $Thump
@onready var glass_thump_sound = $GlassThump
@onready var plant_thump_sound = $PlantThump

@onready var step_sound = $Step
@onready var grass_step_sound = $GrassStep
@onready var water_step_sound = $WaterStep

const CELL_SIZE = 100
var initialized = false
var my_turn = false
var grid : TileMap

var floors : TileMapLayer
var walls : TileMapLayer
var objects : TileMapLayer
var entity_positions : Dictionary

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


func initialize(newFloors : TileMapLayer, newWalls : TileMapLayer, newObjects : TileMapLayer, newPositions : Dictionary):
	if initialized:
		return
	floors = newFloors
	walls = newWalls
	objects = newObjects
	entity_positions = newPositions
		# Snap to grid
	global_position = floors.map_to_local(floors.local_to_map(global_position))
	initialized = true
	grid_entity_initialized.emit()


func move(direction : Vector2i) -> bool:
	if not initialized:
		return false
	
	var grid_coords = floors.local_to_map(global_position) + direction
	var floor_data = floors.get_cell_tile_data(grid_coords)
	
	if not floor_data:
		return false
		
	# Test for other bodies
	if entity_positions.has(grid_coords):
		if (entity_positions[grid_coords].has_method("_on_hit")):
			entity_positions[grid_coords]._on_hit(self)
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
	entity_positions[grid_coords] = self
	entity_positions.erase(floors.local_to_map(global_position))
	global_position += Vector2(direction) * CELL_SIZE
	play_walk_sound(floor_data.get_custom_data("material"))
	return true


func get_valid_moves() -> Array:
	var move_options = []
	if not initialized:
		return move_options
	for direction in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
		
		var grid_coords = floors.local_to_map(global_position) + direction
		var floor_data = floors.get_cell_tile_data(grid_coords)
	
		if not floor_data:
			continue
		
		var wall_data = walls.get_cell_tile_data(grid_coords)
		if wall_data and wall_data.get_custom_data("is_solid"):
			continue
		
		# Test for other bodies
		if entity_positions.has(grid_coords):
			continue
		#var space_state = get_world_2d().direct_space_state
		#var query = PhysicsRayQueryParameters2D.create(global_position, global_position + Vector2(direction) * CELL_SIZE)
		#query.exclude = [self]
		#
		#var result = space_state.intersect_ray(query)
		#if result and result.collider.is_in_group("GridEntity"):
			#continue
		
		# Nothing blocking movement in this direction.
		move_options.append(direction)
	return move_options


func _on_hit(attacker):
	print(self.name, "was hit by:", attacker.name)
	if (self == attacker):
		$Error.play()
	else:
		do_death()
	

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


func take_turn():
	my_turn = true
	turn_started.emit()


func end_turn():
	my_turn = false
	#$Camera2D.make_current()
	if Debug.slowdown_enabled:
		await get_tree().create_timer(.25).timeout
	turn_ended.emit()
	

func do_death() -> void:
	entity_positions.erase(floors.local_to_map(global_position))
	died.emit()
