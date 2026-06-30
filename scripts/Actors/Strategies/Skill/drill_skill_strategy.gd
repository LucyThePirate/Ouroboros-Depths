extends SkillStrategy

var min_distance = 1

@export var DashVFX: PackedScene
@export var vigor_status: PackedScene


func ready_skill(grid_entity: GridEntity) -> bool:
	request_direction()
	if show_UI:
		$Arrows.global_position = grid_entity.global_position
		$Arrows.show()
	return false


func use_skill(grid_entity: GridEntity):
	$Arrows.hide()
	state = SkillStrategy.States.PLAYING_ANIMATION
	print(
		"Used skill ",
		name,
		" towards ",
		direction,
		" from: ",
		Global.floors.local_to_map(grid_entity.global_position)
	)
	var successfully_moved = false
	var i = 0
	while i < min_distance:
		await get_tree().create_timer(0.025).timeout
		successfully_moved = grid_entity.move(direction)
		var check_coords = grid_entity.grid_coords + direction
		if (  # Check for grid entities to hit
			Global.entity_positions.has(check_coords)
			and is_instance_valid(Global.entity_positions[check_coords])
		):
			var target = Global.entity_positions[check_coords]
			target.move(direction)
			target._on_hit(grid_entity)

		var wall_data = Global.walls.get_cell_tile_data(check_coords)
		if (
			wall_data
			and wall_data.get_custom_data("is_solid")
			and not wall_data.get_custom_data("indestructable")
		):  # Check for walls to break
			%Break.play()
			Tiles.spawn_floor(check_coords, wall_data.get_custom_data("material"))
			Tiles.remove_wall_or_floor(check_coords)
			var new_status = vigor_status.instantiate() as StatusStrategy
			new_status.power = 1
			add_child(new_status)
			gained_status.emit(new_status)
		else:
			%Travel.play()
			i += 1
		moved_self.emit()
	if successfully_moved:
		moved_self.emit()
	state = SkillStrategy.States.IDLE
	super(grid_entity)
