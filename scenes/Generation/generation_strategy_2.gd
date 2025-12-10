extends GenerationStrategy


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
	nature_mode = [NatureModes.SOMETIMES].pick_random()


func generate_level():
	#for x in range(-1, generation_size.x + 1):
		#floors.set_cell(Vector2i(x, generation_size.y), stone_floor_tile[0], stone_floor_tile[1])
		#walls.set_cell(Vector2i(x, generation_size.y), stone_wall_tile[0], stone_wall_tile[1])
		#floors.set_cell(Vector2i(x, -1), stone_floor_tile[0], stone_floor_tile[1])
		#walls.set_cell(Vector2i(x, -1), stone_wall_tile[0], stone_wall_tile[1])
	#for y in range(-1, generation_size.y + 1):
		#floors.set_cell(Vector2i(generation_size.x, y), stone_floor_tile[0], stone_floor_tile[1])
		#walls.set_cell(Vector2i(generation_size.x, y), stone_wall_tile[0], stone_wall_tile[1])
		#floors.set_cell(Vector2i(-1, y), stone_floor_tile[0], stone_floor_tile[1])
		#walls.set_cell(Vector2i(-1, y), stone_wall_tile[0], stone_wall_tile[1])
	for leaf in root_node.get_leaves():
		var padding = Vector4i(
			rng.randi_range(0, 0),  # Left Padding
			rng.randi_range(0, 0),  # Up Padding
			rng.randi_range(1, 1),  # Right Padding
			rng.randi_range(1, 1)  # Down Padding
		)

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
				if (
					nature_mode == NatureModes.ALL
					or (leaf.path_intersection_count != 1 and nature_mode == NatureModes.SOMETIMES)
				):  # Place nature tiles
					_place_nature_tile(tile_coordinate)

				else:
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
	print_rich("[color=LIME]Floor: %s, Stairs down at: %s" % [current_floor, placed_stairs])
	floors.set_cell(root_node.get_center(), stairs_up_tile[0], stairs_up_tile[1])
	for coord in surround_coords:
		floors.set_cell(placed_stairs + coord, ice_floor_tile[0], ice_floor_tile[1])
	walls.set_cell(placed_stairs, -1)
	floors.set_cell(placed_stairs, stairs_down_tile[0], stairs_down_tile[1])
	walls.set_cell(root_node.get_center())
	Global.floors = floors
	Global.walls = walls

	#_initialize_entities()
	#_update_fog(Vector2i.ZERO, root_node.get_center())
	#player.grid_entity.warp(root_node.get_center())
	#Global.entity_positions[root_node.get_center()] = player.grid_entity


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
