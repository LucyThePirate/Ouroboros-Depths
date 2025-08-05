extends GridEntity

var grid_coords: Vector2i


func _ready() -> void:
	global_position = Global.floors.map_to_local(Global.floors.local_to_map(global_position))
	grid_coords = Global.floors.local_to_map(global_position)
	Global.turn_passed.connect(_on_turn_passed)


func _on_turn_passed():
	if Global.entity_positions.has(grid_coords):
		queue_free()


func _on_turn_component_turn_ended() -> void:
	turn_component.end_turn()


func on_death() -> void:
	pass
