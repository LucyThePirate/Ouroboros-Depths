extends StatusStrategy

var grid_parent: GridEntity


func on_grid_entity_parent_set(grid_entity: GridEntity):
	grid_parent = grid_entity
	%RemoteTransform2D.remote_path = grid_entity.get_path()


func on_turn_ended():
	pass


#func on_moved(_old_coord: Vector2i, _new_coord: Vector2i):
#if _old_coord != _new_coord:
#grid_parent.warp(_old_coord)


func gets_bonus_turn() -> bool:
	if power >= 1:
		decrease_power()
		return true
	return false
