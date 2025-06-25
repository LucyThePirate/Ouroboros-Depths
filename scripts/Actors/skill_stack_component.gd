extends Node2D

class_name SkillStackComponent

signal used_skill
signal queued_skill
signal stack_full
signal emptied_stack
signal awaited_directional_input
signal awaited_cursor_input

@onready
var skill_icon_holder = $CanvasLayer/AvailableSkills/MarginContainer/CenterContainer/HBoxContainer
@onready var stack_icon_holder = $Stack/MarginContainer/CenterContainer/HBoxContainer

@export var max_stack_size = 4

var skills = []
var stack = []
var current_skill: SkillStrategy
enum States { IDLE, DEAD, EXECUTING_STACK, AWAITING_DIRECTIONAL_INPUT, AWAITING_CURSOR_INPUT }
var state = States.IDLE
var grid_entity: GridEntity
var turn_component: TurnComponent


func _ready() -> void:
	skills = Debug.find_children_in_group(self, "Skill", false)
	_update_skill_visuals()


func initialize(grid_entity_parent: GridEntity, is_player: bool, new_turn_component: TurnComponent):
	grid_entity = grid_entity_parent
	$CanvasLayer.visible = is_player
	turn_component = new_turn_component
	turn_component.turn_ended.connect(_update_turn_cooldown)


func queue_skill(skill_number) -> bool:
	if skills.size() >= skill_number + 1 and not is_full() and skills[skill_number].can_use_skill():
		skills[skill_number].increment_in_stack_counter()
		_update_cooldown_visuals()
		$Stack.show()
		#print(name, " queued skill: ", skills[skill_number].name)
		stack.append(skills[skill_number])
		_update_stack_visuals()
		if is_full():
			stack_full.emit()
		return true
		#$Error.play()
	return false


func is_full() -> bool:
	if stack.size() >= max_stack_size:
		return true
	return false


func execute_stack() -> bool:
	if stack.is_empty():
		return false
	state = States.EXECUTING_STACK
	_handle_stack_execution()
	return true


func _handle_stack_execution():
	_update_stack_visuals()
	if stack.is_empty():
		state = States.IDLE
		emptied_stack.emit()
		_update_cooldown_visuals()
		return
	current_skill = stack.pop_front() as SkillStrategy
	$Stack/MarginContainer/CenterContainer/HBoxContainer/TextureRect/ColorRect.show()
	if current_skill.ready_skill(grid_entity):
		await get_tree().create_timer(0.1).timeout
		_handle_stack_execution()

	elif current_skill.state == SkillStrategy.States.AWAITING_DIRECTION:
		state = States.AWAITING_DIRECTIONAL_INPUT
		awaited_directional_input.emit()

	elif current_skill.state == SkillStrategy.States.AWAITING_CURSOR:
		state = States.AWAITING_CURSOR_INPUT
		awaited_cursor_input.emit()


func set_direction(moveDirection: Vector2i):
	current_skill.set_direction(moveDirection)
	state = States.EXECUTING_STACK
	var finished_skill = current_skill.skill_finished
	current_skill.use_skill(grid_entity)
	if current_skill.state == SkillStrategy.States.PLAYING_ANIMATION:
		await finished_skill
	_handle_stack_execution()


func move_cursor(moveDirection: Vector2i):
	current_skill.move_cursor(moveDirection, grid_entity)


func set_cursor(cursorPosition: Vector2i):
	current_skill.set_cursor(cursorPosition)
	state = States.EXECUTING_STACK
	var finished_skill = current_skill.skill_finished
	current_skill.use_skill(grid_entity)
	if current_skill.state == SkillStrategy.States.PLAYING_ANIMATION:
		await finished_skill
	_handle_stack_execution()


func accept_cursor():
	current_skill.use_skill(grid_entity)
	state = States.EXECUTING_STACK
	_handle_stack_execution()


func _on_emptied_stack() -> void:
	$Stack.hide()
	$Stack/MarginContainer/CenterContainer/HBoxContainer/TextureRect/ColorRect.hide()


func _update_stack_visuals() -> void:
	for texture_panel in stack_icon_holder.get_children():
		texture_panel.texture = null
	for stack_item in range(stack.size()):
		stack_icon_holder.get_child(stack_item).texture = stack[stack_item].icon.texture


func _update_skill_visuals() -> void:
	for skill in range(skills.size()):
		skill_icon_holder.get_child(skill).texture = skills[skill].icon.texture


func _update_turn_cooldown():
	for skill in range(skills.size()):
		skills[skill].decrement_turn_cooldown()
	_update_cooldown_visuals()


func _update_cooldown_visuals():
	for skill in range(skills.size()):
		var progress_bar = (
			get_node(
				(
					"CanvasLayer/AvailableSkills/MarginContainer/CenterContainer/HBoxContainer/TextureRect%s/ProgressBar"
					% [skill + 1]
				)
			)
			as ProgressBar
		)
		var percentage: float
		var new_style_box = progress_bar.get_theme_stylebox("fill").duplicate() as StyleBoxFlat
		if skills[skill].current_in_stack > 0:
			percentage = float(skills[skill].current_in_stack) / float(skills[skill].max_per_stack)
			new_style_box.bg_color = Color(1, 1, 1, 0.5)
			progress_bar.add_theme_stylebox_override("fill", new_style_box)
		else:
			percentage = float(skills[skill].current_cooldown) / float(skills[skill].cooldown_turns)
			new_style_box.bg_color = Color(1, 0, 0, 0.5)
			progress_bar.add_theme_stylebox_override("fill", new_style_box)
		progress_bar.value = percentage
