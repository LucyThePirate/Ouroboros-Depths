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
var purchasable_items = []


func _ready() -> void:
	for soul in range(grid_parent.soul_count):
		souls += soul + 1
	soul_count.text = "Souls: %s" % souls
	for button in buy_skill_container.get_children() as Array[Button]:
		var new_item = {}
		var random_skill = buyable_skills.pick_random().instantiate() as SkillStrategy
		if not random_skill:
			continue
		random_skill.count = 1
		new_item["skill"] = random_skill
		new_item["cost"] = 1
		button.add_child(random_skill)
		button.name = str(buy_skill_buttons.size())
		#button.icon = random_skill.get_icon()
		button.text = "%s\n%s Soul" % [random_skill.skill_name, 1]
		button.pressed.connect(_on_buy_skill_pressed.bind(buy_skill_buttons.size()))
		buy_skill_buttons.append(button)
		purchasable_items.append(new_item)


func _on_confirm_button_pressed() -> void:
	grid_parent.heal(souls)
	grid_parent.soul_count = 0
	metamorphosis_completed.emit()
	queue_free()


func _on_buy_skill_pressed(item_number) -> void:
	var item_to_buy = purchasable_items[item_number]
	if not item_to_buy:
		return
	print("Trying to buy:", item_to_buy)
	if grid_parent.soul_count >= item_to_buy["cost"]:
		$SkillBought.play()
		grid_parent.soul_count -= item_to_buy["cost"]
		soul_count.text = "Souls: %s" % grid_parent.soul_count
		purchasable_items[item_number] = {}
		buy_skill_buttons[item_number].text = "Sold out!"
		grid_parent.stack_component.add_skill(item_to_buy["skill"])

	else:
		# Not enough souls
		print("Too broke! :(")
		pass
