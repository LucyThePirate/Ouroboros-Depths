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
		grid_entity.descended.connect(on_next_floor_reached)
		grid_entity.started_stack_execution.connect(on_stack_execution_started)
		grid_entity.finished_stack_execution.connect(on_stack_execution_finished)
		grid_entity.hurt.connect(on_hit_by_grid_entity)
		grid_entity.died.connect(on_grid_entity_died)
	for status in Debug.find_children_in_group(self, "Status") as Array[StatusStrategy]:
		status.healed.connect(_on_status_healed)
		status.harmed.connect(_on_status_harmed)
		status.reparent(status_bar)
		initialize_status(status)
		status.on_grid_entity_parent_set(grid_entity)


func has_status(status_ID: StatusStrategy.Status_IDs) -> bool:
	for status in status_bar.get_children() as Array[StatusStrategy]:
		if status.status_ID == status_ID:
			return true
	return false


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
	new_status.on_grid_entity_parent_set(grid_entity)
	initialize_status(new_status)


func on_turn_ended():
	for status in status_bar.get_children() as Array[StatusStrategy]:
		status.on_turn_ended()


func on_status_ended(status: StatusStrategy):
	print("Status ended: ", status.name)
	status.queue_free()


func on_next_floor_reached():
	for status in status_bar.get_children() as Array[StatusStrategy]:
		status.on_next_floor_reached()


func on_stack_execution_started():
	for status in status_bar.get_children() as Array[StatusStrategy]:
		status.on_stack_execution_started()


func on_stack_execution_finished():
	for status in status_bar.get_children() as Array[StatusStrategy]:
		status.on_stack_execution_finished()


func on_hit_by_grid_entity(attacker: GridEntity, damage_amount: int):
	for status in status_bar.get_children() as Array[StatusStrategy]:
		status.on_hit_by_grid_entity(attacker, damage_amount)


func on_grid_entity_moved(old_coord: Vector2i, new_coord: Vector2i):
	for status in status_bar.get_children() as Array[StatusStrategy]:
		status.on_moved(old_coord, new_coord)


func on_reload_started():
	for status in status_bar.get_children() as Array[StatusStrategy]:
		status.on_reload_started()


func modify_incoming_damage(incoming_damage := 1) -> int:
	for status in status_bar.get_children() as Array[StatusStrategy]:
		incoming_damage = status.modify_incoming_damage(incoming_damage)
	return incoming_damage


func modify_outgoing_damage(outgoing_damage := 1) -> int:
	for status in status_bar.get_children() as Array[StatusStrategy]:
		outgoing_damage = status.modify_outgoing_damage(outgoing_damage)
	return outgoing_damage


func on_grid_entity_died(is_despawning):
	for status in status_bar.get_children() as Array[StatusStrategy]:
		status.on_death(is_despawning)


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


func _on_status_healed(heal_amount := 1):
	grid_entity.heal(heal_amount)


func _on_status_harmed(damage_amount := 1):
	grid_entity.harm(damage_amount)
