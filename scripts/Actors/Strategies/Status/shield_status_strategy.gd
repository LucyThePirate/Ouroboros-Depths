extends StatusStrategy

class_name ShieldStatus


func _ready() -> void:
	$ShieldAdded.play()
	super()


func merge_status(status: StatusStrategy):
	$ShieldAdded.play()
	super(status)


func modify_damage(incoming_damage := 1) -> int:
	incoming_damage -= power
	if incoming_damage < 0:
		power = abs(incoming_damage)
		_update_visuals()
		incoming_damage = 0
		$ShieldAdded.play()
	else:  # Shield broken
		power = 0
		_update_visuals()
		on_status_ended()
	return incoming_damage


func on_moved():
	power -= 1
	_update_visuals()
	if power <= 0:
		on_status_ended()


func on_status_ended():
	if status_ID == Status_IDs.NONE:
		return
	status_ID = Status_IDs.NONE
	$ShieldBreak.play()
	await $ShieldBreak.finished
	super()
