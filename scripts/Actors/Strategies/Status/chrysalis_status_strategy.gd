extends StatusStrategy


func on_moved(_old_coords: Vector2i, _new_coords: Vector2i):
	power = 0
	_update_visuals()
	on_status_ended()


func on_turn_ended():
	increase_power()


func modify_incoming_damage(incoming_damage := 1) -> int:
	if incoming_damage > 0:
		power = 0
		_update_visuals()
		on_status_ended()
		return incoming_damage * 2
	return super()


func merge_status(status: StatusStrategy):
	pass


func _on_max_power_reached() -> void:
	call_deferred("on_status_ended")
