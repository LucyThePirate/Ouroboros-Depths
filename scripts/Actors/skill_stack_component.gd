extends Node2D

class_name SkillStackComponent

signal used_skill
signal queued_skill
signal stack_full
signal emptied_stack
signal awaited_directional_input
signal awaited_cursor_input
signal gained_status(status)
signal reload_started
signal skill_removed

@export var max_stack_size := 4
@export var hand_size := 4
@export var turns_to_reload := 5
var shuffle_turns := 0
@export var preview_queue_skill_texture := Texture2D
@export var null_skill_texture := Texture2D
@export var reload_status: PackedScene
@export var skill_icon_scene: PackedScene
@export var text_scene: PackedScene
@onready var current_error_text

@onready var hand_visual = $CanvasLayer/AvailableSkills/MarginContainer/CenterContainer/HandVisual
@onready var stack_icon_holder = $Stack/MarginContainer/CenterContainer/StackIconHolder
@onready
var preview_queue_skill = $Stack/MarginContainer/CenterContainer/StackIconHolder/PanelContainer5/PreviewQueueSkill
@onready var stack_color_rect = $Stack/MarginContainer/ColorRect
@onready var skill_bag = $CanvasLayer/AvailableSkills/PanelContainer/SkillBagButton as Button
@onready var skill_bag_list = $CanvasLayer/SkillBagList/Control/ScrollContainer/HFlowContainer
@onready
var execute_prompt = $CanvasLayer/AvailableSkills/MarginContainer/CenterContainer/ExecutePrompt

var skills = []
var total_skill_count := 0
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
	$CanvasLayer/SkillBagList.hide()


func initialize(grid_entity_parent: GridEntity, is_player: bool, new_turn_component: TurnComponent):
	grid_entity = grid_entity_parent
	grid_entity.descended.connect(on_next_floor_reached)
	$CanvasLayer.visible = is_player
	turn_component = new_turn_component
	turn_component.turn_ended.connect(_update_turn_cooldown)
	grid_entity.moved.connect(_on_grid_entity_moved)


func reload_deck() -> bool:
	if state == States.IDLE:  # and stack.is_empty():
		#print("%s is reloading!" % [grid_entity.name])
		if $CanvasLayer.visible:
			$ReloadStart.play()
			$Reload.emitting = true
		reload_started.emit()
		state = States.RELOADING
		hand = []
		deck = []
		_update_skill_visuals()
		_update_stack_visuals()
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
		$SkillAdded.pitch_scale = 0.7 + (0.20 * stack.size())
		$SkillAdded.play()
		hand[skill_number].increment_in_stack_counter()
		_update_cooldown_visuals()
		$Stack.show()
		#print(name, " queued skill: ", skills[skill_number].name)
		stack.append(hand[skill_number])
		hand[skill_number].connect("gained_status", _on_gained_status)
		hand[skill_number].on_skill_queued()
		_update_stack_visuals()
		if is_full():
			stack_full.emit()
		hand[skill_number] = null
		if not deck.is_empty():
			hand[skill_number] = deck.pop_front()
			total_skill_count -= 1
		_update_skill_visuals()
		return true
	else:
		if state == States.RELOADING:
			_display_error("Reloading!")
		elif is_full():
			_display_error("Stack is full!")
	return false


func is_full() -> bool:
	if stack.size() >= max_stack_size:
		return true
	return false


func can_execute_stack() -> bool:
	if stack.is_empty() or state != States.IDLE:
		return false
	return true


func execute_stack() -> bool:
	grid_entity.moved_by_skill = false
	if not can_execute_stack():
		if stack.is_empty():
			_display_error("Stack is empty!")
		elif state == States.RELOADING:
			_display_error("Reloading!")
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


func _on_grid_entity_moved(old_coords: Vector2i, new_coords: Vector2i):
	for skill in stack:
		skill.on_grid_entity_moved(old_coords, new_coords)


func _on_gained_status(status: StatusStrategy):
	gained_status.emit(status)


func add_skill(new_skill: SkillStrategy):
	var existing_skill = find_skill_by_ID(new_skill.skill_ID)
	if existing_skill:
		existing_skill.count += 1
		existing_skill.current_count += 1
		deck.push_back(existing_skill)
		new_skill.queue_free()
	else:
		new_skill.reparent(self)
		skills.append(new_skill)
		deck.push_back(new_skill)
	total_skill_count += 1
	_update_skill_visuals()


func remove_skill(new_skill: SkillStrategy) -> bool:
	var existing_skill = find_skill_by_ID(new_skill.skill_ID)
	if existing_skill and existing_skill.count >= 1 and existing_skill.current_count >= 1:
		existing_skill.count -= 1
		existing_skill.current_count -= 1
		deck.remove_at(deck.find(existing_skill))
		#new_skill.queue_free()
		total_skill_count -= 1
		#if existing_skill.count <= 0:
		#existing_skill.queue_free()
		#_shuffle_skills()
		_update_skill_visuals()
		_on_skill_bag_list_close_requested()
		skill_removed.emit()
		return true
	else:
		# Couldn't remove skill
		return false


func find_skill_by_ID(skill_ID := SkillStrategy.SkillIDs.NONE, group = skills) -> SkillStrategy:
	for skill in group:
		if skill.skill_ID == skill_ID and skill_ID != SkillStrategy.SkillIDs.NONE:
			return skill
	return null


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
	state = States.IDLE
	deck = []
	#stack = []
	hand = []
	total_skill_count = 0
	for skill in skills:
		skill.current_cooldown = 0
		for i in range(skill.current_count):
			total_skill_count += 1
			deck.append(skill)
	deck.shuffle()
	for i in range(hand_size):
		if deck.is_empty():
			break
		hand.append(deck.pop_front())
		total_skill_count -= 1
	_update_skill_visuals()
	_update_stack_visuals()


func on_next_floor_reached() -> void:
	for skill in skills:
		skill.on_next_floor_reached()
	_shuffle_skills()


func _update_stack_visuals() -> void:
	for panel_container in stack_icon_holder.get_children():
		panel_container.get_child(0).texture = null
	execute_prompt.visible = false
	if can_execute_stack():
		execute_prompt.visible = true
	for stack_item in range(stack.size()):
		stack_icon_holder.get_child(stack_item).get_child(0).texture = (
			stack[stack_item].icon.texture
		)


func _update_skill_visuals() -> void:
	skill_bag.text = "x%s" % total_skill_count
	for skill in range(hand_size):
		if hand.size() <= skill or not hand[skill]:
			hand_visual.get_child(skill).get_child(0).texture = null_skill_texture
			continue
		hand_visual.get_child(skill).get_child(0).texture = hand[skill].icon.texture


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
	_update_stack_visuals()


func _update_cooldown_visuals():
	if state == States.RELOADING:
		for skill in range(hand_size):
			var progress_bar = (
				get_node(
					(
						"CanvasLayer/AvailableSkills/MarginContainer/CenterContainer/HandVisual/PanelContainer%s/ProgressBar"
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
					"CanvasLayer/AvailableSkills/MarginContainer/CenterContainer/HandVisual/PanelContainer%s/ProgressBar"
					% [skill + 1]
				)
			)
			as ProgressBar
		)
		if progress_bar:
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


func _on_info_button_1_pressed() -> void:
	if hand[0]:
		hand[0].display_skill_info()


func _on_info_button_2_pressed() -> void:
	if hand[1]:
		hand[1].display_skill_info()


func _on_info_button_3_pressed() -> void:
	if hand[2]:
		hand[2].display_skill_info()


func _on_info_button_4_pressed() -> void:
	if hand[3]:
		hand[3].display_skill_info()


func _on_skill_bag_button_pressed() -> void:
	if not $CanvasLayer/SkillBagList.visible:
		var skills_in_display = []
		var skill_counts = {}
		for skill in deck:
			var existing_skill = find_skill_by_ID(skill.skill_ID, skills_in_display)
			if existing_skill:
				skill_counts[existing_skill] += 1
			else:
				skills_in_display.append(skill)
				skill_counts[skill] = 1
		skills_in_display.sort_custom(func(a, b): return a.skill_ID < b.skill_ID)
		for skill in skills_in_display:
			var new_skill_icon = skill_icon_scene.instantiate()
			new_skill_icon.clicked.connect(skill.display_skill_info)
			new_skill_icon.set_icon_texture(skill.icon.texture)
			new_skill_icon.set_count(skill_counts[skill])
			skill_bag_list.add_child(new_skill_icon)
		skill_bag_list.get_children().shuffle()
		$CanvasLayer/SkillBagList.show()
		$OpenBag.play()
	else:
		_on_skill_bag_list_close_requested()


func _on_skill_bag_list_close_requested() -> void:
	$CanvasLayer/SkillBagList.hide()
	$CloseBag.play()
	for skill in skill_bag_list.get_children():
		skill.queue_free()


func open_skill_bag_for_skill_removal():
	if not $CanvasLayer/SkillBagList.visible:
		var skills_in_display = []
		var skill_counts = {}
		for skill in deck:
			var existing_skill = find_skill_by_ID(skill.skill_ID, skills_in_display)
			if existing_skill:
				skill_counts[existing_skill] += 1
			else:
				skills_in_display.append(skill)
				skill_counts[skill] = 1
		skills_in_display.sort_custom(func(a, b): return a.skill_ID < b.skill_ID)
		for skill in skills_in_display:
			var new_skill_icon = skill_icon_scene.instantiate()
			new_skill_icon.left_clicked.connect(remove_skill.bind(skill))
			new_skill_icon.right_clicked.connect(skill.display_skill_info)
			new_skill_icon.set_icon_texture(skill.icon.texture)
			new_skill_icon.set_count(skill_counts[skill])
			skill_bag_list.add_child(new_skill_icon)
		skill_bag_list.get_children().shuffle()
		$CanvasLayer/SkillBagList.show()
		$OpenBag.play()
	else:
		_on_skill_bag_list_close_requested()


func _on_close_skill_bag_pressed() -> void:
	_on_skill_bag_list_close_requested()


func _display_error(error_msg: String):
	if not grid_entity.is_in_group("Player"):
		return
	$Error.play()
	if not current_error_text:
		var new_text_scene = text_scene.instantiate() as TextComponent
		current_error_text = new_text_scene
		new_text_scene.global_position = grid_entity.global_position
		get_tree().current_scene.add_child(new_text_scene)
		new_text_scene.set_error_text(error_msg)
