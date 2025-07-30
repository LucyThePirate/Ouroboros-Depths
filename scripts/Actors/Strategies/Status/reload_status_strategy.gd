extends StatusStrategy


func on_turn_ended():
	power -= 1
	_update_visuals()
	if power <= 0:
		on_status_ended()
