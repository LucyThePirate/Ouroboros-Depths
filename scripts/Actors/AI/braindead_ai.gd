extends CreatureAI

class_name BraindeadAI
signal egg_died


func pursue_entity(_entity: GridEntity) -> Vector2i:
	return Vector2i.ZERO


func take_turn():
	if not grid_entity.is_alive():
		turn_component.end_turn()
		return
	match intent:
		_:
			pass
	visible = not grid_entity.is_in_darkness()
	update_intent()
	turn_component.end_turn()


func update_intent():
	if not angry_at:
		intent = "Move"
		intent_direction = Vector2i.ZERO
	else:
		intent = "Move"
		intent_direction = pursue_entity(angry_at)
	#if intent_arrow:
	#intent_arrow.visible = intent == "Move"
	#intent_arrow.look_at(intent_arrow.global_position + Vector2(intent_direction))
	if intent_label:
		intent_label.text = intent


func _on_grid_entity_hurt(attacker: GridEntity, damage_amount: int) -> void:
	if grid_entity.is_alive():
		attacker.soul_count += damage_amount


func _on_grid_entity_died() -> void:
	egg_died.emit()
	super()
