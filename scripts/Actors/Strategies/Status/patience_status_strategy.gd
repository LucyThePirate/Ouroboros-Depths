extends StatusStrategy

var notes = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]

@onready var sampler = $SamplerInstrument


func on_moved(_old_coord: Vector2i, _new_coord: Vector2i):
	if _old_coord != _new_coord:
		power = max(power - 2, 0)
		_update_visuals()


func on_turn_ended():
	if increase_power() and power > 1:
		sampler.play_note(notes[power - 1], 4)
