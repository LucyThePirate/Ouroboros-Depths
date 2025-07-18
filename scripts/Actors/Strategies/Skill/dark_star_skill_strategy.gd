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
	var grid_coords = Global.floors.local_to_map(grid_entity.global_position) as Vector2i
	if grid_entity.move(-direction):
		moved_self.emit()
	for i in range(max_distance):
		grid_coords += direction
		new_star_VFX.position += Vector2(Global.CELL_SIZE * direction)
		await get_tree().create_timer(0.05).timeout
		if grid_entity.is_obstructed(grid_coords, false):
			break
	explode_star(grid_coords, grid_entity, direction)
	new_star_VFX.finish_flying()
	state = SkillStrategy.States.IDLE
	super(grid_entity)


func explode_star(grid_coords, grid_entity, direction):
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
		if (
			Global.entity_positions.has(check_coords)
			and is_instance_valid(Global.entity_positions[check_coords])
		):
			Global.entity_positions[check_coords]._on_hit(grid_entity)
