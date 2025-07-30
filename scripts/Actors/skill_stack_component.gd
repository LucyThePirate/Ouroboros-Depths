extends Node2D

class_name SkillStackComponent

signal used_skill
signal queued_skill
signal stack_full
signal emptied_stack
signal awaited_directional_input
signal awaited_cursor_input
signal gained_status(status)

@onready
var skill_icon_holder = $CanvasLayer/AvailableSkills/MarginContainer/CenterContainer/HBoxContainer
@onready var stack_icon_holder = $Stack/MarginContainer/CenterContainer/HBoxContainer
@onready
var preview_queue_skill = $Stack/MarginContainer/CenterContainer/HBoxContainer/PanelContainer5/PreviewQueueSkill
@onready var stack_color_rect = $Stack/MarginContainer/ColorRect

@export var max_stack_size := 4
@export var hand_size := 4
@export var turns_to_reload := 5
var shuffle_turns := 0
@export var preview_queue_skill_texture := Texture2D
@export var null_skill_texture := Texture2D
@export var reload_status: PackedScene

var skills = []
var stack = []
var deck = []
var hand = []
var current_skill: SkillStrategy
enum States {
	IDLE, DEAD, EXECUTING_STACK, AWAITING_DIRECTIONAL_INPUT, AWAITING_CURSOR_INPUT, RELOADING
}
var state = States.IDLE
var grid_entity: GridEntity
var turn_component: TurnComponent

var moved_by_skill := false


func _ready() -> void:
	skills = Debug.find_children_in_group(self, "Skill", false)
	_shuffle_skills()


func initialize(grid_entity_parent: GridEntity, is_player: bool, new_turn_component: TurnComponent):
	grid_entity = grid_entity_parent
	grid_entity.descended.connect(on_next_floor_reached)
	$CanvasLayer.visible = is_player
	turn_component = new_turn_component
	turn_component.turn_ended.connect(_update_turn_cooldown)


func reload_deck() -> bool:
	if state == States.IDLE and stack.is_empty():
		#print("%s is reloading!" % [grid_entity.name])
		if $CanvasLayer.visible:
			$ReloadStart.play()
			$Reload.emitting = true
		state = States.RELOADING
		hand = []
		deck = []
		_update_skill_visuals()
		shuffle_turns = turns_to_reload
		var new_status = reload_status.instantiate() as StatusStrategy
		add_child(new_status)
		gained_status.emit(new_status)
		return true
	return false


func can_queue_skill(skill_number) -> bool:
	if state == States.RELOADING:
		return false
	if hand.is_empty() or not hand[skill_number]:
		reload_deck()
		return false
	if skills.size() >= skill_number + 1 and not is_full() and hand[skill_number].can_use_skill():
		return true
	return false


func queue_skill(skill_number) -> bool:
	if can_queue_skill(skill_number):
		#hand[skill_number].increment_in_stack_counter()
		_update_cooldown_visuals()
		$Stack.show()
		#print(name, " queued skill: ", skills[skill_number].name)
		stack.append(hand[skill_number])
		_update_stack_visuals()
		if is_full():
			stack_full.emit()
		hand[skill_number] = null
		if not deck.is_empty():
			hand[skill_number] = deck.pop_front()
		_update_skill_visuals()
		return true
	return false


func is_full() -> bool:
	if stack.size() >= max_stack_size:
		return true
	return false


func can_execute_stack() -> bool:
	if stack.is_empty():
		return false
	return true


func execute_stack() -> bool:
	grid_entity.moved_by_skill = false
	if stack.is_empty():
		return false
	state = States.EXECUTING_STACK
	for skill in stack:
		skill.on_stack_execution_started(grid_entity)
	_handle_stack_execution()
	return true


func _handle_stack_execution():
	_update_stack_visuals()
	if stack.is_empty():
		state = States.IDLE
		emptied_stack.emit()
		_update_cooldown_visuals()
		for skill in skills:
			skill.on_stack_execution_finished(grid_entity)
		return
	current_skill = stack.pop_front() as SkillStrategy
	current_skill.connect("moved_self", _on_moved_by_skill)
	current_skill.connect("gained_status", _on_gained_status)
	stack_icon_holder.get_child(0).get_child(0).get_child(0).show()
	if current_skill.ready_skill(grid_entity):
		await get_tree().create_timer(0.1).timeout
		_handle_stack_execution()

	elif current_skill.state == SkillStrategy.States.AWAITING_DIRECTION:
		state = States.AWAITING_DIRECTIONAL_INPUT
		awaited_directional_input.emit()

	elif current_skill.state == SkillStrategy.States.AWAITING_CURSOR:
		state = States.AWAITING_CURSOR_INPUT
		awaited_cursor_input.emit()


func _on_moved_by_skill():
	grid_entity.moved_by_skill = true


func _on_gained_status(status: StatusStrategy):
	gained_status.emit(status)


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
	stack_icon_holder.get_child(0).get_child(0).get_child(0).hide()


func _shuffle_skills() -> void:
	for skill in skills:
		skill.current_cooldown = 0
		for i in range(skill.current_count):
			deck.append(skill)
	deck.shuffle()
	for i in range(hand_size):
		if deck.is_empty():
			break
		hand.append(deck.pop_front())
	_update_skill_visuals()


func on_next_floor_reached() -> void:
	for skill in skills:
		skill.on_next_floor_reached()


func _update_stack_visuals() -> void:
	for panel_container in stack_icon_holder.get_children():
		panel_container.get_child(0).texture = null
	for stack_item in range(stack.size()):
		stack_icon_holder.get_child(stack_item).get_child(0).texture = (
			stack[stack_item].icon.texture
		)


func _update_skill_visuals() -> void:
	for skill in range(hand_size):
		if hand.size() <= skill or not hand[skill]:
			skill_icon_holder.get_child(skill).get_child(0).texture = null_skill_texture
			continue
		skill_icon_holder.get_child(skill).get_child(0).texture = hand[skill].icon.texture


func _update_turn_cooldown():
	if state == States.RELOADING:
		shuffle_turns -= 1
		if shuffle_turns <= 0:
			state = States.IDLE
			if $CanvasLayer.visible:
				$ReloadEnd.play()
			_shuffle_skills()
	if state == States.IDLE:
		for skill in range(hand.size()):
			if not hand[skill]:
				continue
			hand[skill].decrement_turn_cooldown()
	_update_cooldown_visuals()


func _update_cooldown_visuals():
	if state == States.RELOADING:
		for skill in range(hand_size):
			var progress_bar = (
				get_node(
					(
						"CanvasLayer/AvailableSkills/MarginContainer/CenterContainer/HBoxContainer/PanelContainer%s/ProgressBar"
						% [skill + 1]
					)
				)
				as ProgressBar
			)
			var percentage: float
			var new_style_box = progress_bar.get_theme_stylebox("fill").duplicate() as StyleBoxFlat

			percentage = float(shuffle_turns) / float(turns_to_reload)
			new_style_box.bg_color = Color(1, 1, 1, 0.5)
			progress_bar.add_theme_stylebox_override("fill", new_style_box)
			progress_bar.value = percentage
		return
	for skill in range(hand.size()):
		if not hand[skill]:
			continue
		var progress_bar = (
			get_node(
				(
					"CanvasLayer/AvailableSkills/MarginContainer/CenterContainer/HBoxContainer/PanelContainer%s/ProgressBar"
					% [skill + 1]
				)
			)
			as ProgressBar
		)
		var percentage: float
		var new_style_box = progress_bar.get_theme_stylebox("fill").duplicate() as StyleBoxFlat

		if hand[skill].current_in_stack > 0:
			#percentage = float(hand[skill].current_in_stack) / float(hand[skill].max_per_stack)
			percentage = 0
			new_style_box.bg_color = Color(1, 1, 1, 0.5)
			progress_bar.add_theme_stylebox_override("fill", new_style_box)
		else:
			percentage = float(hand[skill].current_cooldown) / float(hand[skill].cooldown_turns)
			new_style_box.bg_color = Color(1, 0, 0, 0.5)
			progress_bar.add_theme_stylebox_override("fill", new_style_box)
		progress_bar.value = percentage


func preview_queueing_skill(show_preview := true):
	preview_queue_skill.texture = preview_queue_skill_texture
	preview_queue_skill.visible = show_preview


func preview_executing_stack(show_preview := true):
	if show_preview:
		stack_color_rect.color = Color.from_rgba8(233, 0, 73, 200)
	else:
		stack_color_rect.color = Color.from_rgba8(182, 104, 0, 90)
