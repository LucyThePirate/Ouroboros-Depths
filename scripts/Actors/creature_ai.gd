extends Node2D

@onready var grid_entity = $GridEntity
@onready var display = $Display
@onready var visual = $LichTest
@onready var displayLerpTime = 0.0
@onready var turn_component = $TurnComponent
@onready var stack_component = $GridEntity/SkillStackComponent
@onready var random_skill_planner = $BaseRandomSkillPlanner

var initialized = false
var level: Node2D

var angry_at: GridEntity


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	grid_entity.global_position = global_position
	display.global_position = grid_entity.global_position
	global_position = grid_entity.position
	stack_component.initialize(grid_entity, false, turn_component)
	random_skill_planner.set_stack_component(stack_component)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not initialized or not grid_entity:
		return
	global_position = grid_entity.position
	displayLerpTime += delta * 1.8
	display.global_position = display.global_position.lerp(
		grid_entity.global_position, min(1, displayLerpTime)
	)
	#visual.global_position = visual.global_position.lerp(display.global_position, min(1, displayLerpTime))
	visual.global_position = display.global_position


func take_turn():
	if not grid_entity.is_alive():
		turn_component.end_turn()
		return
	if not angry_at:
		move_randomly()
	else:
		pursue_entity(angry_at)
	turn_component.end_turn()


func move_randomly():
	#if randf() > 0.5:
	#random_skill_planner.perform_plan()
	#return
	var moveDirection = grid_entity.get_valid_moves().pick_random()
	if moveDirection:
		move_in_direction(moveDirection)
		#$Camera2D.make_current()
		#$Timer.start()


func move_in_direction(moveDirection):
	visual.global_position = grid_entity.global_position
	display.global_position = grid_entity.global_position
	var move_successful = grid_entity.move(moveDirection)
	if not move_successful:
		display.global_position += Vector2(moveDirection) * 25
	displayLerpTime = 0.0


func get_direction_towards(entity: GridEntity) -> Vector2i:
	var validMoves = grid_entity.get_valid_moves()
	if validMoves:
		# Pick a move pointing towards target, otherwise pick a random move.
		var directionToEntity = (entity.global_position - grid_entity.global_position).normalized()
		directionToEntity = Vector2i(round(directionToEntity.x), round(directionToEntity.y))

		var movesTowardsEntity = []
		if directionToEntity in validMoves:
			movesTowardsEntity.append(directionToEntity)
		if Vector2i(directionToEntity.x, 0) in validMoves:
			movesTowardsEntity.append(Vector2i(directionToEntity.x, 0))
		if Vector2i(0, directionToEntity.y) in validMoves:
			movesTowardsEntity.append(Vector2i(0, directionToEntity.y))

		if movesTowardsEntity:
			return movesTowardsEntity.pick_random()
		else:
			return validMoves.pick_random()
	return Vector2i.ZERO


func pursue_entity(entity: GridEntity):
	#var attack_successful = grid_entity.try_attacking(entity)
	##if randf() > 0.5:
#
	##return
	#if not attack_successful:
	if randf() > 0.5:
		move_in_direction(get_direction_towards(entity))
	else:
		random_skill_planner.perform_plan(entity)


func _on_grid_entity_grid_entity_initialized() -> void:
	if initialized:
		return
	grid_entity.name = name
	initialized = true


func _on_grid_entity_died() -> void:
	queue_free()


func _on_grid_entity_hurt(attacker: GridEntity) -> void:
	angry_at = attacker
	angry_at.died.connect(_on_angry_at_died)


func _on_angry_at_died():
	angry_at = null


func _on_turn_component_turn_started() -> void:
	take_turn()


func _on_base_random_skill_planner_awaited_directional_input() -> void:
	if angry_at:
		random_skill_planner.set_direction(get_direction_towards(angry_at))


func _on_base_random_skill_planner_awaited_cursor_input() -> void:
	if angry_at:
		random_skill_planner.set_cursor(get_direction_towards(angry_at))
