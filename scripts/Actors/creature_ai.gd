extends Node2D

class_name CreatureAI

#signal aggroed_towards_player(grid_entity)

@export var visual: Node2D

@onready var grid_entity = $GridEntity
@onready var display = $Display
@onready var displayLerpTime = 0.0
@onready var turn_component = $GridEntity/TurnComponent
@onready var stack_component = $GridEntity/SkillStackComponent
@onready var health_component = $GridEntity/UI/HealthComponent
@onready
var status_manager_component = $GridEntity/UI/StatusManagerComponent as StatusManagerComponent
@onready var random_skill_planner = $BaseRandomSkillPlanner
@onready var intent_arrow = $IntentArrow

var initialized = false
var in_darkness = false
var level: Node2D
var angry_at: GridEntity
@onready var intent := "Do Nothing"
@onready var intent_label = $IntentLabel
var intent_direction := Vector2i.ZERO


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	grid_entity.global_position = global_position
	display.global_position = grid_entity.global_position
	global_position = grid_entity.position
	stack_component.initialize(grid_entity, false, turn_component)
	random_skill_planner.set_stack_component(stack_component)
	turn_component.turn_ended.connect(health_component.turn_ended)
	if visual.has_method("initialize"):
		visual.initialize(grid_entity)
	#turn_component.turn_ended.connect(status_manager_component.on_turn_ended)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not initialized or not grid_entity:
		return
	global_position = grid_entity.position
	displayLerpTime += delta * 1.8
	display.global_position = display.global_position.lerp(
		grid_entity.global_position, min(1, displayLerpTime)
	)
	visual.global_position = display.global_position


func take_turn():
	if (
		not grid_entity.is_alive()
		or stack_component.state == SkillStackComponent.States.EXECUTING_STACK
	):
		turn_component.end_turn()
		return
	match intent:
		"Move":
			move_in_direction(intent_direction)
		"Queue Skill":
			random_skill_planner.perform_plan("Queue Skill")
		"Execute Stack":
			random_skill_planner.perform_plan("Execute Stack")
		_:
			print("%s did %s" % [name, intent])
			pass
	in_darkness = grid_entity.is_in_darkness()
	visible = not in_darkness
	#if in_darkness:
	#modulate = Color.BLACK
	#else:
	#modulate = Color.WHITE
	update_intent()
	turn_component.end_turn()


func update_intent():
	if not angry_at:
		intent = "Move"
		intent_direction = get_random_direction() as Vector2i
	else:
		intent = "Move"
		intent_direction = pursue_entity(angry_at)
	if intent_arrow:
		intent_arrow.visible = intent == "Move"
		intent_arrow.look_at(intent_arrow.global_position + Vector2(intent_direction))
	if intent_label:
		intent_label.text = (
			"%s - %s" % [intent, stack_component.States.keys()[stack_component.state]]
		)


func get_random_direction() -> Vector2i:
	var move_direction = grid_entity.get_valid_moves()
	if move_direction:
		return move_direction.pick_random()
	else:
		return Vector2i.ZERO


func move_in_direction(moveDirection):
	visual.global_position = grid_entity.global_position
	display.global_position = grid_entity.global_position
	var move_successful = grid_entity.move(moveDirection, angry_at == null)
	if not move_successful:
		display.global_position += Vector2(moveDirection) * 25
	displayLerpTime = 0.0


func get_direction_towards(
	entity: GridEntity, allow_diagonals := false, allow_moving_into_entities := false
) -> Vector2i:
	var validMoves = grid_entity.get_valid_moves(allow_moving_into_entities)
	if validMoves:
		# Pick a move pointing towards target, otherwise pick a random move.
		var directionToEntity = (entity.global_position - grid_entity.global_position).normalized()
		directionToEntity = Vector2i(round(directionToEntity.x), round(directionToEntity.y))

		if allow_diagonals:
			return directionToEntity

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


func pursue_entity(entity: GridEntity) -> Vector2i:
	if randf() > 0.5 or in_darkness:
		return get_direction_towards(entity, false, true)
	else:
		intent = random_skill_planner.make_plan(entity)

		stack_component.preview_queueing_skill(intent == "Queue Skill")
		stack_component.preview_executing_stack(intent == "Execute Stack")

		if not intent:
			return get_direction_towards(entity, false, true)
		return Vector2i.ZERO


func _on_grid_entity_grid_entity_initialized() -> void:
	if initialized:
		return
	grid_entity.name = name
	initialized = true


func _on_grid_entity_died(is_despawning) -> void:
	_update_angry_at(null)
	queue_free()


func _on_grid_entity_hurt(attacker: GridEntity, damage_amount: int) -> void:
	if grid_entity.is_alive():
		_update_angry_at(attacker)


func _update_angry_at(new_target: GridEntity):
	if new_target == angry_at:
		return
	if new_target == null:
		if angry_at and angry_at.is_in_group("Player"):
			Global.deaggroed_towards_player.emit(grid_entity)
		angry_at = null
		health_component.set_color(Color.WHITE)
	if not can_aggro_against(new_target):
		return
	if new_target.is_in_group("Player"):
		Global.aggroed_towards_player.emit(grid_entity)
		health_component.set_color(Color.RED)
	elif angry_at and angry_at.is_in_group("Player"):
		Global.deaggroed_towards_player.emit(grid_entity)
		health_component.set_color(Color.WHITE)
	angry_at = new_target
	angry_at.died.connect(_on_angry_at_died)
	print(name, " pissed at ", new_target.name)


func can_aggro_against(new_target: GridEntity) -> bool:
	if (
		new_target == null
		or not is_instance_valid(new_target)
		or not is_instance_valid(grid_entity)
	):
		return false
	if new_target == grid_entity or new_target is not GridEntity:
		return false
	if new_target.species_name == grid_entity.species_name:
		return false
	if new_target.state == GridEntity.States.DEAD:
		return false
	return true


func _on_angry_at_died():
	_update_angry_at(null)


func _on_turn_component_turn_started() -> void:
	take_turn()


func _on_base_random_skill_planner_awaited_directional_input() -> void:
	if angry_at:
		random_skill_planner.set_direction(get_direction_towards(angry_at))
	else:
		random_skill_planner.set_direction(get_random_direction())


func _on_base_random_skill_planner_awaited_cursor_input() -> void:
	if angry_at:
		random_skill_planner.set_cursor(get_direction_towards(angry_at, true))
	else:
		random_skill_planner.set_direction(get_random_direction())


func _on_detection_radius_body_entered(body: Node2D) -> void:
	if angry_at:
		return
	if body.is_in_group("Player") and not in_darkness:
		_update_angry_at(body)
