extends CreatureAI

class_name BraindeadAI
signal egg_died
signal egg_timer_expired

enum BOGOTIME { INSTANT, TIME_25, TIME_50, TIME_100, TIME_150, TIME_200, NEVER }
@onready var selected_bogo_time := BOGOTIME.TIME_150

var base_scale := 0.455


func _ready() -> void:
	if Global.config.has_section_key("Gameplay", "BogosortTimer"):
		selected_bogo_time = Global.config.get_value("Gameplay", "BogosortTimer")
	match selected_bogo_time:
		BOGOTIME.INSTANT:
			$BogoTimer.start(1)
		BOGOTIME.TIME_25:
			$BogoTimer.start(2.5)
		BOGOTIME.TIME_50:
			$BogoTimer.start(5)
		BOGOTIME.TIME_100:
			$BogoTimer.start(10)
		BOGOTIME.TIME_150:
			$BogoTimer.start(15)
		BOGOTIME.TIME_200:
			$BogoTimer.start(20)
		_:
			print("Bogo timer not started.")
	super()


func _on_grid_entity_hurt(attacker: GridEntity, damage_amount: int) -> void:
	_egg_damaged_visual()
	if grid_entity.is_alive():
		attacker.soul_count += damage_amount
		attacker.absorbed_souls.emit(global_position)


func _on_grid_entity_died(is_despawning) -> void:
	if not is_despawning:
		egg_died.emit()
	super(is_despawning)


func _on_bogo_timer_timeout() -> void:
	_egg_damaged_visual()
	#egg_timer_expired.emit()
	grid_entity.health_component.deal_damage(1)


func _egg_damaged_visual() -> void:
	var missing_health = (
		grid_entity.health_component.max_health - grid_entity.health_component.health
	)
	%EggCrack.volume_db = missing_health
	%EggCrack.pitch_scale = 1.2 - (0.08 * missing_health)
	%EggCrack.play()
	%EggSprite.frame = missing_health / 2
	var new_scale = base_scale + ((base_scale * missing_health) / 10)
	%EggSprite.scale = Vector2(new_scale, new_scale)
	%EggSprite.material.set("shader_parameter/intensity", missing_health)
