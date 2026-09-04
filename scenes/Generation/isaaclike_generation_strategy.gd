extends GenerationStrategy

@export var number_of_cells := 40
@export var cell_size := 4
@export var number_of_rooms := 3
@export var number_of_set_pieces := 2
@export var max_room_size := 4
@export var biggest_room_chance := 0.75
@export var set_pieces: Array[PackedScene]
@export var stairs_down_particle_scene: PackedScene
@export var seed := 0

var cells: Array[Vector2i] = []
var rooms := {}
var stairs_up_location = Vector2i.ZERO
var stairs_down_location = Vector2i.RIGHT
var stairs_down_particles: GPUParticles2D
var extra_nodes: Array = []


func initialize(
	floor_number: int, new_floor: TileMapLayer, new_wall: TileMapLayer, new_fog: TileMapLayer
):
	current_floor = floor_number
	floors = new_floor
	walls = new_wall
	fog = new_fog
	rng = RandomNumberGenerator.new()
	noise = FastNoiseLite.new()
	if Global.seed:
		rng.set_seed(Global.seed + floor_number)
	else:
		Global.set_seed(0)
		rng.set_seed(Global.seed + floor_number)
	noise.seed = rng.get_seed()
	%SeedLabel.text = "Floor: %s Seed: %s" % [floor_number, Global.seed_string]
	print_rich("[color=LIME]The seed is: %s (%s)" % [Global.seed_string, rng.seed])
	noise.fractal_octaves = 2
	noise.fractal_lacunarity = 1.575
	noise.frequency = 0.05
	noise.noise_type = 3


func generate_level():
	if stairs_down_particles:
		stairs_down_particles.queue_free()
	extra_nodes = []
	# 1. Generating an arbitrarily connecting clump of cells
	cells = [Vector2i.ZERO]
	var adjacent = [Vector2i.LEFT, Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN]
	var expandable_areas := (
		[Vector2i.LEFT, Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN] as Array[Vector2i]
	)
	while cells.size() < number_of_cells:
		var new_cell = expandable_areas.pop_at(rng.randi_range(0, expandable_areas.size() - 1))
		if not new_cell in cells:
			cells.append(new_cell)
			for a in adjacent:
				if not new_cell + a in expandable_areas:
					expandable_areas.append(new_cell + a)
	#print("Cells after 1.:", cells)

	var possible_rooms = cells.duplicate()

	# 2. Converting random cells into basic rooms
	for room_num in number_of_rooms:
		var new_room = possible_rooms.pop_at(rng.randi_range(0, possible_rooms.size() - 1))
		rooms[room_num] = [new_room]
	# 2.5 randomly join up neighboring cells into existing rooms, if possible
	for room in number_of_rooms:
		var possible_joining_rooms = []
		for a in adjacent:
			possible_joining_rooms.append(rooms[room][0] + a)
		while not possible_joining_rooms.is_empty() and rooms[room].size() < max_room_size:
			var candidate_joining_cell = possible_joining_rooms.pop_at(
				rng.randi_range(0, possible_joining_rooms.size() - 1)
			)
			if (
				not possible_rooms.has(candidate_joining_cell)
				or rooms[room].has(candidate_joining_cell)
			):
				continue
			rooms[room].append(candidate_joining_cell)
			possible_rooms.erase(candidate_joining_cell)
			if rng.randf() > biggest_room_chance:
				break
			for a in adjacent:
				if not rooms[room].has(candidate_joining_cell + a):
					possible_joining_rooms.append(candidate_joining_cell + a)

	# 3. Generate floor terrain, walls, doors, etc.
	_generate_nature_tiles(possible_rooms, expandable_areas)

	_generate_basic_rooms(expandable_areas)

	_generate_set_pieces(expandable_areas)

	_generate_border_walls()

	_generate_bogo_room(expandable_areas)

	#_debug_cover_rooms_in_trees(expandable_areas)

	_clean_up_doors()

	# 4. Generate stairs up & down
	_place_stairs()

	Global.floors = floors
	Global.walls = walls


func _generate_nature_tiles(roomy_rooms: Array[Vector2i], expandable_areas):
	for cell in roomy_rooms:
		if cell in expandable_areas:
			expandable_areas.erase(cell)
		for c_x in range(cell.x * cell_size, cell.x * cell_size + cell_size):
			for c_y in range(cell.y * cell_size, cell.y * cell_size + cell_size):
				_place_nature_tile(Vector2i(c_x, c_y))


func _debug_cover_rooms_in_trees(roomy_rooms: Array[Vector2i]):
	for cell in roomy_rooms:
		for c_x in range(cell.x * cell_size, cell.x * cell_size + cell_size):
			for c_y in range(cell.y * cell_size, cell.y * cell_size + cell_size):
				walls.set_cell(
					Vector2i(c_x, c_y), Tiles.small_tree_wall_tile[0], Tiles.small_tree_wall_tile[1]
				)


func _generate_basic_rooms(expandable_areas):
	var horizontal_doors = []
	var vertical_doors = []
	var adjacent = [Vector2i.LEFT, Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN]
	for room in number_of_rooms:
		for room_cell in rooms[room]:
			if expandable_areas.has(room_cell):
				expandable_areas.erase(room_cell)
			for r_x in range(room_cell.x * cell_size, room_cell.x * cell_size + cell_size):
				for r_y in range(room_cell.y * cell_size, room_cell.y * cell_size + cell_size):
					floors.set_cell(
						Vector2i(r_x, r_y), Tiles.wood_floor_tile[0], Tiles.wood_floor_tile[1]
					)
					#walls.set_cell(Vector2i(r_x, r_y), -1)
			for a in adjacent:
				if not rooms[room].has(a + room_cell):
					var door_orientation_horizontal = false
					var door_placement = Vector2i.ZERO
					for i in cell_size + 1:
						var wall_select = Vector2i.ZERO
						match a:
							Vector2i.LEFT:
								wall_select = Vector2i(0, i)
								door_placement = Vector2i(0, (cell_size + 1) / 2)
							Vector2i.RIGHT:
								wall_select = Vector2i(cell_size, i)
								door_placement = Vector2i(cell_size, (cell_size + 1) / 2)
							Vector2i.UP:
								wall_select = Vector2i(i, 0)
								door_orientation_horizontal = true
								door_placement = Vector2i((cell_size + 1) / 2, 0)
							Vector2i.DOWN:
								wall_select = Vector2i(i, cell_size)
								door_orientation_horizontal = true
								door_placement = Vector2i((cell_size + 1) / 2, cell_size)
						walls.set_cell(
							(
								Vector2i(room_cell.x * cell_size, room_cell.y * cell_size)
								+ wall_select
							),
							stone_wall_tile[0],
							stone_wall_tile[1]
						)
						floors.set_cell(
							(
								Vector2i(room_cell.x * cell_size, room_cell.y * cell_size)
								+ wall_select
							),
							stone_floor_tile[0],
							stone_floor_tile[1]
						)
					# Doors!!! Mark them for later so we can generate them on top of the walls
					#if cells.has(a + room_cell):
					if true:
						if door_orientation_horizontal:
							horizontal_doors.append(
								(
									Vector2i(room_cell.x * cell_size, room_cell.y * cell_size)
									+ door_placement
								)
							)
						else:
							vertical_doors.append(
								(
									Vector2i(room_cell.x * cell_size, room_cell.y * cell_size)
									+ door_placement
								)
							)

	# 3.1 Place the doors!
	for h_d: Vector2i in horizontal_doors:
		walls.set_cell(h_d, door_horizontal_tile[0], door_horizontal_tile[1])
	for v_d: Vector2i in vertical_doors:
		walls.set_cell(v_d, door_vertical_tile[0], door_vertical_tile[1])


func _generate_set_pieces(possible_locations: Array[Vector2i]):
	for set_piece_num in number_of_set_pieces:
		var set_piece_scene = (
			set_pieces[rng.randi_range(0, set_pieces.size() - 1)].instantiate() as SetPiece
		)

		add_child(set_piece_scene)
		var set_piece_shape = set_piece_scene.get_cell_shape(cell_size) as Vector2i
		var set_piece_location = _find_room_for_rect(possible_locations, set_piece_shape)
		for x in set_piece_shape.x:
			for y in set_piece_shape.y:
				var remove_from_possible_rooms = Vector2i(x, y) + set_piece_location
				if possible_locations.has(remove_from_possible_rooms):
					possible_locations.erase(remove_from_possible_rooms)
				#if not cells.has(remove_from_possible_rooms):
				#cells.append(remove_from_possible_rooms)
				#for a in adjacent:
				#if not remove_from_possible_rooms + a in cells:
				#expandable_areas.append(remove_from_possible_rooms + a)
		floors.set_pattern(
			Vector2i(set_piece_location.x * cell_size, set_piece_location.y * cell_size),
			set_piece_scene.get_floor_pattern()
		)
		for x in set_piece_scene.get_set_piece_size().x:
			for y in set_piece_scene.get_set_piece_size().y:
				walls.set_cell(
					(
						Vector2i(x, y)
						+ Vector2i(
							set_piece_location.x * cell_size, set_piece_location.y * cell_size
						)
					),
					-1
				)
		walls.set_pattern(
			Vector2i(set_piece_location.x * cell_size, set_piece_location.y * cell_size),
			set_piece_scene.get_wall_pattern()
		)
		for new_node in set_piece_scene.get_non_tile_map_children() as Array[Node]:
			extra_nodes.append(new_node)
			new_node.global_position = (
				new_node.position + floors.map_to_local(set_piece_location * cell_size)
			)
			new_node.reparent(self)
		set_piece_scene.queue_free()


func _find_room_for_rect(possible_locations: Array[Vector2i], rect_size: Vector2i) -> Vector2i:
	var current_location = possible_locations[rng.randi_range(0, possible_locations.size() - 1)]
	var adjacent = [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN]
	var locations_to_check = []
	var checked_locations = []
	while true:
		if not _is_rect_obstructed(current_location, possible_locations, rect_size):
			return current_location
		for a in adjacent:
			if (
				current_location + a not in checked_locations
				and current_location + a not in locations_to_check
			):
				locations_to_check.append(current_location + a)
		checked_locations.append(current_location)
		current_location = locations_to_check[rng.randi_range(0, locations_to_check.size() - 1)]
	return current_location


func _is_rect_obstructed(
	checking_location: Vector2i, possible_locations: Array[Vector2i], rect_size: Vector2i
) -> bool:
	for x in rect_size.x:
		for y in rect_size.y:
			var cell_to_check = Vector2i(checking_location.x + x, checking_location.y + y)
			if not cells.has(cell_to_check):
				continue
			if not possible_locations.has(cell_to_check):
				return true
	return false


func _generate_border_walls():
	for cell in floors.get_used_cells():
		for neighbor_cell in floors.get_surrounding_cells(cell):
			if (
				not floors.get_cell_tile_data(neighbor_cell)
				and not walls.get_cell_tile_data(neighbor_cell)
			):
				floors.set_cell(neighbor_cell, stone_floor_tile[0], stone_floor_tile[1])
				_blend_in_with_neighboring_walls(
					neighbor_cell,
					[Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP],
					stone_wall_tile
				)
				var wall_data = walls.get_cell_tile_data(cell)
				if (
					wall_data
					and (
						wall_data.get_custom_data("is_pushable")
						or wall_data.get_custom_data("is_door")
					)
				):
					_blend_in_with_neighboring_walls(
						cell,
						[Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP],
						stone_wall_tile
					)
				#walls.set_cell(neighbor_cell, stone_wall_tile[0], stone_wall_tile[1])


func _generate_bogo_room(expandable_areas: Array[Vector2i]):
	var bogo_room = expandable_areas[rng.randi_range(0, expandable_areas.size() - 1)]
	expandable_areas.erase(bogo_room)
	for x in range(bogo_room.x * cell_size, bogo_room.x * cell_size + cell_size):
		for y in range(bogo_room.y * cell_size, bogo_room.y * cell_size + cell_size):
			floors.set_cell(Vector2i(x, y), ice_floor_tile[0], ice_floor_tile[1], 1)
			walls.set_cell(Vector2i(x, y), -1)


func _clean_up_doors():
	var horizontal_doors = walls.get_used_cells_by_id(
		Tiles.door_horizontal_tile[0], Tiles.door_horizontal_tile[1]
	)
	var vertical_doors = walls.get_used_cells_by_id(
		Tiles.door_vertical_tile[0], Tiles.door_vertical_tile[1]
	)
	for h_d in horizontal_doors:
		if _is_obstructed(h_d + Vector2i.UP) or _is_obstructed(h_d + Vector2i.DOWN):
			_blend_in_with_neighboring_walls(
				h_d, [Vector2i.LEFT, Vector2i.RIGHT], [-1, Vector2i(-1, -1)]
			)
	for v_d in vertical_doors:
		if _is_obstructed(v_d + Vector2i.LEFT) or _is_obstructed(v_d + Vector2i.RIGHT):
			_blend_in_with_neighboring_walls(
				v_d, [Vector2i.UP, Vector2i.DOWN], [-1, Vector2i(-1, -1)]
			)


func _is_obstructed(tile_coords) -> bool:
	if not tile_coords:
		return true

	var wall_tile = walls.get_cell_tile_data(tile_coords)
	if (
		wall_tile
		and wall_tile.get_custom_data("is_solid")
		and not wall_tile.get_custom_data("is_door")
	):
		return true

	return false


func _blend_in_with_neighboring_walls(
	tile_coords: Vector2i, neighbors_to_copy: Array[Vector2i], default_tile: Array
):
	if neighbors_to_copy.is_empty():
		return
	neighbors_to_copy.shuffle()
	for neighbor_wall in neighbors_to_copy:
		var wall_tile = walls.get_cell_tile_data(tile_coords + neighbor_wall)
		if wall_tile and wall_tile.get_custom_data("is_full_block"):
			walls.set_cell(
				tile_coords,
				walls.get_cell_source_id(tile_coords + neighbor_wall),
				walls.get_cell_atlas_coords(tile_coords + neighbor_wall)
			)
			return
	# Couldn't find a valid wall to copy
	walls.set_cell(tile_coords, default_tile[0], default_tile[1])


func _place_stairs():
	var possible_stair_locations = floors.get_used_cells_by_id(
		Tiles.wood_floor_tile[0], Tiles.wood_floor_tile[1]
	)
	stairs_down_location = possible_stair_locations[rng.randi_range(
		0, possible_stair_locations.size() - 1
	)]
	floors.set_cell(stairs_down_location, stairs_down_tile[0], stairs_down_tile[1])
	if current_floor > 0:
		walls.set_cell(stairs_down_location, Tiles.lock_tile[0], Tiles.lock_tile[1])
	stairs_down_particles = stairs_down_particle_scene.instantiate()
	get_tree().current_scene.add_child(stairs_down_particles)
	stairs_down_particles.global_position = floors.map_to_local(stairs_down_location)

	possible_stair_locations = floors.get_used_cells_by_id(
		Tiles.wood_floor_tile[0], Tiles.wood_floor_tile[1]
	)
	stairs_up_location = possible_stair_locations[rng.randi_range(
		0, possible_stair_locations.size() - 1
	)]
	floors.set_cell(stairs_up_location, stairs_up_tile[0], stairs_up_tile[1])
	walls.set_cell(stairs_up_location, -1)
	print_rich(
		"[color=LIME]Stairs up: %s\nStairs down: %s" % [stairs_up_location, stairs_down_location]
	)


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
