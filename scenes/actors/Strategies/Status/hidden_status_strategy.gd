extends StatusStrategy

@export var move_blocks := true

var used_effect := false
var executed_stack_this_turn := false


func merge_status(status: StatusStrategy):
	executed_stack_this_turn = false
	super(status)


func on_grid_entity_parent_set(grid_entity: GridEntity):
	grid_entity.turned_invisible.emit()


func on_stack_execution_started():
	executed_stack_this_turn = true


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
		if not Tiles.move_wall(old_coord, new_coord):
			power = 0
	power -= 1
	_update_visuals()
	if power <= 0:
		on_status_ended()


func on_turn_ended():
	if executed_stack_this_turn:
		on_status_ended()


func on_status_ended():
	if status_ID == Status_IDs.NONE:
		return
	used_effect = true
	status_ID = Status_IDs.NONE
	hide()
	super()
