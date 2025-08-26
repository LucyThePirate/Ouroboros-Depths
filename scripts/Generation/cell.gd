extends Node2D

@export_file("*.tscn") var title_scene

@export var boulder_splash: PackedScene
@export var spawn_smoke_scene: PackedScene
@export var player_scene: PackedScene
@export var creature_scene: Array[PackedScene]

@export var generation_size: Vector2i
@export var spawn_creatures := true
@export var tutorial_level := false

#region Fog
@onready var fog = $Fog
#endregion

#region Terrain generation and Tiles
var root_node: Branch
var tile_size: int = 100
@onready var floors: TileMapLayer = $Floors
@onready var walls = $Walls as TileMapLayer
@onready var path_tile := [3, Vector2i(1, 3)]
@onready var room_floor_tile := [3, Vector2i(0, 3)]
@onready var glass_wall_tile := [2, Vector2i(3, 0)]
@onready var stone_wall_tile := [2, Vector2i(1, 0)]
@onready var boulder_object_tile := [2, Vector2i(3, 2)]
@onready var tall_tree_wall_tile := [3, Vector2i(3, 2)]
@onready var small_tree_wall_tile := [3, Vector2i(2, 3)]
@onready var clover_decor_tile := [3, Vector2i(3, 1)]
@onready var grass_floor_tile := [3, Vector2i(1, 3)]
@onready var stone_floor_tile := [2, Vector2i(0, 1)]
@onready var water_floor_tile := [3, Vector2i(0, 0)]
@onready var lilly_decor_tile := [3, Vector2i(3, 0)]
@onready var ice_floor_tile := [3, Vector2i(2, 1)]
@onready var door_horizontal_tile := [2, Vector2i(1, 2)]
@onready var door_vertical_tile := [2, Vector2i(2, 2)]
@onready var stairs_up_tile := [2, Vector2i(0, 2)]
@onready var stairs_down_tile := [2, Vector2i(0, 3)]
@onready var fog_tile := [3, Vector2i(1, 1)]

var paths: Array = []
var noise
var rng
#endregion

@onready var turn_queue: Array[TurnComponent]
var ready_for_next_turn = true
var turn_counter = 0
var current_floor := 0
var player


func _ready():
	$CanvasLayer/DeathScreen.hide()
#region Setting up RNG and dungeon generation
	if (
		$Floors.get_used_cells().size() > 0
		and $Floors.get_used_cells_by_id(stairs_up_tile[0], stairs_up_tile[1])
	):
		# There already is a level, no need to generate
		Global.floors = floors
		Global.walls = walls
		player = (
			spawn_entity(
				$Floors.get_used_cells_by_id(stairs_up_tile[0], stairs_up_tile[1])[0], player_scene
			)
			as Player
		)
		_initialize_entities()
		return
	rng = RandomNumberGenerator.new()
	noise = FastNoiseLite.new()
	noise.seed = rng.get_seed()
	noise.fractal_octaves = 2
	noise.fractal_lacunarity = 1.575
	noise.frequency = 0.05
	noise.noise_type = 3
	root_node = Branch.new(Vector2i(0, 0), generation_size)
	root_node.split(3, paths)
	generate_level()


func _redraw_map():
	current_floor += 1
	$CanvasLayer/ColorRect/FloorLabel.text = "Floor: %s" % current_floor
	$AnimationPlayer.play("floor_text")
	for entity in get_tree().get_nodes_in_group("GridEntity") as Array[GridEntity]:
		if not entity.is_in_group("Player"):
			entity.on_death()
	Global.floors.clear()
	Global.walls.clear()
	_update_fog(Vector2i.ZERO, Global.floors.local_to_map(player.grid_entity.global_position))
	_ready()


#endregion


func _initialize_entities():
	for entity in get_tree().get_nodes_in_group("GridEntity"):
		_initialize_entity(entity)
	process_turn()


func _initialize_entity(new_entity: GridEntity):
	new_entity.opened_door.connect(_open_door)
	new_entity.pushed_object.connect(_push_tile)
	new_entity.spawn_tile.connect(_spawn_tile)
	turn_queue.push_back(new_entity.turn_component)
	new_entity.turn_component.turn_ended.connect(_entity_finished_turn)
	if not new_entity.is_in_group("Player"):
		new_entity.health_component.max_health += floori(
			new_entity.health_component.max_health * current_floor * 0.25
		)
		new_entity.health_component.health = new_entity.health_component.max_health
		new_entity.health_component._update_health_bar()
	else:
		player.grid_entity.moved.connect(_update_fog)
		player.grid_entity.died.connect(_on_player_died)
		player.descended.connect(_redraw_map)
	new_entity.initialize()


func _update_fog(old_coords: Vector2i, new_coords: Vector2i):
	var radius = 7
	for x in range(-radius, radius):
		for y in range(-radius, radius):
			fog.set_cell(Vector2i(x, y) + new_coords, -1)


func generate_level():
	if not player:
		player = spawn_entity(root_node.get_center(), player_scene) as Player

	for leaf in root_node.get_leaves():
		if 0.5 > randf():
			spawn_entity(leaf.get_center(), creature_scene.pick_random())
		var padding = Vector4i(
			rng.randi_range(0, 0),  # Left Padding
			rng.randi_range(0, 0),  # Up Padding
			rng.randi_range(1, 1),  # Right Padding
			rng.randi_range(1, 1)  # Down Padding
		)
		#draw_rect(
		#Rect2(
		#leaf.position.x * tile_size,  # x
		#leaf.position.y * tile_size,  # y
		#leaf.size.x * tile_size,  # width
		#leaf.size.y * tile_size  # height
		#),
		#Color.GREEN,  # colour
		#false  # is filled
		#)
		for x in range(leaf.size.x):
			for y in range(leaf.size.y):
				var tile_coordinate = Vector2i(x + leaf.position.x, y + leaf.position.y)
				fog.set_cell(tile_coordinate, fog_tile[0], fog_tile[1])
				if not is_inside_padding(x, y, leaf, padding):
					floors.set_cell(tile_coordinate, room_floor_tile[0], room_floor_tile[1])
				else:  # Wall
					floors.set_cell(tile_coordinate, stone_floor_tile[0], stone_floor_tile[1])
					walls.set_cell(tile_coordinate, stone_wall_tile[0], stone_wall_tile[1])
		for path in paths:
			#draw_line(path["left"] * tile_size, path["right"] * tile_size, Color.RED, 10)
			if path["left"].y == path["right"].y:
				# horizontal
				for i in range(path["right"].x - path["left"].x):
					var tile_coordinate = Vector2i(path["left"].x + i, path["left"].y)
					if walls.get_cell_tile_data(tile_coordinate):
						floors.set_cell(tile_coordinate, room_floor_tile[0], room_floor_tile[1])
						walls.set_cell(tile_coordinate, -1)

						if (
							walls.get_cell_tile_data(tile_coordinate - Vector2i(0, 1))
							and walls.get_cell_tile_data(tile_coordinate + Vector2i(0, 1))
						):
							leaf.path_intersection_count += 1
							walls.set_cell(
								tile_coordinate, door_vertical_tile[0], door_vertical_tile[1]
							)
			else:
				# vertical
				for i in range(path["right"].y - path["left"].y):
					var tile_coordinate = Vector2i(path["left"].x, path["left"].y + i)
					if walls.get_cell_tile_data(tile_coordinate):
						floors.set_cell(tile_coordinate, room_floor_tile[0], room_floor_tile[1])
						walls.set_cell(tile_coordinate, -1)

						if (
							walls.get_cell_tile_data(tile_coordinate - Vector2i(1, 0))
							and walls.get_cell_tile_data(tile_coordinate + Vector2i(1, 0))
						):
							leaf.path_intersection_count += 1
							walls.set_cell(
								tile_coordinate, door_horizontal_tile[0], door_horizontal_tile[1]
							)
	var placed_stairs = false
	for leaf in root_node.get_leaves():
		#print("leaf path count:", leaf.path_intersection_count)
		for x in range(leaf.size.x):
			for y in range(leaf.size.y):
				var tile_coordinate = Vector2i(x + leaf.position.x, y + leaf.position.y)
				if leaf.path_intersection_count != 1:  # Place nature tiles
					_place_nature_tile(tile_coordinate)

				if leaf.path_intersection_count == 1:
					var random_tile = noise.get_noise_2dv(tile_coordinate)
					if walls.get_cell_tile_data(tile_coordinate) and random_tile < -0.15:
						if (
							walls.get_cell_tile_data(tile_coordinate).get_custom_data("is_door")
							== false
						):
							walls.set_cell(tile_coordinate, glass_wall_tile[0], glass_wall_tile[1])
					if random_tile > 0.3 and rng.randf() > 0.6:
						_place_nature_tile(tile_coordinate)
			if leaf.path_intersection_count == 1 and not placed_stairs:
				var tile_coordinate = Vector2i(
					randi_range(1, leaf.size.x - 2) + leaf.position.x,
					randi_range(1, leaf.size.y - 2) + leaf.position.y
				)
				floors.set_cell(tile_coordinate, stairs_down_tile[0], stairs_down_tile[1])
				walls.set_cell(tile_coordinate, -1)
				placed_stairs = tile_coordinate
	if not placed_stairs:
		var tile_coordinate = Vector2i(
			randi_range(
				1,
				generation_size.x,
			),
			randi_range(1, generation_size.y)
		)
		floors.set_cell(tile_coordinate, stairs_down_tile[0], stairs_down_tile[1])
		walls.set_cell(tile_coordinate, -1)
		placed_stairs = tile_coordinate
	var surround_coords = [
		Vector2i(1, 0),
		Vector2i(1, 1),
		Vector2i(0, 1),
		Vector2i(-1, 1),
		Vector2i(-1, 0),
		Vector2i(-1, -1),
		Vector2i(0, -1),
		Vector2i(1, -1)
	]
	for coord in surround_coords:
		floors.set_cell(placed_stairs + coord, ice_floor_tile[0], ice_floor_tile[1])
	floors.set_cell(placed_stairs, stairs_down_tile[0], stairs_down_tile[1])
	walls.set_cell(placed_stairs, -1)
	print_rich("[color=LIME]Floor: %s, Stairs down at: %s" % [current_floor, placed_stairs])
	floors.set_cell(root_node.get_center(), stairs_up_tile[0], stairs_up_tile[1])
	walls.set_cell(root_node.get_center())
	Global.floors = floors
	Global.walls = walls
	_initialize_entities()
	_update_fog(Vector2i.ZERO, root_node.get_center())
	player.grid_entity.warp(root_node.get_center())


func _place_nature_tile(tile_coordinate: Vector2i):
	var random_tile = noise.get_noise_2dv(tile_coordinate)
	walls.set_cell(tile_coordinate, -1)
	match true:
		_ when random_tile >= 0.5:
			if rng.randf() > 0.8:
				walls.set_cell(tile_coordinate, boulder_object_tile[0], boulder_object_tile[1])
			floors.set_cell(tile_coordinate, stone_floor_tile[0], stone_floor_tile[1])
		_ when random_tile >= 0.1 && random_tile < 0.4:
			floors.set_cell(tile_coordinate, grass_floor_tile[0], grass_floor_tile[1])
			if rng.randf() > 0.9:
				walls.set_cell(tile_coordinate, small_tree_wall_tile[0], small_tree_wall_tile[1])
			elif rng.randf() > 0.7:
				walls.set_cell(tile_coordinate, tall_tree_wall_tile[0], tall_tree_wall_tile[1])
			if rng.randf() > 0.3:
				walls.set_cell(tile_coordinate, clover_decor_tile[0], clover_decor_tile[1])
		_ when random_tile >= 0 && random_tile < 0.1:
			floors.set_cell(tile_coordinate, grass_floor_tile[0], grass_floor_tile[1])
			if rng.randf() > 0.5:
				walls.set_cell(tile_coordinate, clover_decor_tile[0], clover_decor_tile[1])
		_ when random_tile < 0 && random_tile > -0.1:
			floors.set_cell(tile_coordinate, grass_floor_tile[0], grass_floor_tile[1])
		_ when random_tile <= -0.1 && random_tile > -0.15:
			floors.set_cell(tile_coordinate, stone_floor_tile[0], stone_floor_tile[1])
		_ when random_tile <= -0.15:
			floors.set_cell(tile_coordinate, water_floor_tile[0], water_floor_tile[1])
		_ when random_tile <= -0.3 && random_tile > -0.1:
			floors.set_cell(tile_coordinate, water_floor_tile[0], water_floor_tile[1])
		_ when random_tile <= -0.45 && random_tile > -0.3:
			walls.set_cell(tile_coordinate, lilly_decor_tile[0], lilly_decor_tile[1])
			floors.set_cell(tile_coordinate, water_floor_tile[0], water_floor_tile[1])
		_:
			if rng.randf() > 0.2:
				floors.set_cell(tile_coordinate, stone_floor_tile[0], stone_floor_tile[1])
			else:
				floors.set_cell(tile_coordinate, grass_floor_tile[0], grass_floor_tile[1])


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
	return new_entity


func process_turn():
	if turn_queue.size() <= 0:
		turn_counter += 1
		if spawn_creatures and (turn_counter % 5) == 0:
			try_spawning_random_monster()
		print(turn_counter)
		for turn_component in get_tree().get_nodes_in_group("TurnComponent"):
			turn_queue.push_back(turn_component)

	var current_entity = turn_queue.pop_front()
	if current_entity:
		print("Taking turn now:", current_entity.get_parent().name)
		current_entity.take_turn()
	else:
		#print("invalid entity?")
		process_turn()
	Global.turn_passed.emit()
	#await current_entity.turn_ended


func try_spawning_random_monster():
	if Global.entity_positions.size() < 10 + current_floor:
		var grid_coordinate = Global.floors.get_used_cells().pick_random()
		if not _is_obstructed(grid_coordinate):
			var new_entity = spawn_entity(grid_coordinate, creature_scene.pick_random())
			_initialize_entity(new_entity.grid_entity)
			var new_smoke = spawn_smoke_scene.instantiate()
			new_smoke.global_position = Global.floors.map_to_local(grid_coordinate)
			add_child(new_smoke)


func _entity_finished_turn():
	#ready_for_next_turn = true
	process_turn()


func _open_door(door_coords):
	walls.set_cell(door_coords, -1)


func _push_tile(tile_coords, direction):
	var tile = walls.get_cell_tile_data(tile_coords) as TileData
	if not tile:
		return

	if _is_obstructed(tile_coords + direction):
		return

	if not Global.floors.get_cell_tile_data(tile_coords + direction):
		walls.set_cell(tile_coords, -1)
		return

	if Global.floors.get_cell_tile_data(tile_coords + direction).get_custom_data("is_liquid"):
		Global.floors.set_cell(tile_coords + direction, 2, Vector2i(0, 1))
		var splashVFX = boulder_splash.instantiate()
		walls.add_child(splashVFX)
		splashVFX.global_position = Global.floors.map_to_local(tile_coords + direction)
	else:
		walls.set_cell(
			tile_coords + direction,
			walls.get_cell_source_id(tile_coords),
			walls.get_cell_atlas_coords(tile_coords)
		)
	walls.set_cell(tile_coords, -1)


func _spawn_tile(tile_coords):
	var existing_tile = Global.floors.get_cell_tile_data(tile_coords)
	if existing_tile and existing_tile.get_custom_data("indestructable"):
		return
	Global.floors.set_cell(tile_coords, 2, Vector2i(0, 1))


func _is_obstructed(tile_coords) -> bool:
	if not tile_coords:
		return true

	var wall_tile = Global.walls.get_cell_tile_data(tile_coords)
	if wall_tile and wall_tile.get_custom_data("is_solid"):
		return true

	var object_tile = Global.walls.get_cell_tile_data(tile_coords)
	if object_tile and object_tile.get_custom_data("is_solid"):
		return true

	if Global.entity_positions.has(tile_coords):
		return true
	return false


func _on_player_turn_ended() -> void:
	for entity in get_tree().get_nodes_in_group("AI"):
		if entity.has_method("take_turn"):
			entity.take_turn()
			await entity.turn_ended


func _on_player_died() -> void:
	$Fog.hide()
	$CanvasLayer/DeathScreen/VBoxContainer/FloorReached.text = ("Floor Reached: %s" % current_floor)
	$CanvasLayer/DeathScreen/VBoxContainer/Kills.text = "Kills: %s" % player.grid_entity.kills
	$CanvasLayer/DeathScreen/VBoxContainer/Turns.text = "Turns: %s" % turn_counter
	$CanvasLayer/DeathScreen.show()
	$AutoTurnTimer.start()


func _on_auto_turn_timer_timeout() -> void:
	process_turn()


func _on_new_run_button_pressed() -> void:
	get_tree().reload_current_scene()


func _on_title_screen_button_pressed() -> void:
	get_tree().change_scene_to_file(title_scene)
