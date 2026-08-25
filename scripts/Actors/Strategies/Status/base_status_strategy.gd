extends Panel

class_name StatusStrategy

signal status_ended(StatusStrategy)
signal power_changed
signal max_power_reached
signal healed(heal_amount)
signal harmed(damage_amount)
signal modify_max_health(max_health_change)

enum Status_IDs {
	NONE,
	SHIELD,
	RELOAD,
	PATIENCE,
	CHRYSALIS,
	VIGOR,
	REGEN,
	HIDDEN,
	MOBILE_GUARD,
	SPEED,
	DECAY,
	BOUNCY,
	EXPLOSIVE,
	DESPERATION,
}

@export_category("Lore")
@export var status_name := "Default Status Name"
@export_multiline var status_desc := "Default Status Desc"
@onready var icon := $TextureRect

@export_category("Stats")
@export var turns_afflicted := 5
@onready var current_turns_afflicted := turns_afflicted
@export var power := 1
@export var status_ID := Status_IDs.NONE
@onready var power_label = $Label as RichTextLabel
@export var max_power = 999


func _ready() -> void:
	_update_visuals()


func merge_status(status: StatusStrategy):
	power = min(max_power, power + status.power)
	current_turns_afflicted = turns_afflicted
	_update_visuals()


func decrease_power(amount := 1):
	power -= amount
	if power <= 0:
		on_status_ended()


func increase_power(amount := 1) -> bool:
	if power >= max_power:
		return false
	power = min(max_power, power + amount)
	_update_visuals()
	if power >= max_power:
		max_power_reached.emit()
	return true


func on_turn_ended():
	current_turns_afflicted -= 1
	if current_turns_afflicted <= 0:
		power -= 1
		current_turns_afflicted = turns_afflicted
		_update_visuals()
	if power <= 0:
		on_status_ended()


func on_status_ended():
	status_ended.emit(self)


func on_moved(_old_coord: Vector2i, _new_coord: Vector2i):
	pass


func on_reload_started():
	pass


func on_grid_entity_parent_set(_grid_entity: GridEntity):
	pass


func on_next_floor_reached(_health_component: HealthComponent = null):
	status_ended.emit(self)


func on_stack_execution_started():
	pass


func on_stack_execution_finished():
	pass


func on_hit_by_grid_entity(_attacker: GridEntity, _damage_amount := 1):
	pass


func modify_incoming_damage(incoming_damage := 1) -> int:
	return incoming_damage


func modify_outgoing_damage(outgoing_damage := 1) -> int:
	return outgoing_damage


## Returns true if status prevents death
func on_death(is_despawning: bool, _health_component: HealthComponent = null) -> bool:
	if is_despawning:
		return false
	return false


func _update_visuals() -> void:
	visible = power > 0
	if power == 1:
		power_label.text = ""
		return
	if power >= max_power:
		power_label.text = (
			"[outline_color=GOLDENROD][color=YELLOW]%s[/color][/outline_color]" % str(power)
		)
	else:
		power_label.text = str(power)
