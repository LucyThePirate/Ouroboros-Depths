extends Node2D

@export var boulder_splash: PackedScene
@export var player_scene: PackedScene
@export var creature_scene: PackedScene

var root_node: Branch
var tile_size: int = 100
@onready var floors: TileMapLayer = $Floors
@onready var walls = $Walls as TileMapLayer
@onready var objects = $Objects as TileMapLayer
@onready var path_tile := [3, Vector2i(1, 3)]
@onready var room_floor_tile := [3, Vector2i(0, 3)]
@onready var stone_wall_tile := [2, Vector2i(1, 0)]
@onready var stone_floor_tile := [2, Vector2i(0, 1)]
@onready var door_horizontal_tile := [2, Vector2i(1, 2)]
@onready var door_vertical_tile := [2, Vector2i(2, 2)]
@onready var stairs_up_tile := [2, Vector2i(0, 2)]
@onready var stairs_down_tile := [2, Vector2i(0, 3)]

@onready var turn_queue: Array[TurnComponent]
@onready var entity_positions = {}
var ready_for_next_turn = true
var turn_counter = 0
var paths: Array = []


func _ready():
	root_node = Branch.new(Vector2i(0, 0), Vector2i(60, 30))
	root_node.split(4, paths)
	queue_redraw()


func _initialize_entities():
	get_tree().call_group("GridEntity", "initialize", floors, walls, objects, entity_positions)
	for entity in get_tree().get_nodes_in_group("GridEntity"):
		entity.opened_door.connect(_open_door)
		entity.pushed_object.connect(_push_tile)
		entity.spawn_tile.connect(_spawn_tile)
	for entity in get_tree().get_nodes_in_group("TurnComponent"):
		turn_queue.push_front(entity)
		entity.turn_ended.connect(_entity_finished_turn)
	process_turn()


func _draw():
	var rng = RandomNumberGenerator.new()
	spawn_entity(root_node.get_center(), player_scene)

	for leaf in root_node.get_leaves():
		if 0.5 > randf():
			spawn_entity(leaf.get_center(), creature_scene)
		var padding = Vector4i(
			rng.randi_range(0, 0),  # Left Padding
			rng.randi_range(0, 0),  # Up Padding
			rng.randi_range(1, 1),  # Right Padding
			rng.randi_range(1, 1)  # Down Padding
		)
		draw_rect(
			Rect2(
				leaf.position.x * tile_size,  # x
				leaf.position.y * tile_size,  # y
				leaf.size.x * tile_size,  # width
				leaf.size.y * tile_size  # height
			),
			Color.GREEN,  # colour
			false  # is filled
		)
		for x in range(leaf.size.x):
			for y in range(leaf.size.y):
				var tile_coordinate = Vector2i(x + leaf.position.x, y + leaf.position.y)
				if not is_inside_padding(x, y, leaf, padding):
					floors.set_cell(tile_coordinate, room_floor_tile[0], room_floor_tile[1])
				else:  # Wall
					floors.set_cell(tile_coordinate, stone_floor_tile[0], stone_floor_tile[1])
					walls.set_cell(tile_coordinate, stone_wall_tile[0], stone_wall_tile[1])
					# here Vector2i(2, 2) is where our floor is in the tileset we are using
		for path in paths:
			draw_line(path["left"] * tile_size, path["right"] * tile_size, Color.RED, 10)
			if path["left"].y == path["right"].y:
				# horizontal
				for i in range(path["right"].x - path["left"].x):
					var tile_coordinate = Vector2i(path["left"].x + i, path["left"].y)
					floors.set_cell(tile_coordinate, path_tile[0], path_tile[1])
					if walls.get_cell_tile_data(tile_coordinate):
						floors.set_cell(tile_coordinate, room_floor_tile[0], room_floor_tile[1])
						walls.set_cell(tile_coordinate, -1)

						if (
							walls.get_cell_tile_data(tile_coordinate - Vector2i(0, 1))
							and walls.get_cell_tile_data(tile_coordinate + Vector2i(0, 1))
						):
							leaf.path_intersection_count += 1
							objects.set_cell(
								tile_coordinate, door_vertical_tile[0], door_vertical_tile[1]
							)
			else:
				# vertical
				for i in range(path["right"].y - path["left"].y):
					var tile_coordinate = Vector2i(path["left"].x, path["left"].y + i)
					floors.set_cell(tile_coordinate, 3, Vector2i(2, 1))
					if walls.get_cell_tile_data(tile_coordinate):
						floors.set_cell(tile_coordinate, room_floor_tile[0], room_floor_tile[1])
						walls.set_cell(tile_coordinate, -1)

						if (
							walls.get_cell_tile_data(tile_coordinate - Vector2i(1, 0))
							and walls.get_cell_tile_data(tile_coordinate + Vector2i(1, 0))
						):
							leaf.path_intersection_count += 1
							objects.set_cell(
								tile_coordinate, door_horizontal_tile[0], door_horizontal_tile[1]
							)
	for leaf in root_node.get_leaves():
		#print("leaf path count:", leaf.path_intersection_count)
		for x in range(leaf.size.x):
			for y in range(leaf.size.y):
				var tile_coordinate = Vector2i(x + leaf.position.x, y + leaf.position.y)
				if leaf.path_intersection_count != 1:
					floors.set_cell(tile_coordinate, stone_floor_tile[0], stone_floor_tile[1])
	floors.set_cell(root_node.get_center(), stairs_up_tile[0], stairs_up_tile[1])
	_initialize_entities()


func is_inside_padding(x, y, leaf, padding):
	return (
		x <= padding.x
		or y <= padding.y
		or x >= leaf.size.x - padding.z
		or y >= leaf.size.y - padding.w
	)


func spawn_entity(grid_coordinate: Vector2i, entity_scene: PackedScene):
	var new_entity = entity_scene.instantiate()
	new_entity.global_position = floors.map_to_local(grid_coordinate)
	add_child(new_entity)
	print("Spawned %s at: %s" % [new_entity.name, grid_coordinate])


func process_turn():
	if turn_queue.size() <= 0:
		turn_counter += 1
		print(turn_counter)
		for entity in get_tree().get_nodes_in_group("TurnComponent"):
			turn_queue.push_front(entity)
	var current_entity = turn_queue.pop_front()
	if current_entity:
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

	if not floors.get_cell_tile_data(tile_coords + direction):
		objects.set_cell(tile_coords, -1)
		return

	if floors.get_cell_tile_data(tile_coords + direction).get_custom_data("is_liquid"):
		floors.set_cell(tile_coords + direction, 2, Vector2i(0, 1))
		var splashVFX = boulder_splash.instantiate()
		walls.add_child(splashVFX)
		splashVFX.global_position = floors.map_to_local(tile_coords + direction)
	else:
		objects.set_cell(
			tile_coords + direction,
			objects.get_cell_source_id(tile_coords),
			objects.get_cell_atlas_coords(tile_coords)
		)
	objects.set_cell(tile_coords, -1)


func _spawn_tile(tile_coords):
	floors.set_cell(tile_coords, 2, Vector2i(0, 1))


func _is_obstructed(tile_coords) -> bool:
	#var floor_tile = floors.get_cell_tile_data(tile_coords)
	#if not floor_tile:
	#return true

	var wall_tile = walls.get_cell_tile_data(tile_coords)
	if wall_tile and wall_tile.get_custom_data("is_solid"):
		return true

	var object_tile = objects.get_cell_tile_data(tile_coords)
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
