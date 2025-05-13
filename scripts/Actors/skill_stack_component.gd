extends Node2D

class_name SkillStackComponent

signal used_skill
signal queued_skill
signal emptied_stack
signal awaited_directional_input
signal awaited_cursor_input

@onready
var skill_icon_holder = $CanvasLayer/AvailableSkills/MarginContainer/CenterContainer/HBoxContainer
@onready var stack_icon_holder = $Stack/MarginContainer/CenterContainer/HBoxContainer

var skills = []
var stack = []
var current_skill: SkillStrategy
enum States { IDLE, DEAD, EXECUTING_STACK, AWAITING_DIRECTIONAL_INPUT, AWAITING_CURSOR_INPUT }
var state = States.IDLE


func _ready() -> void:
	skills = Debug.find_children_in_group(self, "Skill", false)
	_update_skill_visuals()


func _update_stack_visuals() -> void:
	for texture_panel in stack_icon_holder.get_children():
		texture_panel.texture = null
	for stack_item in range(stack.size()):
		stack_icon_holder.get_child(stack_item).texture = stack[stack_item].icon.texture


func _update_skill_visuals() -> void:
	for skill in range(skills.size()):
		skill_icon_holder.get_child(skill).texture = skills[skill].icon.texture


func queue_skill(skill_number) -> bool:
	if skills.size() >= skill_number + 1 and stack.size() < 4:
		$Stack.show()
		print(name, " queued skill: ", skills[skill_number].name)
		stack.append(skills[skill_number])
		_update_stack_visuals()
		return true
	$Error.play()
	return false


func execute_stack(grid_entity: GridEntity) -> bool:
	if stack.is_empty():
		return false
	state = States.EXECUTING_STACK
	_handle_stack_execution(grid_entity)
	return true


func _handle_stack_execution(grid_entity: GridEntity):
	_update_stack_visuals()
	if stack.is_empty():
		state = States.IDLE
		emptied_stack.emit()
		return
	current_skill = stack.pop_front() as SkillStrategy
	$Stack/MarginContainer/CenterContainer/HBoxContainer/TextureRect/ColorRect.show()
	if current_skill.ready_skill(grid_entity):
		await get_tree().create_timer(0.1).timeout
		_handle_stack_execution(grid_entity)

	elif current_skill.state == SkillStrategy.States.AWAITING_DIRECTION:
		state = States.AWAITING_DIRECTIONAL_INPUT
		awaited_directional_input.emit()

	elif current_skill.state == SkillStrategy.States.AWAITING_CURSOR:
		state = States.AWAITING_CURSOR_INPUT
		awaited_cursor_input.emit()


func set_direction(moveDirection: Vector2i, grid_entity: GridEntity):
	current_skill.set_direction(moveDirection)
	current_skill.use_skill(grid_entity)
	state = States.EXECUTING_STACK
	_handle_stack_execution(grid_entity)


func _on_emptied_stack() -> void:
	$Stack.hide()
	$Stack/MarginContainer/CenterContainer/HBoxContainer/TextureRect/ColorRect.hide()
