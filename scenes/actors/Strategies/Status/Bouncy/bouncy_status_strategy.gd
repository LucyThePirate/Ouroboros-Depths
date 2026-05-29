extends StatusStrategy

var grid_parent: GridEntity


func on_grid_entity_parent_set(_grid_entity: GridEntity):
	grid_parent = _grid_entity


func on_hit_by_grid_entity(attacker: GridEntity, _damage_amount := 1):
	var direction: Vector2i = grid_parent.grid_coords - attacker.grid_coords
	direction = direction.clampi(-1, 1)
	grid_parent.move(direction)


func on_turn_ended():
	pass
