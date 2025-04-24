extends MoveStrategy


func move(direction: Vector2i) -> bool:
	return false


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

		# Nothing blocking movement in this direction.
		move_options.append(direction)
	return move_options
