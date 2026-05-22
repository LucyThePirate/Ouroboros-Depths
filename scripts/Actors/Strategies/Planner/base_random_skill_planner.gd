extends Node2D

class_name PlannerStrategy

signal awaited_directional_input
signal awaited_cursor_input

var stack_component: SkillStackComponent
var is_angry_at_a_creature := false
var grid_parent: GridEntity
var temp_can_walk_through_walls := false


func set_stack_component(new_stack_component: SkillStackComponent):
	stack_component = new_stack_component
	stack_component.connect("awaited_directional_input", _on_requested_directional_input)
	stack_component.connect("awaited_cursor_input", _on_requested_cursor_input)


func queue_random_skill() -> bool:
	if stack_component.skills.size() < 1:
		return false
	#var random_skill = randi() % stack_component.skills.size()
	var chosen_skill = null
	var chosen_skill_number = 0
	var skill_number = -1
	for skill in stack_component.hand as Array[SkillStrategy]:
		skill_number += 1
		if not skill:
			continue
		if not is_appropriate_time_to_use_skill(skill):
			continue
		if not chosen_skill:
			chosen_skill = skill
			chosen_skill_number = skill_number
		elif (
			skill.priority > chosen_skill.priority and skill.current_in_stack < skill.max_per_stack
		):
			chosen_skill = skill
			chosen_skill_number = skill_number
	return stack_component.queue_skill(chosen_skill_number)


func has_queueable_skill() -> bool:
	if stack_component.hand.size() < 1:
		return false
	for skill: SkillStrategy in stack_component.hand:
		if not skill:
			continue
		if not is_appropriate_time_to_use_skill(skill):
			continue
		if skill.current_in_stack < skill.max_per_stack:
			return true
	return false


func is_appropriate_time_to_use_skill(skill: SkillStrategy) -> bool:
	if skill.when_to_use_skill == SkillStrategy.SkillUsageTypes.WHENEVER:
		return true
	if (
		is_angry_at_a_creature
		and skill.when_to_use_skill == SkillStrategy.SkillUsageTypes.COMBAT_ONLY
	):
		return true
	if (
		not is_angry_at_a_creature
		and skill.when_to_use_skill == SkillStrategy.SkillUsageTypes.OUTSIDE_COMBAT_ONLY
	):
		return true
	return false


func make_plan(grid_entity: GridEntity, angry_at: GridEntity) -> String:
	grid_parent = grid_entity
	is_angry_at_a_creature = angry_at != null
	if stack_component.is_full():
		return "Execute Stack"
	else:
		if stack_component.skills.size() <= 0:
			return ""
		if has_queueable_skill():
			return "Queue Skill"
		else:
			if stack_component.can_execute_stack():
				return "Execute Stack"
			else:
				if angry_at:
					stack_component.reload_deck()
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
	if stack_component.current_skill.usable_on_walls:
		temp_can_walk_through_walls = grid_parent.can_walk_through_walls
		grid_parent.can_walk_through_walls = true
	awaited_directional_input.emit()


func set_direction(move_direction: Vector2i):
	stack_component.set_direction(move_direction)
	grid_parent.can_walk_through_walls = temp_can_walk_through_walls


func _on_requested_cursor_input():
	awaited_cursor_input.emit()


func set_cursor(move_direction: Vector2i):
	move_direction *= Vector2i(randi_range(1, 5), randi_range(1, 5))
	stack_component.move_cursor(move_direction)
	stack_component.accept_cursor()
