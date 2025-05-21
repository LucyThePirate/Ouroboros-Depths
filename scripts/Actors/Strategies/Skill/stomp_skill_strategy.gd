extends SkillStrategy

var shockwave_radius = 3

@export var StompVFX: PackedScene


func use_skill(grid_entity: GridEntity) -> bool:
	print("Used skill ", name, " towards ", direction)
	entity_positions = grid_entity.entity_positions
	var new_stomp_VFX = StompVFX.instantiate()
	add_child(new_stomp_VFX)
	new_stomp_VFX.global_position = grid_entity.global_position
	var grid_coords = grid_entity.floors.local_to_map(grid_entity.global_position)
	var offset = -shockwave_radius + 1
	for i in range(shockwave_radius * 2 - 1):
		for j in range(shockwave_radius * 2 - 1):
			var checkingPosition = grid_coords + Vector2i(offset + i, offset + j)
			if entity_positions.has(checkingPosition):
				if entity_positions[checkingPosition] == grid_entity:
					continue
				entity_positions[checkingPosition]._on_hit(grid_entity)
	skill_finished.emit()
	return false
