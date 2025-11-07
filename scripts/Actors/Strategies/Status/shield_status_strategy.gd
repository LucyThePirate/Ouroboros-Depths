extends StatusStrategy

class_name ShieldStatus

@export var text_scene: PackedScene


func _ready() -> void:
	$ShieldAdded.play()
	super()


func merge_status(status: StatusStrategy):
	$ShieldAdded.play()
	super(status)


func on_turn_ended():
	pass


func modify_incoming_damage(incoming_damage := 1) -> int:
	incoming_damage -= power
	if incoming_damage < 0:
		var new_text_scene = text_scene.instantiate()
		get_tree().current_scene.add_child(new_text_scene)
		new_text_scene.global_position = global_position
		new_text_scene.add_damage_shield(power - abs(incoming_damage))
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


func on_reload_started():
	power = floor(power / 2)
	_update_visuals()
	if power <= 0:
		on_status_ended()


func on_status_ended():
	if status_ID == Status_IDs.NONE:
		return
	status_ID = Status_IDs.NONE
	hide()
	$ShieldBreak.play()
	await $ShieldBreak.finished
	super()
