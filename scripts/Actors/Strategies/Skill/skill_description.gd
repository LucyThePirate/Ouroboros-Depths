extends Control

class_name SkillDescription

@onready var skill_name = $CanvasLayer/Window/ScrollContainer/Control/SkillName
@onready var icon = $CanvasLayer/Window/ScrollContainer/Control/PanelContainer/Icon
@onready var skill_desc = $CanvasLayer/Window/ScrollContainer/Control/SkillDesc


func _ready():
	$DominoFlip.play()


func _on_window_close_requested() -> void:
	queue_free()


func _on_window_focus_exited() -> void:
	queue_free()
