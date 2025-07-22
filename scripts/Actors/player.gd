extends Node2D

class_name Player

signal descended

@export var text_component: PackedScene
@onready var current_text: TextComponent
@onready var grid_entity = $GridEntity
@onready var display = $Display
@onready var visual = $ScarecrowVisual
@onready var displayLerpTime = 0.0
@onready var turn_component = $GridEntity/TurnComponent
@onready var stack_component = $GridEntity/SkillStackComponent
@onready var health_component = $GridEntity/HealthComponent

var initialized = false

enum States { IDLE, DEAD, EXECUTING_STACK }
var state = States.IDLE


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	grid_entity.global_position = global_position
	display.global_position = grid_entity.global_position
	global_position = grid_entity.position
	visual.initialize(grid_entity)
	stack_component.initialize(grid_entity, true, turn_component)
	turn_component.turn_ended.connect(health_component.turn_ended)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not initialized:
		return
	global_position = grid_entity.position
	displayLerpTime += delta * 1.8
	display.global_position = display.global_position.lerp(
		grid_entity.global_position, min(1, displayLerpTime)
	)
	visual.global_position = display.global_position
	$StateLabel.text = (
		"%s - %s" % [States.keys()[state], stack_component.States.keys()[stack_component.state]]
	)


func _input(event):
	if Input.is_action_just_pressed("Chat") and not current_text:
		var new_text_component = text_component.instantiate() as TextComponent
		add_child(new_text_component)
		new_text_component.initialize(true)
		new_text_component.global_position = grid_entity.global_position
		current_text = new_text_component
		new_text_component.text_changed.connect(visual._on_talked)
		new_text_component.text_submitted.connect(_on_finished_writing_text)

	if not turn_component.my_turn or current_text:
		return

	match state:
		States.IDLE:
			_handle_movement()
		States.EXECUTING_STACK:
			if stack_component.state == SkillStackComponent.States.EXECUTING_STACK:
				pass
			elif stack_component.state == SkillStackComponent.States.AWAITING_DIRECTIONAL_INPUT:
				_handle_awaiting_directional_input()
			elif stack_component.state == SkillStackComponent.States.AWAITING_CURSOR_INPUT:
				_handle_awaiting_cursor_input()
			elif stack_component.state == SkillStackComponent.States.IDLE:
				state = States.IDLE


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

	elif Input.is_action_just_pressed("UseSkill4"):
		queue_skill(3)

	elif Input.is_action_just_pressed("ExecuteStack"):
		if state == States.IDLE:
			state = States.EXECUTING_STACK
			stack_component.execute_stack()

	elif Input.is_action_just_pressed("Reload"):
		stack_component.reload_deck()


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
	if stack_component.queue_skill(skill_number):
		end_turn()


func _handle_awaiting_directional_input():
	var moveDirection = _get_directional_input()
	if moveDirection:
		stack_component.set_direction(moveDirection)


func _handle_awaiting_cursor_input():
	var moveDirection = _get_directional_input()
	if moveDirection:
		stack_component.move_cursor(moveDirection)
	if Input.is_action_just_pressed("ui_accept"):
		stack_component.accept_cursor()


func _on_grid_entity_grid_entity_initialized() -> void:
	if initialized:
		return
	grid_entity.name = name
	initialized = true
	global_position = grid_entity.position


func end_turn():
	turn_component.end_turn()
	if not grid_entity.is_on_floor():
		_on_grid_entity_fell_off_map()
	elif grid_entity.is_on_path_down():
		grid_entity.descended.emit()
		descended.emit()


func _on_grid_entity_died() -> void:
	queue_free()


func _update_movement_visuals():
	visual.global_position = grid_entity.global_position
	display.global_position = grid_entity.global_position
	displayLerpTime = 0.0


func _on_grid_entity_performed_action() -> void:
	if state == States.IDLE:
		end_turn()


func _on_skill_stack_component_emptied_stack() -> void:
	if state == States.EXECUTING_STACK:
		state = States.IDLE
		end_turn()


func _on_finished_writing_text() -> void:
	current_text = null


func _on_grid_entity_fell_off_map() -> void:
	visual._on_fell_off_map()
	state = States.DEAD
	visual.connect("finished_animation", _on_grid_entity_died)
