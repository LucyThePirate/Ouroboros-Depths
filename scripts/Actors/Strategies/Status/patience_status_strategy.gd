extends StatusStrategy

var notes = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]

@onready var sampler = $SamplerInstrument


func on_moved():
	power = 0
	_update_visuals()


func on_turn_ended():
	if power < max_power:
		power = min(max_power, power + 1)
		sampler.play_note(notes[power - 1], 4)
		_update_visuals()
