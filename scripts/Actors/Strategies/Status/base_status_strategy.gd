extends Panel

class_name StatusStrategy

signal status_ended(StatusStrategy)
signal power_changed
signal max_power_reached

enum Status_IDs { NONE, SHIELD, RELOAD, PATIENCE, CHRYSALIS, VIGOR }

@export_category("Lore")
@export var status_name := "Default Status Name"
@export_multiline var status_desc := "Default Status Desc"
@onready var icon := $TextureRect

@export_category("Stats")
@export var turns_afflicted := 5
@onready var current_turns_afflicted := turns_afflicted
@export var power := 1
@export var status_ID := Status_IDs.NONE
@onready var power_label = $Label as RichTextLabel
@export var max_power = 999


func _ready() -> void:
	_update_visuals()


func merge_status(status: StatusStrategy):
	power += status.power
	_update_visuals()


func increase_power(amount := 1) -> bool:
	if power >= max_power:
		return false
	power = min(max_power, power + amount)
	_update_visuals()
	if power >= max_power:
		max_power_reached.emit()
	return true


func on_turn_ended():
	current_turns_afflicted -= 1
	if current_turns_afflicted <= 0:
		on_status_ended()


func on_status_ended():
	status_ended.emit(self)


func on_moved():
	pass


func on_reload_started():
	pass


func modify_incoming_damage(incoming_damage := 1) -> int:
	return incoming_damage


func modify_outgoing_damage(outgoing_damage := 1) -> int:
	return outgoing_damage


func _update_visuals() -> void:
	if power >= max_power:
		power_label.text = (
			"[outline_color=GOLDENROD][color=YELLOW]%s[/color][/outline_color]" % str(power)
		)
	else:
		power_label.text = str(power)
