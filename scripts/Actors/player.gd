extends Node2D

class_name Player

signal descended

@export var text_component: PackedScene
@export var chrysalis_status_scene: PackedScene
@export var metamorphosis_scene: PackedScene

@onready var current_text: TextComponent
@onready var current_error_text: TextComponent
@onready var grid_entity = $GridEntity
@onready var display = $Display
@onready var visual = $ScarecrowVisual
@onready var displayLerpTime = 0.0
@onready var turn_component = $GridEntity/TurnComponent
@onready var stack_component = $GridEntity/SkillStackComponent
@onready var health_component = $GridEntity/UI/HealthComponent

var initialized = false

enum States { IDLE, DEAD, EXECUTING_STACK, METAMORPHOSIS_STARTED, METAMORPHING }
var state = States.IDLE

var is_talking := false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	grid_entity.global_position = global_position
	display.global_position = grid_entity.global_position
	global_position = grid_entity.position
	visual.initialize(grid_entity)
	_load_deck()
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
	if turn_component.is_my_turn() and state == States.METAMORPHOSIS_STARTED:
		process_mode = Node.PROCESS_MODE_DISABLED
		await get_tree().create_timer(0.1).timeout
		process_mode = Node.PROCESS_MODE_ALWAYS
		end_turn()

	if Input.is_action_just_pressed("Chat"):
		if not is_talking:
			var new_text_component = text_component.instantiate() as TextComponent
			add_child(new_text_component)
			new_text_component.initialize(true)
			new_text_component.global_position = grid_entity.global_position
			current_text = new_text_component
			is_talking = true
			new_text_component.text_changed.connect(visual._on_talked)
			#new_text_component.text_submitted.connect(_on_finished_writing_text)
		else:
			_on_finished_writing_text()

	if not turn_component.is_my_turn() or current_text:
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
			elif (
				stack_component.state == SkillStackComponent.States.IDLE
				or stack_component.state == SkillStackComponent.States.RELOADING
			):
				state = States.IDLE


func _handle_movement() -> void:
	var moveDirection = _get_directional_input()
	if moveDirection:
		_update_movement_visuals()
		var move_successful = grid_entity.move(moveDirection)
		if not move_successful:
			display.global_position += moveDirection * 25

	elif (
		Input.is_action_just_pressed("Wait")
		or (Input.is_action_pressed("Wait") and Input.is_action_pressed("Run"))
	):
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
			#$ExecutingParticles.emitting = true
			state = States.EXECUTING_STACK
			stack_component.execute_stack()

	elif Input.is_action_just_pressed("Reload"):
		stack_component.reload_deck()

	elif Input.is_action_just_pressed("Chrysalis"):
		if grid_entity.soul_count > 0 and state == States.IDLE:
			state = States.METAMORPHOSIS_STARTED
			var new_chrysalis_status = chrysalis_status_scene.instantiate() as StatusStrategy
			if not $MetamorphosisStart.playing:
				$MetamorphosisStart.play()
			new_chrysalis_status.max_power_reached.connect(_metamorphing_started)
			new_chrysalis_status.status_ended.connect(_metamorphing_interrupted)
			add_child(new_chrysalis_status)
			grid_entity.gain_status(new_chrysalis_status)
			end_turn()
			return
		elif grid_entity.soul_count <= 0:
			_display_error("Need souls!")
		elif state != States.IDLE:
			_display_error("Can't metamorph right now!")


func _metamorphing_interrupted(_status):
	if state == States.METAMORPHOSIS_STARTED:
		state = States.IDLE


func _metamorphing_started():
	if state == States.METAMORPHOSIS_STARTED:
		state = States.METAMORPHING
		var new_metamorph = metamorphosis_scene.instantiate()
		new_metamorph.grid_parent = grid_entity
		new_metamorph.metamorphosis_completed.connect(_metamorphing_completed)
		add_child(new_metamorph)


func _metamorphing_completed():
	if state == States.METAMORPHING:
		$MetamorphosisEnd.play()
		state = States.IDLE


func _get_directional_input():
	var moveDirection = Vector2()
	var is_running = false
	if Input.is_action_pressed("Run"):
		is_running = true
	if Input.is_action_just_pressed("Left") or (is_running and Input.is_action_pressed("Left")):
		moveDirection.x -= 1
	if Input.is_action_just_pressed("Right") or (is_running and Input.is_action_pressed("Right")):
		moveDirection.x += 1
	if Input.is_action_just_pressed("Up") or (is_running and Input.is_action_pressed("Up")):
		moveDirection.y -= 1
	if Input.is_action_just_pressed("Down") or (is_running and Input.is_action_pressed("Down")):
		moveDirection.y += 1
	if moveDirection:
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


func _on_grid_entity_died(despawning) -> void:
	state = States.DEAD
	grid_entity.on_death(despawning)
	hide()


func _update_movement_visuals():
	visual.global_position = grid_entity.global_position
	display.global_position = grid_entity.global_position
	displayLerpTime = 0.0


func _on_grid_entity_performed_action() -> void:
	if state == States.IDLE:
		end_turn()


func _on_skill_stack_component_emptied_stack() -> void:
	if state == States.EXECUTING_STACK:
		#$ExecutingParticles.emitting = false
		state = States.IDLE
		end_turn()


func _on_finished_writing_text() -> void:
	current_text = null
	is_talking = false


func _load_deck():
	var deck = Global.load_deck().instantiate()
	add_child(deck)
	for skill in deck.get_children():
		skill.reparent(stack_component)
	deck.queue_free()


func _on_grid_entity_fell_off_map() -> void:
	visual._on_fell_off_map()
	state = States.DEAD
	await visual.finished_animation
	#visual.connect("finished_animation", _on_grid_entity_died)
	_on_grid_entity_died(false)


func _on_grid_entity_absorbed_souls(soul_position: Vector2) -> void:
	pass
	#$CanvasLayer/TextureRect/SoulCountDisplay.text = "Souls: %s" % grid_entity.soul_count
	#if $AnimationPlayer.is_playing():
	#$AnimationPlayer.seek(0.5)
	#else:
	#$AnimationPlayer.play("DisplaySouls")


func _display_error(error_msg: String):
	$Error.play()
	if not current_error_text:
		var new_text_scene = text_component.instantiate() as TextComponent
		current_error_text = new_text_scene
		new_text_scene.global_position = grid_entity.global_position
		get_tree().current_scene.add_child(new_text_scene)
		new_text_scene.set_error_text(error_msg)
