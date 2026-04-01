extends Control

class_name SkillDescription

@onready var skill_name = $CanvasLayer/Window/ScrollContainer/Control/SkillName
@onready var icon = $CanvasLayer/Window/ScrollContainer/Control/PanelContainer/Icon
@onready var skill_desc = $CanvasLayer/Window/ScrollContainer/Control/SkillDesc
@onready var stack_size = %StackSizeLabel

func _ready():
	$DominoFlip.play()
	Global.UI_opened.emit()


func _on_window_close_requested() -> void:
	Global.UI_closed.emit()
	queue_free()


func _on_window_focus_exited() -> void:
	Global.UI_closed.emit()
	queue_free()
