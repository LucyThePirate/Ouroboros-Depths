@tool
extends Control

class_name HealthComponent

signal hurt
signal healed
signal died
signal health_updated
signal max_health_updated

@export var max_health = 15
@export var damage_number_scene: PackedScene
@export var allow_desperation_mode := false
@onready var health = max_health
@onready var health_bar = $ProgressBar as ProgressBar
@onready var base_max_health = max_health

var current_damage_number: DamageNumberComponent
var current_heal_number: DamageNumberComponent

var tween


func _ready():
	_update_health_bar()


func set_health(new_health: int, new_max_health := 0):
	health = new_health
	if new_max_health:
		max_health_updated.emit()
		max_health = new_max_health
	_update_health_bar()


func deal_damage(damage_amount = 1):
	if damage_amount <= 0:
		return
	health -= damage_amount
	if not is_instance_valid(current_damage_number):
		current_damage_number = damage_number_scene.instantiate()
		current_damage_number.add_damage(damage_amount)
		current_damage_number.global_position = %DamageNumberSpawn.global_position
		get_tree().current_scene.add_child(current_damage_number)
	else:
		current_damage_number.add_damage(damage_amount)
		current_damage_number.global_position = %DamageNumberSpawn.global_position
	if health <= 0:
		died.emit()
	else:
		hurt.emit()
	_update_health_bar()


func heal(heal_amount):
	if heal_amount <= 0:
		return
	var healed_amount = health
	health = min(health + heal_amount, max_health)
	healed_amount = abs(health - healed_amount)
	healed.emit()
	if healed_amount <= 0:
		return
	if not is_instance_valid(current_heal_number):
		current_heal_number = damage_number_scene.instantiate()
		current_heal_number.add_heal(healed_amount)
		current_heal_number.global_position = %DamageNumberSpawn.global_position
		get_tree().current_scene.add_child(current_heal_number)
	else:
		current_heal_number.add_heal(healed_amount)
		current_heal_number.global_position = %DamageNumberSpawn.global_position
	_update_health_bar()


func get_health_percentage() -> float:
	return float(health) / float(max_health)


func get_max_health_percentage() -> float:
	return float(max_health) / float(base_max_health)


func turn_ended():
	current_damage_number = null
	current_heal_number = null


func set_color(new_color: Color):
	health_bar.self_modulate = new_color


func set_text_color(new_color: Color):
	%HealthLabel.self_modulate = new_color


func _update_health_bar():
	health_bar.max_value = max_health
	health_bar.value = health
	%HealthLabel.text = "%s/%s" % [health, max_health]
	var missing_health = max_health - health
	if missing_health >= 25:
		%OnesPlace.frame = 4
		%OnesPlace.frame = 4
	else:
		%OnesPlace.frame = missing_health % 5
		%FivesPlace.frame = (missing_health / 5) % 5
	%FivesControl.visible = %FivesPlace.frame != 0
	%OnesControl.visible = %OnesPlace.frame != 0
	%FivesPlace.scale = Vector2.ONE
	%OnesPlace.scale = Vector2.ONE
	if tween:
		tween.kill()
	tween = get_tree().create_tween()
	tween.tween_property(%FivesPlace, "scale", Vector2(0.495, 0.495), 0.1)
	tween.tween_property(%OnesPlace, "scale", Vector2(0.495, 0.495), 0.1)
	health_updated.emit()
