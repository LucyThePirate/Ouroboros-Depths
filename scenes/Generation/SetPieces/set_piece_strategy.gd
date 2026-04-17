extends Node2D

class_name SetPiece

@onready var floors = %Floors
@onready var walls = %Walls


func _ready() -> void:
	get_cell_shape(5)


func get_floor_pattern() -> TileMapPattern:
	return floors.get_pattern(floors.get_used_cells())


func get_wall_pattern() -> TileMapPattern:
	return walls.get_pattern(walls.get_used_cells())


func get_cell_shape(cell_size := 4):
	var cell_shape = Vector2i(
		ceili(floors.get_used_rect().size.x / float(cell_size)),
		ceili(floors.get_used_rect().size.y / float(cell_size))
	)
	return cell_shape


func get_cell_position() -> Vector2i:
	return floors.get_used_rect().position
