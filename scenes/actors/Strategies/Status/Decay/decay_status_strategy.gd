extends StatusStrategy


func on_turn_ended():
	current_turns_afflicted -= 1
	if current_turns_afflicted <= 0:
		harmed.emit(power)
		current_turns_afflicted = turns_afflicted
		_update_visuals()
	if power <= 0:
		on_status_ended()
