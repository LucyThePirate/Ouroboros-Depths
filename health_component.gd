extends Node2D

class_name HealthComponent

signal hurt
signal healed
signal died

@export var max_health = 15
@export var damage_number_scene: PackedScene

@onready var health = max_health
@onready var health_bar = $VBoxContainer/ProgressBar as ProgressBar
@onready var health_label = $VBoxContainer/ProgressBar/Label

var current_damage_number: DamageNumberComponent
var current_heal_number: DamageNumberComponent


func _ready():
	_update_health_bar()


func deal_damage(damage_amount = 1):
	health -= damage_amount
	if not is_instance_valid(current_damage_number):
		current_damage_number = damage_number_scene.instantiate()
		current_damage_number.add_damage(damage_amount)
		current_damage_number.global_position = global_position
		get_tree().current_scene.add_child(current_damage_number)
	else:
		current_damage_number.add_damage(damage_amount)
		current_damage_number.global_position = global_position
	if health <= 0:
		died.emit()
	else:
		hurt.emit()
	_update_health_bar()


func heal(heal_amount):
	health = min(health + heal_amount, max_health)
	healed.emit()
	if not is_instance_valid(current_heal_number):
		current_heal_number = damage_number_scene.instantiate()
		current_heal_number.add_heal(heal_amount)
		current_heal_number.global_position = global_position
		get_tree().current_scene.add_child(current_heal_number)
	else:
		current_heal_number.add_heal(heal_amount)
		current_heal_number.global_position = global_position
	_update_health_bar()


func turn_ended():
	current_damage_number = null


func set_color(new_color: Color):
	health_bar.self_modulate = new_color


func _update_health_bar():
	health_bar.max_value = max_health
	health_bar.value = health
	health_label.text = str(health)
