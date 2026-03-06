extends StatusStrategy

class_name RegenStatus


func on_turn_ended():
	healed.emit(power)
