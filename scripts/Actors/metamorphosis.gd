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
@onready
var buy_skill_container = $CanvasLayer/Panel/HBoxContainer/Right/VBoxContainer/BuySkillContainer
var buy_skill_buttons: Array[Button]
var purchasable_items = []
var num_items_on_sale := 6

var reroll_cost := 3
@onready var reroll_button = (
	$CanvasLayer/Panel/HBoxContainer/Right/VBoxContainer/UpgradesContainer/RerollSkillsButton
	as Button
)


func _ready() -> void:
	for soul in range(grid_parent.soul_count):
		souls += soul + 1
	var bonus_souls = souls - grid_parent.soul_count
	grid_parent.soul_count = souls
	soul_count.text = "Souls: %s\n(+%s bonus souls!)" % [souls, bonus_souls]
	reroll_cost = 3
	_stock_buyable_skills()


func _stock_buyable_skills():
	purchasable_items = []
	for child in buy_skill_container.get_children():
		child.queue_free()
	for item_num in range(num_items_on_sale):
		var new_item = {}
		var random_skill = buyable_skills.pick_random().instantiate() as SkillStrategy
		if not random_skill:
			continue
		random_skill.count = 1
		new_item["skill"] = random_skill
		var new_skill_icon = skill_icon_scene.instantiate() as SkillIcon
		buy_skill_container.add_child(new_skill_icon)
		add_child(random_skill)
		new_item["cost"] = random_skill.cost
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
		print("Invalid buy")
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


func _on_reroll_skills_button_pressed() -> void:
	if grid_parent.soul_count >= reroll_cost:
		grid_parent.soul_count -= reroll_cost
		soul_count.text = "Souls: %s" % grid_parent.soul_count
		_stock_buyable_skills()
		reroll_cost += 1
		reroll_button.text = "Reroll Skills - %s souls" % reroll_cost
		$RerollSkillsBought.play()
	else:
		# too broke
		pass


func _on_remove_skill_button_pressed() -> void:
	grid_parent.stack_component.open_skill_bag_for_skill_removal()
