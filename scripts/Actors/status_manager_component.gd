extends Node2D

class_name StatusManagerComponent

var grid_entity: GridEntity
var turn_component: TurnComponent
var active_statuses := []


func _ready() -> void:
	active_statuses = Debug.find_children_in_group(self, "Status")
