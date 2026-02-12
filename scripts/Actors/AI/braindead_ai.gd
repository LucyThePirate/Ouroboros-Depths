extends CreatureAI

class_name BraindeadAI
signal egg_died
signal egg_timer_expired

enum BOGOTIME { INSTANT, TIME_25, TIME_50, TIME_100, TIME_150, TIME_200, NEVER }
@onready var selected_bogo_time := BOGOTIME.TIME_100


func _ready() -> void:
	if Global.config.has_section_key("Gameplay", "BogosortTimer"):
		selected_bogo_time = Global.config.get_value("Gameplay", "BogosortTimer")
		match selected_bogo_time:
			BOGOTIME.INSTANT:
				$BogoTimer.start(3)
			BOGOTIME.TIME_25:
				$BogoTimer.start(25)
			BOGOTIME.TIME_50:
				$BogoTimer.start(50)
			BOGOTIME.TIME_100:
				$BogoTimer.start(100)
			BOGOTIME.TIME_150:
				$BogoTimer.start(150)
			BOGOTIME.TIME_200:
				$BogoTimer.start(200)
			_:
				print("Bogo timer not started.")
	super()


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


func _on_grid_entity_died(is_despawning) -> void:
	if not is_despawning:
		egg_died.emit()
	super(is_despawning)


func _on_bogo_timer_timeout() -> void:
	egg_timer_expired.emit()


func _update_angry_at(_new_target: GridEntity):
	return
