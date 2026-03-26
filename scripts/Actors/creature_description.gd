extends Control

class_name CreatureDescription

@export var status_description_scene: PackedScene

@onready var creature_name = $CanvasLayer/Window/ScrollContainer/Control/SkillName
@onready var icon = $CanvasLayer/Window/ScrollContainer/Control/PanelContainer/Icon
@onready var creature_desc = $CanvasLayer/Window/ScrollContainer/Control/SkillDesc
@onready var status_desc_holder = $CanvasLayer/Window/ScrollContainer/Control/Statuses


func _ready():
	$DominoFlip.play()
	$CanvasLayer/Window/ScrollContainer/Control/ActiveStatuses.hide()
	Global.UI_opened.emit()


func set_status_descriptions(descriptions: Array):
	for status_desc in descriptions:
		$CanvasLayer/Window/ScrollContainer/Control/ActiveStatuses.show()
		var new_status_desc = status_description_scene.instantiate() as StatusDescription
		status_desc_holder.add_child(new_status_desc)
		new_status_desc.icon.texture = status_desc["Icon"]
		new_status_desc.label.text = (
			"[color=GOLD]%s[/color] - %s" % [status_desc["Name"], status_desc["Desc"]]
		)
		new_status_desc.power.text = "[color=LIME]%s" % status_desc["Power"]


func _on_window_close_requested() -> void:
	Global.UI_closed.emit()
	queue_free()


func _on_window_focus_exited() -> void:
	Global.UI_closed.emit()
	queue_free()
