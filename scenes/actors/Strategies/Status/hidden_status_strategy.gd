extends StatusStrategy

var used_effect := false


func on_grid_entity_parent_set(grid_entity: GridEntity):
	grid_entity.turned_invisible.emit()


func modify_outgoing_damage(outgoing_damage := 1) -> int:
	if outgoing_damage > 0:
		outgoing_damage *= 2
		power = 0
		used_effect = true
	return outgoing_damage


func modify_incoming_damage(incoming_damage := 1) -> int:
	if incoming_damage > 0:
		power = 0
		used_effect = true
	return incoming_damage


func on_moved():
	power -= 1
	_update_visuals()
	if power <= 0:
		on_status_ended()


func on_turn_ended():
	if used_effect:
		power = 0
		on_status_ended()


func on_status_ended():
	if status_ID == Status_IDs.NONE:
		return
	status_ID = Status_IDs.NONE
	hide()
	super()
