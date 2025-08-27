extends Control

class_name StatusManagerComponent

@onready var status_bar = $StatusBar

var grid_entity: GridEntity
var turn_component: TurnComponent


func _ready() -> void:
	grid_entity = get_parent().get_parent()
	if grid_entity is GridEntity:
		grid_entity.moved.connect(on_grid_entity_moved)
		grid_entity.reload_started.connect(on_reload_started)
	for status in Debug.find_children_in_group(self, "Status") as Array[StatusStrategy]:
		status.reparent(status_bar)
		initialize_status(status)


func initialize_status(status: StatusStrategy):
	status.status_ended.connect(on_status_ended)


func add_status(new_status: StatusStrategy):
	for status in status_bar.get_children() as Array[StatusStrategy]:
		if new_status.status_ID == status.status_ID:
			# Existing status of the same type, merge 'em together
			status.merge_status(new_status)
			new_status.queue_free()
			return
	new_status.reparent(status_bar)
	initialize_status(new_status)


func on_turn_ended():
	for status in status_bar.get_children() as Array[StatusStrategy]:
		status.on_turn_ended()


func on_status_ended(status: StatusStrategy):
	print("Status ended: ", status.name)
	status.queue_free()


func on_grid_entity_moved(old_coord: Vector2i, new_coord: Vector2i):
	for status in status_bar.get_children() as Array[StatusStrategy]:
		status.on_moved()


func on_reload_started():
	for status in status_bar.get_children() as Array[StatusStrategy]:
		status.on_reload_started()


func modify_damage(incoming_damage := 1) -> int:
	for status in status_bar.get_children() as Array[StatusStrategy]:
		incoming_damage = status.modify_damage(incoming_damage)
	return incoming_damage


func get_status_descriptions():
	var descriptions := []
	for status in status_bar.get_children() as Array[StatusStrategy]:
		var new_desc = {
			"Name": status.status_name,
			"Desc": status.status_desc,
			"Icon": status.icon.texture,
			"Power": status.power
		}
		descriptions.append(new_desc)
	return descriptions
