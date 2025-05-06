extends Node2D

signal turn_ended

@onready var grid_entity = $GridEntity
@onready var display = $Display
@onready var visual = $LichTest
@onready var displayLerpTime = 0.0
@onready var turn_component = $TurnComponent

var initialized = false

var skills = []
var stack = []
var current_skill: SkillStrategy

enum States { IDLE, DEAD, EXECUTING_STACK, AWAITING_DIRECTIONAL_INPUT, AWAITING_CURSOR_INPUT }
var state = States.IDLE


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	grid_entity.global_position = global_position
	display.global_position = grid_entity.global_position
	global_position = grid_entity.position


#func _input(event):
#match event.as_text():
#_:
#print("Pressed:", event.as_text())


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not initialized:
		return
	global_position = grid_entity.position
	displayLerpTime += delta * 1.8
	display.global_position = display.global_position.lerp(
		grid_entity.global_position, min(1, displayLerpTime)
	)
	#visual.global_position = visual.global_position.lerp(display.global_position, min(1, displayLerpTime))
	visual.global_position = display.global_position


func _input(event):
	if not turn_component.my_turn:
		return

	match state:
		States.IDLE:
			_handle_movement()
		States.EXECUTING_STACK:
			_handle_stack_execution()
		States.AWAITING_DIRECTIONAL_INPUT:
			_handle_awaiting_directional_input()
		States.AWAITING_CURSOR_INPUT:
			pass


func _handle_movement() -> void:
	var moveDirection = _get_directional_input()
	if moveDirection:
		_update_movement_visuals()
		var move_successful = grid_entity.move(moveDirection)
		if not move_successful:
			display.global_position += moveDirection * 25

	elif Input.is_action_just_pressed("Wait"):
		end_turn()
		return

	elif Input.is_action_just_pressed("UseSkill1"):
		queue_skill(0)

	elif Input.is_action_just_pressed("UseSkill2"):
		queue_skill(1)

	elif Input.is_action_just_pressed("UseSkill3"):
		queue_skill(2)

	elif Input.is_action_just_pressed("ExecuteStack"):
		if stack:
			state = States.EXECUTING_STACK


func _get_directional_input():
	var moveDirection = Input.get_vector("Left", "Right", "Up", "Down")

	if (
		moveDirection
		and (
			Input.is_action_just_pressed("Left")
			or Input.is_action_just_pressed("Right")
			or Input.is_action_just_pressed("Down")
			or Input.is_action_just_pressed("Up")
		)
	):
		moveDirection = Vector2(roundi(moveDirection.x), roundi(moveDirection.y))
		if moveDirection.x and moveDirection.y:  # Disallow diagonal movements... for now.
			return
	return moveDirection


func queue_skill(skill_number):
	if skills.size() >= skill_number + 1 and stack.size() < 4:
		print(name, " queued skill: ", skills[skill_number].name)
		stack.append(skills[skill_number])
		end_turn()


func _handle_stack_execution():
	if stack.is_empty():
		state = States.IDLE
		end_turn()
		return
	current_skill = stack.pop_front() as SkillStrategy
	if current_skill.ready_skill(grid_entity):
		await get_tree().create_timer(.15).timeout
		_handle_stack_execution()
	elif current_skill.state == SkillStrategy.States.AWAITING_DIRECTION:
		state = States.AWAITING_DIRECTIONAL_INPUT
	elif current_skill.state == SkillStrategy.States.AWAITING_CURSOR:
		state = States.AWAITING_CURSOR_INPUT


func _handle_awaiting_directional_input():
	var moveDirection = _get_directional_input()
	if moveDirection:
		current_skill.set_direction(moveDirection)
		current_skill.use_skill(grid_entity)
		state = States.EXECUTING_STACK


func _on_grid_entity_grid_entity_initialized() -> void:
	if initialized:
		return
	grid_entity.name = name
	initialized = true
	global_position = grid_entity.position
	skills = Debug.find_children_in_group($Skills, "Skill", false)


func end_turn():
	turn_component.end_turn()


func _on_grid_entity_died() -> void:
	queue_free()


func _on_dash_skill_strategy_moved_self() -> void:
	_update_movement_visuals()


func _update_movement_visuals():
	visual.global_position = grid_entity.global_position
	display.global_position = grid_entity.global_position
	displayLerpTime = 0.0


func _on_grid_entity_performed_action() -> void:
	if state == States.IDLE:
		end_turn()
