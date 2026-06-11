extends StatusStrategy

var grid_entity: GridEntity
var used_effect_this_turn := false


func on_moved(_old_coord: Vector2i, _new_coord: Vector2i):
	if used_effect_this_turn:
		return
	used_effect_this_turn = true
	var direction = _new_coord - _old_coord
	grid_entity.move(direction, false, true)


func on_grid_entity_parent_set(_grid_entity: GridEntity):
	grid_entity = _grid_entity


func on_turn_ended():
	used_effect_this_turn = false
