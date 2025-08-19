extends SkillStrategy

var max_distance = 5

@export var DashVFX: PackedScene


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
	for i in range(max_distance):
		var new_dash_VFX = DashVFX.instantiate() as GPUParticles2D
		new_dash_VFX.preprocess = (4 - i) * 0.15
		new_dash_VFX.emitting = true
		add_child(new_dash_VFX)
		new_dash_VFX.global_position = grid_entity.global_position
		await get_tree().create_timer(0.025).timeout
		successfully_moved = grid_entity.move(direction)
		var check_coords = Global.floors.local_to_map(grid_entity.global_position) + direction
		if (
			Global.entity_positions.has(check_coords)
			and is_instance_valid(Global.entity_positions[check_coords])
		):
			var target = Global.entity_positions[check_coords]
			target.move(direction)
			target._on_hit(grid_entity)
			break
		if not successfully_moved:
			break
		moved_self.emit()
	if successfully_moved:
		moved_self.emit()
	state = SkillStrategy.States.IDLE
	super(grid_entity)
