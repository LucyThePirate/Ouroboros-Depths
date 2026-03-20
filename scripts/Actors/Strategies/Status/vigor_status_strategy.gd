extends StatusStrategy

class_name VigorStatus

var used_effect := false


func _ready() -> void:
	super()


func merge_status(status: StatusStrategy):
	super(status)


func modify_outgoing_damage(outgoing_damage := 1) -> int:
	outgoing_damage += power
	used_effect = true
	return outgoing_damage


func on_turn_ended():
	if used_effect:
		power = 0
	super()


func on_status_ended():
	if status_ID == Status_IDs.NONE:
		return
	status_ID = Status_IDs.NONE
	hide()
	super()


func on_grid_entity_parent_set(grid_entity: GridEntity):
	%RemoteTransform2D.remote_path = grid_entity.get_path()
