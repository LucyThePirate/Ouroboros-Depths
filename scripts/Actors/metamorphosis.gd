extends Control

class_name Metamorphosis

signal metamorphosis_completed

@export var buyable_skills: Array[PackedScene]
@export var skill_icon_scene: PackedScene
@export var sold_out_texture: Texture2D

@onready
var soul_count = $CanvasLayer/Panel/HBoxContainer/Left/VBoxContainer/CenterContainer/SoulCount
var souls := 0

var grid_parent: GridEntity
@onready var buy_skill_container = $CanvasLayer/Panel/HBoxContainer/Right/GridContainer
var buy_skill_buttons: Array[Button]
var purchasable_items = []
var num_items_on_sale := 6


func _ready() -> void:
	for soul in range(grid_parent.soul_count):
		souls += soul + 1
	var bonus_souls = souls - grid_parent.soul_count
	grid_parent.soul_count = souls
	soul_count.text = "Souls: %s\n(+%s bonus souls!)" % [souls, bonus_souls]
	for item_num in range(num_items_on_sale):
		var new_item = {}
		var random_skill = buyable_skills.pick_random().instantiate() as SkillStrategy
		if not random_skill:
			continue
		random_skill.count = 1
		new_item["skill"] = random_skill
		new_item["cost"] = 1
		var new_skill_icon = skill_icon_scene.instantiate() as SkillIcon
		buy_skill_container.add_child(new_skill_icon)
		add_child(random_skill)
		new_skill_icon.set_icon_texture(random_skill.icon.texture)
		new_skill_icon.left_clicked.connect(_on_buy_skill_pressed.bind(item_num))
		new_skill_icon.right_clicked.connect(random_skill.display_skill_info)
		#button.name = str(buy_skill_buttons.size())
		new_skill_icon.set_text("%s\n%s Soul" % [random_skill.skill_name, new_item["cost"]])
		#buy_skill_buttons.append(button)
		purchasable_items.append(new_item)


func _on_confirm_button_pressed() -> void:
	grid_parent.heal(grid_parent.soul_count)
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
		buy_skill_container.get_child(item_number).set_text("Sold out!")
		buy_skill_container.get_child(item_number).set_icon_texture(sold_out_texture)
		grid_parent.stack_component.add_skill(item_to_buy["skill"])

	else:
		# Not enough souls
		print("Too broke! :(")
		pass
