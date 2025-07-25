extends Panel

class_name StatusStrategy

signal status_ended(StatusStrategy)
signal power_changed

enum Status_IDs { NONE, SHIELD }

@export var turns_afflicted := 5
@onready var current_turns_afflicted := turns_afflicted
@export var power := 1
@export var status_ID := Status_IDs.NONE

@onready var power_label = $PanelContainer/Label


func _ready() -> void:
	_update_visuals()


func merge_status(status: StatusStrategy):
	power += status.power
	_update_visuals()


func on_turn_ended():
	current_turns_afflicted -= 1
	if current_turns_afflicted <= 0:
		on_status_ended()


func on_status_ended():
	status_ended.emit(self)


func on_moved():
	pass


func modify_damage(incoming_damage := 1) -> int:
	return incoming_damage


func _update_visuals() -> void:
	power_label.text = str(power)
