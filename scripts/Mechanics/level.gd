extends Node2D

@export var boulder_splash : PackedScene

@onready var floors = $Floors as TileMapLayer
@onready var walls = $Walls as TileMapLayer
@onready var objects = $Objects as TileMapLayer
@onready var turn_queue: Array[GridEntity]
@onready var entity_positions = {}
var ready_for_next_turn = true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_tree().call_group("GridEntity", "initialize", floors, walls, objects, entity_positions)
	for entity in get_tree().get_nodes_in_group("GridEntity"):
		turn_queue.push_front(entity)
		entity.opened_door.connect(_open_door)
		entity.pushed_object.connect(_push_tile)
		entity.turn_ended.connect(_entity_finished_turn)
	process_turn()

#func _process(delta: float) -> void:
	#if ready_for_next_turn:
		#ready_for_next_turn = false
		#process_turn()


func process_turn():
	if turn_queue.size() <= 0:
		for entity in get_tree().get_nodes_in_group("GridEntity"):
			turn_queue.push_front(entity)
	var current_entity = turn_queue.pop_front()
	current_entity.take_turn()
	#await current_entity.turn_ended


func _entity_finished_turn():
	#ready_for_next_turn = true
	process_turn()


func _open_door(door_coords):
	objects.set_cell(door_coords, -1)
	

func _push_tile(tile_coords, direction):
	var tile = objects.get_cell_tile_data(tile_coords) as TileData
	if not tile:
		return
		
	if _is_obstructed(tile_coords + direction):
		return
	
	if floors.get_cell_tile_data(tile_coords + direction).get_custom_data("is_liquid"):
		floors.set_cell(tile_coords + direction, 2, Vector2i(0, 1) )
		var splashVFX = boulder_splash.instantiate()
		walls.add_child(splashVFX)
		splashVFX.global_position = floors.map_to_local(tile_coords + direction)
	else:
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
		
	if entity_positions.has(tile_coords):
		return true
	return false


func _on_player_turn_ended() -> void:
	for entity in get_tree().get_nodes_in_group("AI"):
		if entity.has_method("take_turn"):
			entity.take_turn()
			await entity.turn_ended
