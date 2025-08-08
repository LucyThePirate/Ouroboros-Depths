extends StatusStrategy


func on_moved():
	power = 0
	_update_visuals()
	on_status_ended()


func on_turn_ended():
	increase_power()


func modify_damage(incoming_damage := 1) -> int:
	power = 0
	_update_visuals()
	on_status_ended()
	return super()


func merge_status(status: StatusStrategy):
	pass


func _on_max_power_reached() -> void:
	call_deferred("on_status_ended")
