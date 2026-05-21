extends StatusStrategy

@export var move_blocks := true

var used_effect := false


func on_grid_entity_parent_set(grid_entity: GridEntity):
	grid_entity.turned_invisible.emit()


func modify_outgoing_damage(outgoing_damage := 1) -> int:
	if outgoing_damage > 0 and not used_effect:
		outgoing_damage *= 2
		on_status_ended()
	return outgoing_damage


func modify_incoming_damage(incoming_damage := 1) -> int:
	if incoming_damage > 0 and not used_effect:
		on_status_ended()
	return incoming_damage


func on_moved(old_coord: Vector2i, new_coord: Vector2i):
	if move_blocks:
		var new_wall_data = Global.walls.get_cell_tile_data(new_coord)
		if not (new_wall_data and new_wall_data.get_custom_data("is_solid")):
			var wall_pattern = Global.walls.get_pattern([old_coord])
			Global.walls.set_pattern(new_coord, wall_pattern)
			Global.walls.set_cell(old_coord, -1)
	power -= 1
	_update_visuals()
	if power <= 0:
		on_status_ended()


func on_turn_ended():
	pass


func on_status_ended():
	if status_ID == Status_IDs.NONE:
		return
	used_effect = true
	status_ID = Status_IDs.NONE
	hide()
	super()
