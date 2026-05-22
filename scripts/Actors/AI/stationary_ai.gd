extends CreatureAI

class_name StationaryAI


func _ready() -> void:
	super()


func pursue_entity(entity: GridEntity) -> Vector2i:
	intent = random_skill_planner.make_plan(grid_entity, entity)

	stack_component.preview_queueing_skill(intent == "Queue Skill")
	stack_component.preview_executing_stack(intent == "Execute Stack")

	if intent == "Execute Stack":
		visual.use_parent_material = false

	if not intent:
		return Vector2i.ZERO
	return Vector2i.ZERO


func take_turn():
	if not grid_entity.is_alive():
		turn_component.end_turn()
		return
	match intent:
		"Move":
			pass
		"Queue Skill":
			random_skill_planner.perform_plan("Queue Skill")
		"Execute Stack":
			random_skill_planner.perform_plan("Execute Stack")
		_:
			print("%s did %s" % [name, intent])
			pass
	visible = not grid_entity.is_in_darkness() or Debug.fog_visible == false
	update_intent()
	turn_component.end_turn()


func update_intent():
	if not angry_at:
		intent = "Move"
		intent_direction = Vector2i.ZERO
		check_for_targets()
	else:
		intent = "Move"
		intent_direction = pursue_entity(angry_at)
	#if intent_arrow:
	#intent_arrow.visible = intent == "Move"
	#intent_arrow.look_at(intent_arrow.global_position + Vector2(intent_direction))
	if intent_label:
		intent_label.text = intent
