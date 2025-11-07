extends StatusStrategy

class_name VigorStatus

@export var text_scene: PackedScene


func _ready() -> void:
	super()


func merge_status(status: StatusStrategy):
	super(status)


func modify_outgoing_damage(outgoing_damage := 1) -> int:
	outgoing_damage += power
	power = 0
	_update_visuals()
	return outgoing_damage


func on_turn_ended():
	if power <= 0:
		on_status_ended()


func on_status_ended():
	if status_ID == Status_IDs.NONE:
		return
	status_ID = Status_IDs.NONE
	hide()
	super()
