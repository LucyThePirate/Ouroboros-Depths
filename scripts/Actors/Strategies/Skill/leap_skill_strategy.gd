extends SkillStrategy

var max_distance = 5

@export var DashVFX: PackedScene


func ready_skill(grid_entity: GridEntity) -> bool:
	request_cursor()
	if show_UI:
		$Cursor.global_position = grid_entity.global_position
		cursor = grid_entity.floors.local_to_map(grid_entity.global_position)
		$Cursor.show()
	return false


func move_cursor(moveDirection: Vector2i, grid_entity: GridEntity):
	cursor += moveDirection
	$Cursor.global_position = grid_entity.floors.map_to_local(cursor)


func use_skill(grid_entity: GridEntity) -> bool:
	$Cursor.hide()
	print("Used skill ", name, " towards ", cursor)
	moved_self.emit()
	var new_dash_VFX = DashVFX.instantiate() as GPUParticles2D
	new_dash_VFX.emitting = true
	add_child(new_dash_VFX)
	new_dash_VFX.global_position = grid_entity.global_position
	grid_entity.warp(cursor)

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
