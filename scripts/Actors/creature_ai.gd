extends Node2D

@onready var grid_entity = $GridEntity
@onready var display = $Display
@onready var visual = $LichTest
@onready var displayLerpTime = 0.0
@onready var turn_component = $TurnComponent
@onready var stack_component = $GridEntity/SkillStackComponent

var initialized = false
var level: Node2D

var angry_at: GridEntity


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	grid_entity.global_position = global_position
	display.global_position = grid_entity.global_position
	global_position = grid_entity.position
	stack_component.initialize(grid_entity, false)


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


func move_towards_entity(entity: GridEntity):
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
			move_in_direction(movesTowardsEntity.pick_random())
		else:
			move_in_direction(validMoves.pick_random())


func pursue_entity(entity: GridEntity):
	var attack_successful = grid_entity.try_attacking(entity)
	if not attack_successful:
		move_towards_entity(entity)


func _on_grid_entity_grid_entity_initialized() -> void:
	if initialized:
		return
	grid_entity.name = name
	initialized = true


func _on_grid_entity_died() -> void:
	queue_free()


func _on_grid_entity_hurt(attacker) -> void:
	angry_at = attacker


func _on_turn_component_turn_started() -> void:
	take_turn()
