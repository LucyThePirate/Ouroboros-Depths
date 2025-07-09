extends Node2D

class_name PlannerStrategy

signal awaited_directional_input
signal awaited_cursor_input

var stack_component: SkillStackComponent


func set_stack_component(new_stack_component: SkillStackComponent):
	stack_component = new_stack_component
	stack_component.connect("awaited_directional_input", _on_requested_directional_input)
	stack_component.connect("awaited_cursor_input", _on_requested_cursor_input)


func queue_random_skill() -> bool:
	if stack_component.skills.size() < 1:
		return false
	var random_skill = randi() % stack_component.skills.size()
	return stack_component.queue_skill(random_skill)


func make_plan(entity: GridEntity) -> String:
	if stack_component.is_full():
		return "Execute Stack"
	else:
		var random_skill = randi() % stack_component.skills.size()
		if stack_component.can_queue_skill(random_skill):
			return "Queue Skill"
		else:
			if stack_component.can_execute_stack():
				return "Execute Stack"
			else:
				return ""


func perform_plan(plan: String) -> bool:
	match plan:
		"Execute Stack":
			return stack_component.execute_stack()
		"Queue Skill":
			return queue_random_skill()
		_:
			return false


func _on_requested_directional_input():
	awaited_directional_input.emit()


func set_direction(move_direction: Vector2i):
	stack_component.set_direction(move_direction)


func _on_requested_cursor_input():
	awaited_cursor_input.emit()


func set_cursor(move_direction: Vector2i):
	move_direction *= Vector2i(randi_range(2, 5), randi_range(2, 5))
	stack_component.move_cursor(move_direction)
	stack_component.accept_cursor()
