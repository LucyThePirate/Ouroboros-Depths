class_name Inventory extends Node

var slots : Array[InventorySlot]
@onready var window : Panel = get_node("InventoryWindow")
@onready var info_text : Label = get_node("InventoryWindow/InfoText")
@export var starter_items : Array[item_data]
var inventory_owner : Creature

func _ready ():
	toggle_window(false)
	# Initialize inventory slots
	for child in get_node("InventoryWindow/SlotContainter").get_children():
		slots.append(child)
		child.set_item(null)
		child.inventory = self
		child.hovered_over.connect(_on_slot_mouse_entered)
		child.hovered_off.connect(_on_slot_mouse_exited)
	
	for item in starter_items:
		add_item(item)
		
	info_text.text = ""


func _process (_delta):
	if Input.is_action_just_pressed("Inventory") and inventory_owner.is_in_group("player"):
		toggle_window(!window.visible)
		if window.visible:
			_debug_output_inventory()


func toggle_window (open : bool):
	window.visible = open


func add_item (item : item_data):
	var slot = get_slot_to_add(item)
	
	if slot == null: # Inventory full
		return

	if slot.item == null: # Can't stack with anything
		slot.set_item(item)
	elif slot.item == item: # Found a slot to stack with
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


func _debug_output_inventory():
	for slot in slots:
		if slot.item != null:
			print("item:", slot.item.name)
