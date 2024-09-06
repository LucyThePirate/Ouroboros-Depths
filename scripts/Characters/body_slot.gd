class_name BodySlot extends Node

var part : part_data
@onready var icon : TextureRect = get_node("Icon")
@onready var label : Label = get_node("Label")
var body : Body

func set_part (new_part : part_data):
	part = new_part
	
	if part == null:
		icon.visible = false
	else:
		icon.visible = true
		icon.texture = part.icon
	
