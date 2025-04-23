extends Node2D

signal hurt
signal healed
signal died

@export var max_health = 15

@onready var health = max_health
@onready var health_bar = $ProgressBar
@onready var health_label = $Label


func _ready():
	_update_health_bar()


func deal_damage(damage_amount = 1):
	health -= damage_amount
	if health <= 0:
		died.emit()
	else:
		hurt.emit()
	_update_health_bar()


func heal(heal_amount):
	health = min(health + heal_amount, max_health)
	healed.emit()
	_update_health_bar()


func _update_health_bar():
	health_bar.max_value = max_health
	health_bar.value = health
	health_label.text = str(health)
