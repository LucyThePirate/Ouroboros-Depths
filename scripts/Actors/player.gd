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
var executing_stack = false
var awaiting_directional_input = false


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

	if not executing_stack:
		_handle_movement()
	else:
		_handle_stack_execution()


func _handle_movement() -> void:
	var moveDirection = _get_directional_input()
	if moveDirection:
		_update_movement_visuals()
		var move_successful = grid_entity.move(moveDirection)
		if not move_successful:
			display.global_position += moveDirection * 25
		#else:
		#end_turn()

	elif Input.is_action_just_pressed("Wait"):
		end_turn()
		return

	elif Input.is_action_just_pressed("UseSkill1"):
		if skills and stack.size() < 4:
			stack.append(skills[0])
			end_turn()
			return

	elif Input.is_action_just_pressed("ExecuteStack"):
		if stack:
			executing_stack = true


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


func _handle_stack_execution():
	if not stack:
		executing_stack = false
		return
	if not awaiting_directional_input:
		var current_skill = stack.pop_front() as SkillStrategy
		if current_skill.ready_skill(grid_entity):
			current_skill.use_skill(grid_entity)
		elif awaiting_directional_input:
			var move_direction = _get_directional_input()
			if move_direction:
				current_skill.set_direction(move_direction)
				awaiting_directional_input = false
				current_skill.use_skill(grid_entity)

	if stack.is_empty():
		executing_stack = false
		end_turn()
		return


func _on_grid_entity_grid_entity_initialized() -> void:
	if initialized:
		return
	grid_entity.name = name
	initialized = true
	global_position = grid_entity.position
	skills = Debug.find_children_in_group(self, "Skill", false)


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
	if not executing_stack:
		end_turn()


func _on_dash_skill_strategy_requested_direction_input(skill: SkillStrategy) -> void:
	awaiting_directional_input = true
