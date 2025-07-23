extends StatusStrategy


func modify_damage(incoming_damage := 1) -> int:
	incoming_damage -= power
	if incoming_damage < 0:
		power = abs(incoming_damage)
		incoming_damage = 0
	else:  # Shield broken
		on_status_ended()
	return incoming_damage
