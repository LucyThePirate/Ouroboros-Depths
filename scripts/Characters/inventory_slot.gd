class_name InventorySlot extends Node

signal mouse_entered(item_name)
signal mouse_exited(item_name)

var item : item_data
var quantity : int
@onready var icon : TextureRect = get_node("Icon")
@onready var quantity_text : Label = get_node("QuantityText")
var inventory : Inventory


func set_item (new_item : item_data):
	item = new_item
	
	if item == null:
		icon.visible = false
		quantity = 0
	else:
		icon.visible = true
		icon.texture = item.icon
		quantity = new_item.quantity
	
	update_quantity_text()


func add_item():
	quantity += 1
	update_quantity_text()
	
	
func remove_item():
	quantity -= 1
	update_quantity_text()
	
	if quantity == 0:
		set_item(null)


func update_quantity_text():
	if quantity > 1:
		quantity_text.text = str(quantity)
	else:
		quantity_text.text = ""
	

func _on_pressed() -> void:
	if item == null:
		return
		
	print("Item: ", item.name, " used")


func _on_mouse_entered() -> void:
	if item == null:
		return
	mouse_entered.emit(item.name)


func _on_mouse_exited() -> void:
	if item == null:
		return
	mouse_exited.emit(item.name)
