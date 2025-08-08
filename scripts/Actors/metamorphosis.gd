extends Control

class_name Metamorphosis

signal metamorphosis_completed

@onready
var soul_count = $CanvasLayer/Panel/HBoxContainer/Left/VBoxContainer/CenterContainer/SoulCount
var souls := 0

var grid_parent: GridEntity


func _ready() -> void:
	for soul in range(grid_parent.soul_count):
		souls += soul + 1
	soul_count.text = "Souls: %s" % souls


func _on_confirm_button_pressed() -> void:
	grid_parent.heal(souls)
	grid_parent.soul_count = 0
	metamorphosis_completed.emit()
	queue_free()
