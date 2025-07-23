extends Node2D

class_name StatusManagerComponent

var grid_entity: GridEntity
var turn_component: TurnComponent
var active_statuses: Array[Node] = []


func _ready() -> void:
	for status in Debug.find_children_in_group(self, "Status") as Array[StatusStrategy]:
		add_status(status)


func add_status(status: StatusStrategy):
	active_statuses.append(status)
	status.status_ended.connect(on_status_ended)


func on_turn_ended():
	for status in active_statuses as Array[StatusStrategy]:
		status.on_turn_ended()


func on_status_ended(status: StatusStrategy):
	print("Status ended: ", status.name)
	active_statuses.remove_at(active_statuses.find(status))
	status.queue_free()


func modify_damage(incoming_damage := 1) -> int:
	for status in active_statuses as Array[StatusStrategy]:
		incoming_damage = status.modify_damage(incoming_damage)
	return incoming_damage
