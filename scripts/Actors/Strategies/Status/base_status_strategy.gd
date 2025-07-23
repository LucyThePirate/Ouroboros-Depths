extends Node2D

class_name StatusStrategy

signal status_ended(StatusStrategy)

@export var turns_afflicted := 5
@onready var current_turns_afflicted := turns_afflicted
@export var power := 1
@export var icon: Texture2D


func _ready() -> void:
	pass


func on_turn_ended():
	current_turns_afflicted -= 1
	if current_turns_afflicted <= 0:
		on_status_ended()


func on_status_ended():
	status_ended.emit(self)


func modify_damage(incoming_damage := 1) -> int:
	return incoming_damage
