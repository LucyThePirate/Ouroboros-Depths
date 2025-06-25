extends SkillStrategy

var max_distance = 8

@export var StarVFX: PackedScene


func ready_skill(grid_entity: GridEntity) -> bool:
	request_direction()
	if show_UI:
		$Arrows.global_position = grid_entity.global_position
		$Arrows.show()
	return false


func use_skill(grid_entity: GridEntity):
	$Arrows.hide()
	state = SkillStrategy.States.PLAYING_ANIMATION
	#print("Used skill ", name, " towards ", direction)
	var new_star_VFX = StarVFX.instantiate()
	add_child(new_star_VFX)
	new_star_VFX.initialize(direction, grid_entity)
	var grid_coords = grid_entity.floors.local_to_map(grid_entity.global_position) as Vector2i
	grid_entity.move(-direction)
	for i in range(max_distance):
		grid_coords += direction
		new_star_VFX.position += Vector2(CELL_SIZE * direction)
		await get_tree().create_timer(0.05).timeout
		if grid_entity.is_obstructed(grid_coords, false):
			break
	explode_star(grid_coords, grid_entity, direction)
	new_star_VFX.finish_flying()
	state = SkillStrategy.States.IDLE
	super(grid_entity)


func explode_star(grid_coords, grid_entity, direction):
	entity_positions = grid_entity.entity_positions

	var star_points = [
		Vector2.ZERO, Vector2(1, 0), Vector2(0, -1), Vector2(0, 1), Vector2(-1, -1), Vector2(-1, 1)
	]
	for point in star_points:
		var rotated_point = point.rotated(Vector2(direction).angle())
		var check_coords = Vector2i(round(rotated_point.x), round(rotated_point.y)) + grid_coords
		#print(
		#"checking:", check_coords, "point:", Vector2i(point.rotated(Vector2(direction).angle()))
		#)
		grid_entity.spawn_tile.emit(check_coords)
		if entity_positions.has(check_coords):
			entity_positions[check_coords]._on_hit(grid_entity)


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
