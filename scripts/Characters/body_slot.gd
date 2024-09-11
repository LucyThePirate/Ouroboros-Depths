class_name BodySlot extends Node

var part : base_part_strategy
@onready var icon : TextureRect = get_node("Icon")
@onready var label : Label = get_node("Label")
var body : Body

func set_part (new_part : base_part_strategy):
	part = new_part
	
	if part == null:
		icon.visible = false
	else:
		icon.visible = true
		icon.texture = part.icon
	
