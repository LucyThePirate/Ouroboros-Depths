extends SkillStrategy

var max_distance = 8

@export var note_VFX: PackedScene


func ready_skill(grid_entity: GridEntity) -> bool:
	request_direction()
	return false


func use_skill(grid_entity: GridEntity):
	var hitting_entities = []
	var distance_traveled = max_distance
	state = SkillStrategy.States.PLAYING_ANIMATION
	if direction:
		%ShootSFX.play()
		for i in range(max_distance):
			var check_coords = grid_entity.grid_coords + (direction * (i + 1))

			var new_note_VFX = note_VFX.instantiate()
			get_tree().current_scene.add_child(new_note_VFX)
			new_note_VFX.global_position = Global.floors.map_to_local(check_coords)

			if (
				Global.entity_positions.has(check_coords)
				and is_instance_valid(Global.entity_positions[check_coords])
			):
				hitting_entities.append(Global.entity_positions[check_coords])
			if Tiles.is_obstructed(check_coords):
				distance_traveled = i
				break
		for target in hitting_entities:
			grid_entity.hit(target)
			for j in range(distance_traveled):
				if not target.move(direction):
					grid_entity.hit(target)
					break
	await get_tree().create_timer(0.025).timeout
	state = SkillStrategy.States.IDLE
	super(grid_entity)
