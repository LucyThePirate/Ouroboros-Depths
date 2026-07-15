extends SkillStrategy

var max_distance = 5

@export var DashVFX: PackedScene


func ready_skill(grid_entity: GridEntity) -> bool:
	request_direction()
	return false


func use_skill(grid_entity: GridEntity):
	state = SkillStrategy.States.PLAYING_ANIMATION
	var successfully_moved = false
	for i in range(max_distance):
		var new_dash_VFX = DashVFX.instantiate() as GPUParticles2D
		new_dash_VFX.preprocess = (4 - i) * 0.15
		new_dash_VFX.emitting = true
		add_child(new_dash_VFX)
		new_dash_VFX.global_position = grid_entity.global_position
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
	state = SkillStrategy.States.IDLE
	super(grid_entity)
