extends Control

class_name Metamorphosis

signal metamorphosis_completed

@export var buyable_skills: Array[PackedScene]

@onready
var soul_count = $CanvasLayer/Panel/HBoxContainer/Left/VBoxContainer/CenterContainer/SoulCount
var souls := 0

var grid_parent: GridEntity
@onready var buy_skill_container = $CanvasLayer/Panel/HBoxContainer/Right/GridContainer
var buy_skill_buttons: Array[Button]


func _ready() -> void:
	for soul in range(grid_parent.soul_count):
		souls += soul + 1
	soul_count.text = "Souls: %s" % souls
	for button in buy_skill_container.get_children() as Array[Button]:
		var random_skill = buyable_skills.pick_random().instantiate() as SkillStrategy
		if not random_skill:
			continue
		button.add_child(random_skill)
		button.name = random_skill.name + str(buy_skill_buttons.size())
		#button.icon = random_skill.get_icon()
		button.text = "%s\n%s Soul" % [random_skill.skill_name, 1]
		buy_skill_buttons.append(button)
		button.pressed.connect(_on_buy_skill_pressed.bind(button.name))


func _on_confirm_button_pressed() -> void:
	grid_parent.heal(souls)
	grid_parent.soul_count = 0
	metamorphosis_completed.emit()
	queue_free()


func _on_buy_skill_pressed(button_name) -> void:
	print("Button %s pressed" % button_name)
