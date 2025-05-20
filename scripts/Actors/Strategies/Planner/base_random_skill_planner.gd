extends Node2D

class_name PlannerStrategy

var stack_component: SkillStackComponent


func set_stack_component(new_stack_component: SkillStackComponent):
	stack_component = new_stack_component
	stack_component.connect("awaited_directional_input", _on_requested_directional_input)
	stack_component.connect("awaited_cursor_input", _on_requested_cursor_input)


func queue_random_skill():
	if stack_component.skills.size() < 1:
		return
	var random_skill = randi() % stack_component.skills.size()
	stack_component.queue_skill(random_skill)


func perform_plan():
	if stack_component.is_full():
		stack_component.execute_stack()
	else:
		queue_random_skill()


func _on_requested_directional_input():
	var moveDirection = (
		[Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)].pick_random()
	)
	stack_component.set_direction(moveDirection)


func _on_requested_cursor_input():
	#stack_component.set_cursor()
	var moveDirection = Vector2i(randi_range(-3, 3), randi_range(-3, 3))
	stack_component.move_cursor(moveDirection)
	stack_component.accept_cursor()
