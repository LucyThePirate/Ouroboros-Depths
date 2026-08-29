extends Node2D

class_name Player

signal descended

@export var text_component: PackedScene
@export var chrysalis_status_scene: PackedScene
@export var metamorphosis_scene: PackedScene

@onready var soul_particle_effect := preload("uid://doabdeo7r61yu")
@onready var current_text: TextComponent
@onready var current_error_text: TextComponent
@onready var grid_entity = $GridEntity
@onready var display = $Display
@onready var visual = $ScarecrowVisual
@onready var displayLerpTime = 0.0
@onready var turn_component = $GridEntity/TurnComponent
@onready var stack_component = $GridEntity/SkillStackComponent
@onready var health_component = $GridEntity/UI/HealthComponent as HealthComponent

var cursor_position := Vector2i.ZERO
var last_mouse_cursor_position := Vector2i.ZERO

var initialized = false

enum States {IDLE, DEAD, EXECUTING_STACK, METAMORPHOSIS_STARTED, METAMORPHING, FALLING, IN_CUTSCENE}
var state = States.IDLE

var is_talking := false
var can_survive_falls := false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	grid_entity.global_position = global_position
	display.global_position = grid_entity.global_position
	grid_entity.team = grid_entity
	global_position = grid_entity.position
	visual.initialize(grid_entity)
	_load_deck()
	stack_component.initialize(grid_entity, true, turn_component)
	stack_component.tried_queueieng.connect(func(skill_number: int): queue_skill(skill_number))
	stack_component.tried_executing.connect(execute_queue)
	stack_component.crammed_skill.connect(_on_stack_component_crammed_skill)
	stack_component.tried_reloading.connect(
		func():
			Input.action_press("Reload")
			Input.action_release("Reload")
	)
	stack_component.awaited_cursor_input.connect(_on_stack_component_awaited_cursor)
	turn_component.turn_ended.connect(health_component.turn_ended)
	grid_entity.moved.connect(_on_grid_entity_moved)
	update_soul_counter()


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

	if current_text:
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
				%ScarecrowVisual.use_parent_material = true


#region movement handling
func _handle_movement() -> void:
	var moveDirection = _get_directional_input()
	if moveDirection:
		_update_movement_visuals()
		var move_successful = grid_entity.move(moveDirection, false, true)
		if not move_successful:
			display.global_position += moveDirection * 25
		#%LastMovedDirection.look_at(%LastMovedDirection.global_position + Vector2(moveDirection))

	elif (
		Input.is_action_just_pressed("Wait")
		or (Input.is_action_pressed("Wait") and Input.is_action_pressed("Run"))
	):
		if not Input.is_action_pressed("Run"):
			%WaitSFX.play()
			var new_text_component = text_component.instantiate() as TextComponent
			add_child(new_text_component)
			new_text_component.initialize(false)
			new_text_component.global_position = grid_entity.global_position
			new_text_component.set_text("...", "[wave amp=50.0 freq=5.0 connected=1]")
		end_turn()
		return

	elif Input.is_action_just_pressed("UseSkill1"):
		queue_skill(0)
		return

	elif Input.is_action_just_pressed("UseSkill2"):
		queue_skill(1)
		return

	elif Input.is_action_just_pressed("UseSkill3"):
		queue_skill(2)
		return

	elif Input.is_action_just_pressed("UseSkill4"):
		queue_skill(3)
		return

	elif Input.is_action_just_pressed("ExecuteStack"):
		execute_queue()
		return

	elif Input.is_action_just_pressed("Reload"):
		stack_component.reload_deck()
		return

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


func _get_directional_input():
	var moveDirection = Vector2()
	var is_running = false
	if Input.is_action_pressed("Run"):
		if Engine.get_physics_frames() % 3 == 0:
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
		#if moveDirection.x and moveDirection.y:  # Disallow diagonal movements... for now.
		#return
	return moveDirection


#endregion


#region metamorphosis
func _metamorphing_interrupted(_status):
	if state == States.METAMORPHOSIS_STARTED:
		state = States.IDLE


func _metamorphing_started():
	if state == States.METAMORPHOSIS_STARTED:
		state = States.METAMORPHING
		stack_component.on_next_floor_reached()
		update_soul_counter()
		var new_metamorph = metamorphosis_scene.instantiate()
		new_metamorph.grid_parent = grid_entity
		new_metamorph.metamorphosis_completed.connect(_metamorphing_completed)
		add_child(new_metamorph)


func _metamorphing_completed():
	if state == States.METAMORPHING:
		$MetamorphosisEnd.play()
		update_soul_counter()
		state = States.IDLE


#endregion


#region queue execution
func queue_skill(skill_number):
	if state != States.IDLE:
		return
	if stack_component.queue_skill(skill_number):
		pass
		execute_queue()
		#end_turn()


func execute_queue():
	if state != States.IDLE:
		return
	%ExecutingParticles.emitting = true
	state = States.EXECUTING_STACK
	%ScarecrowVisual.use_parent_material = false
	stack_component.execute_stack()


func _handle_awaiting_directional_input():
	%Arrows.modulate = Color.WHITE
	var moveDirection = _get_directional_input()
	if moveDirection:
		%Arrows.modulate = Color.TRANSPARENT
		stack_component.set_direction(moveDirection)


func _on_stack_component_awaited_cursor():
	%Cursor.show()
	%Arrows.hide()
	cursor_position = grid_entity.grid_coords
	stack_component.set_cursor_position(cursor_position)
	last_mouse_cursor_position = Global.floors.local_to_map(get_global_mouse_position())
	%Cursor.position = Global.floors.map_to_local(cursor_position)


func _on_stack_component_crammed_skill():
	end_turn()


func _handle_awaiting_cursor_input():
	if Input.get_last_mouse_screen_velocity().length() > 5:
		var mouse_cursor_position = Global.floors.local_to_map(get_global_mouse_position())
		if mouse_cursor_position != last_mouse_cursor_position:
			last_mouse_cursor_position = mouse_cursor_position
			stack_component.set_cursor_position(mouse_cursor_position)
			%Cursor.position = Global.floors.map_to_local(mouse_cursor_position)
	else:
		var move_direction = _get_directional_input()
		if move_direction:
			cursor_position += Vector2i(move_direction)
			%Cursor.position = Global.floors.map_to_local(cursor_position)
			stack_component.set_cursor_position(cursor_position)
	if Input.is_action_just_pressed("ui_accept"):
		%Cursor.hide()
		%Arrows.show()
		stack_component.accept_cursor()


func _on_skill_stack_component_emptied_stack() -> void:
	if state == States.EXECUTING_STACK:
		%ExecutingParticles.emitting = false
		state = States.IDLE
		%ScarecrowVisual.use_parent_material = true
		end_turn()


func _load_deck():
	var deck = Global.load_deck().instantiate()
	add_child(deck)
	for skill in deck.get_children():
		skill.reparent(stack_component)
	deck.queue_free()


#endregion


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
		if state != States.DEAD:
			state = States.IN_CUTSCENE
			grid_entity.descended.emit()
			descended.emit()


func next_floor_reached():
	if state == States.IN_CUTSCENE:
		state = States.IDLE


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


func _on_grid_entity_moved(old_coord: Vector2i, _new_coord: Vector2i):
	display.global_position = Global.floors.map_to_local(old_coord)
	displayLerpTime = 0.0


func _on_finished_writing_text() -> void:
	current_text = null
	is_talking = false


func _on_grid_entity_fell_off_map() -> void:
	visual._on_fell_off_map()
	state = States.FALLING
	await visual.finished_animation
	if not can_survive_falls:
		state = States.DEAD
		_on_grid_entity_died(true)
	else:
		grid_entity.descended.emit()
		descended.emit()


#region UI stuff
func _on_grid_entity_absorbed_souls(soul_position: Vector2) -> void:
	var new_soul_particle = soul_particle_effect.instantiate() as SoulParticleEffect
	new_soul_particle.target = grid_entity
	new_soul_particle.global_position = soul_position
	get_tree().current_scene.add_child(new_soul_particle)
	new_soul_particle.reached_target.connect(update_soul_counter)


func update_soul_counter() -> void:
	%SoulCountDisplay.text = "Souls: %s" % grid_entity.soul_count


func _display_error(error_msg: String):
	$Error.play()
	if not current_error_text:
		var new_text_scene = text_component.instantiate() as TextComponent
		current_error_text = new_text_scene
		new_text_scene.global_position = grid_entity.global_position
		get_tree().current_scene.add_child(new_text_scene)
		new_text_scene.set_error_text(error_msg)


func _on_health_component_health_updated() -> void:
	if health_component:
		%HealthBar.max_value = health_component.max_health
		%HealthBar.value = health_component.health
		%HealthLabel.text = "%s/%s" % [health_component.health, health_component.max_health]


#endregion


#region arrow buttons
func _on_right_arrow_button_pressed() -> void:
	Input.action_press("Right")
	Input.action_release("Right")


func _on_up_arrow_button_pressed() -> void:
	Input.action_press("Up")
	Input.action_release("Up")


func _on_left_arrow_button_pressed() -> void:
	Input.action_press("Left")
	Input.action_release("Left")


func _on_down_arrow_button_pressed() -> void:
	Input.action_press("Down")
	Input.action_release("Down")


func _on_wait_button_pressed() -> void:
	Input.action_press("Wait")
	Input.action_release("Wait")


func _on_chrysalis_button_pressed() -> void:
	Input.action_press("Chrysalis")
	Input.action_release("Chrysalis")

#endregion
