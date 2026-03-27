extends GenerationStrategy

@export var number_of_cells := 40
@export var cell_size := 5
@export var number_of_rooms := 3
@export var max_room_size := 4
@export var biggest_room_chance := 0.75

var cells: Array[Vector2i] = []
var rooms := {}
var stairs_up_location = Vector2i.ZERO
var stairs_down_location = Vector2i.ZERO


func initialize(new_floor: TileMapLayer, new_wall: TileMapLayer, new_fog: TileMapLayer):
	floors = new_floor
	walls = new_wall
	fog = new_fog
	rng = RandomNumberGenerator.new()
	noise = FastNoiseLite.new()
	noise.seed = rng.get_seed()
	noise.fractal_octaves = 2
	noise.fractal_lacunarity = 1.575
	noise.frequency = 0.05
	noise.noise_type = 3
	root_node = Branch.new(Vector2i(0, 0), generation_size)
	root_node.split(randi_range(2, 4), paths)
	nature_mode = [NatureModes.ALL, NatureModes.SOMETIMES, NatureModes.NONE].pick_random()


func generate_level():
	# 1. Generating an arbitrarily connecting clump of cells
	cells = [Vector2i.ZERO]
	var adjacent = [Vector2i.LEFT, Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN]
	var expandable_areas = [Vector2i.LEFT, Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN]
	while cells.size() < number_of_cells:
		var new_cell = expandable_areas.pop_at(randi_range(0, expandable_areas.size() - 1))
		if not new_cell in cells:
			cells.append(new_cell)
			for a in adjacent:
				if not new_cell + a in cells:
					expandable_areas.append(new_cell + a)
	#print("Cells after 1.:", cells)

	# 2. Converting random cells into rooms
	var possible_rooms = cells.duplicate()
	for room_num in number_of_rooms:
		var new_room = possible_rooms.pop_at(randi_range(0, possible_rooms.size() - 1))
		rooms[room_num] = [new_room]
	# 2.5 randomly join up neighboring cells into existing rooms, if possible
	for room in number_of_rooms:
		var possible_joining_rooms = []
		for a in adjacent:
			possible_joining_rooms.append(rooms[room][0] + a)
		while not possible_joining_rooms.is_empty() and rooms[room].size() < max_room_size:
			var candidate_joining_cell = possible_joining_rooms.pop_at(
				randi_range(0, possible_joining_rooms.size() - 1)
			)
			if (
				not possible_rooms.has(candidate_joining_cell)
				or rooms[room].has(candidate_joining_cell)
			):
				continue
			rooms[room].append(candidate_joining_cell)
			possible_rooms.remove_at(possible_rooms.find(candidate_joining_cell))
			if randf() > biggest_room_chance:
				break
			for a in adjacent:
				if not rooms[room].has(candidate_joining_cell + a):
					possible_joining_rooms.append(candidate_joining_cell + a)

	# 3. Generate floor terrain, walls, doors, etc.
	for cell in possible_rooms:
		for c_x in range(cell.x * cell_size, cell.x * cell_size + cell_size):
			for c_y in range(cell.y * cell_size, cell.y * cell_size + cell_size):
				_place_nature_tile(Vector2i(c_x, c_y))
	var horizontal_doors = []
	var vertical_doors = []
	for room in number_of_rooms:
		for room_cell in rooms[room]:
			for r_x in range(room_cell.x * cell_size, room_cell.x * cell_size + cell_size):
				for r_y in range(room_cell.y * cell_size, room_cell.y * cell_size + cell_size):
					floors.set_cell(Vector2i(r_x, r_y), room_floor_tile[0], room_floor_tile[1])
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
					if cells.has(a + room_cell):
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

	# 3.2 Smooth out the nature tiles on the borders
#	var rotated_point = point.rotated(Vector2(attack_direction).angle())
	#var chance_gradient = []
	#for i in range(cell_size):
	#chance_gradient.append(range(1, cell_size + 1))

	for cell in floors.get_used_cells():
		for neighbor_cell in floors.get_surrounding_cells(cell):
			if not floors.get_cell_tile_data(neighbor_cell):
				floors.set_cell(neighbor_cell, stone_floor_tile[0], stone_floor_tile[1])
				walls.set_cell(neighbor_cell, stone_wall_tile[0], stone_wall_tile[1])

	var bogo_room = expandable_areas.pick_random()
	for x in range(bogo_room.x * cell_size, bogo_room.x * cell_size + cell_size):
		for y in range(bogo_room.y * cell_size, bogo_room.y * cell_size + cell_size):
			floors.set_cell(Vector2i(x, y), ice_floor_tile[0], ice_floor_tile[1])
			walls.set_cell(Vector2i(x, y), -1)

	# 4. Generate stairs up & down
	var possible_stair_locations = rooms
	var stairs_down_room = possible_stair_locations.keys().pick_random()
	stairs_down_location = (
		rooms[stairs_down_room].pick_random() * cell_size + Vector2i(cell_size / 2, cell_size / 2)
	)
	floors.set_cell(stairs_down_location, stairs_down_tile[0], stairs_down_tile[1])
	assert(possible_stair_locations.erase(stairs_down_room))
	var stairs_up_room = possible_stair_locations.keys().pick_random()
	stairs_up_location = (
		rooms[stairs_up_room].pick_random() * cell_size + Vector2i(cell_size / 2, cell_size / 2)
	)
	floors.set_cell(stairs_up_location, stairs_up_tile[0], stairs_up_tile[1])

	for x in range(floors.get_used_rect().position.x - 1, floors.get_used_rect().size.x + 1):
		for y in range(floors.get_used_rect().position.y - 1, floors.get_used_rect().size.y + 1):
			fog.set_cell(Vector2i(x, y), fog_tile[0], fog_tile[1])
			pass

	fog.set_pattern(walls.get_used_rect().position, walls.get_pattern(walls.get_used_cells()))

	Global.floors = floors
	Global.walls = walls


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
