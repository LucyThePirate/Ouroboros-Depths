extends Node2D

class_name TurnComponent

signal turn_started
signal turn_ended

var my_turn = false


func is_my_turn() -> bool:
	return my_turn


func take_turn():
	my_turn = true
	turn_started.emit()


func end_turn():
	my_turn = false
	turn_ended.emit()
