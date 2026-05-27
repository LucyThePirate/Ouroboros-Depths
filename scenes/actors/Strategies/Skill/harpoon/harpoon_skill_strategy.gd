extends SkillStrategy

var max_distance = 8

var target_to_pull: GridEntity


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
	# First check if there is a target to grab
	var grapple_check_coords = grid_entity.grid_coords + direction
	var grapple_distance = 0
	var max_line_points = 4
	%GrabLineVFX.clear_points()
	%AnimationPlayer.play("RESET")
	%GrabLineVFX.add_point(grid_entity.global_position)
	%ExtendLineSFX.play()
	for i in range(max_distance):
		grapple_distance += 1
		if (
			Global.entity_positions.has(grapple_check_coords)
			and is_instance_valid(Global.entity_positions[grapple_check_coords])
		):
			target_to_pull = Global.entity_positions[grapple_check_coords]
			break
		elif (
			Global.walls.get_cell_tile_data(grapple_check_coords)
			and Global.walls.get_cell_tile_data(grapple_check_coords).get_custom_data("is_solid")
		):
			break
		%GrabLineVFX.add_point(Global.floors.map_to_local(grapple_check_coords))

		if %GrabLineVFX.points.size() > max_line_points:
			%GrabLineVFX.remove_point(0)
		grapple_check_coords += direction
		await get_tree().create_timer(0.025).timeout
	%RetractLineSFX.play()
	if target_to_pull:
		for i in range(grapple_distance - 1):
			target_to_pull.move(-direction)
			%GrabLineVFX.add_point(target_to_pull.global_position)
			if %GrabLineVFX.points.size() > max_line_points:
				%GrabLineVFX.remove_point(0)
			await get_tree().create_timer(0.025).timeout
		grid_entity.hit(target_to_pull, 1)
	else:
		for i in range(max_distance):
			await get_tree().create_timer(0.025).timeout
			successfully_moved = grid_entity.move(direction)
			var check_coords = grid_entity.grid_coords + direction
			if (
				Global.entity_positions.has(check_coords)
				and is_instance_valid(Global.entity_positions[check_coords])
			):
				var target = Global.entity_positions[check_coords]
				target.move(direction)
				grid_entity.hit(target)
				break
			if not successfully_moved:
				break
			moved_self.emit()
		if successfully_moved:
			moved_self.emit()
	%AnimationPlayer.play("fade_line")
	state = SkillStrategy.States.IDLE
	target_to_pull = null
	super(grid_entity)
