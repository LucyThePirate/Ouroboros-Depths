extends Node2D

class_name TurnComponent

signal turn_started
signal turn_ended

var my_turn = false
var is_busy := false


func _ready() -> void:
	if not Global.is_turn_based():
		%AutoTurnTimer.start()


func is_my_turn() -> bool:
	if not Global.is_turn_based():
		return true
	return my_turn


func take_turn():
	if is_busy:
		return
	is_busy = true
	my_turn = true
	turn_started.emit()


func end_turn():
	my_turn = false
	turn_ended.emit()
	is_busy = false


func _on_auto_turn_timer_timeout() -> void:
	take_turn()
	%AutoTurnTimer.start(0.25)
