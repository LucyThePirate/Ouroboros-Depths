extends Node2D

class_name TurnComponent

signal turn_started
signal turn_ended

var my_turn = false


func _ready() -> void:
	if not Global.is_turn_based():
		%AutoTurnTimer.start()


func is_my_turn() -> bool:
	if not Global.is_turn_based():
		return true
	return my_turn


func take_turn():
	my_turn = true
	turn_started.emit()


func end_turn():
	my_turn = false
	turn_ended.emit()


func _on_auto_turn_timer_timeout() -> void:
	take_turn()
	%AutoTurnTimer.start(0.25)
