class_name Inventory extends Node

@export var max_size : int = 88

var slots : Array[InventorySlot]
var inventory_count = 0
@onready var window : Panel = get_node("InventoryWindow")
@onready var info_text : Label = get_node("InventoryWindow/InfoText")
@export var starter_items : Array[item_data]

func _ready ():
	toggle_window(false)
	# Initialize inventory slots
	for child in get_node("InventoryWindow/SlotContainter").get_children():
		slots.append(child)
		child.set_item(null)
		child.inventory = self
		child.mouse_entered.connect(_on_slot_mouse_entered)
		child.mouse_exited.connect(_on_slot_mouse_exited)
	
	for item in starter_items:
		add_item(item)
		
	info_text.text = ""


func _process (delta):
	if Input.is_action_just_pressed("Inventory"):
		toggle_window(!window.visible)


func toggle_window (open : bool):
	window.visible = open


func on_give_player_item (item : item_data, amount : int):
	pass


func add_item (item : item_data):
	var slot = get_slot_to_add(item)
	
	if slot == null: # Inventory full
		return
		
	if slot.item == null:
		slot.set_item(item)
	elif slot.item == item:
		slot.add_item()


func remove_item (item : item_data):
	var slot = get_slot_to_remove(item)
	
	if slot == null or slot.item == item:
		return
	
	slot.remove_item()


func get_slot_to_add (item : item_data) -> InventorySlot:
	if item.max_stack_size > 1:
		for slot in slots: # Find a stackable copy of this item, if possible
			if slot.item == item and slot.quantity < item.max_stack_size:
				return slot
	
	# Can't stack with anything, find an empty slot instead.
	for slot in slots:
		if slot.item == null:
			return slot
	
	return null


func get_slot_to_remove (item : item_data) -> InventorySlot:
	for slot in slots:
		if slot.item == item:
			return slot
			
	return null


func get_number_of_item (item : item_data) -> int:
	var total = 0
	
	for slot in slots:
		if slot.item == item:
			total += slot.quantity
	
	return total


func _on_slot_mouse_entered(item_name : String):
	info_text.text = item_name
	
	
func _on_slot_mouse_exited():
	info_text.text = ""
