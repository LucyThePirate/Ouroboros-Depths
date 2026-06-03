extends Node2D

class_name SetPiece

@onready var floors = %Floors
@onready var walls = %Walls


func _ready() -> void:
	print("cell shape:", get_cell_shape(4))


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


# Returns a dict of the form: {Vector2i(position): Vector2i(external_direction)}
# Can return an empty dictionary if no exposed doors
func get_exposed_doors() -> Dictionary:
	var exposed_doors = {}
	for h_d in walls.get_used_cells_by_id(
		Tiles.door_horizontal_tile[0], Tiles.door_horizontal_tile[1]
	):
		for direction_to_check in [Vector2i.UP, Vector2i.DOWN]:
			if not floors.get_cell_tile_data(h_d + direction_to_check):
				exposed_doors[h_d] = direction_to_check
				continue
	for v_d in walls.get_used_cells_by_id(Tiles.door_vertical_tile[0], Tiles.door_vertical_tile[1]):
		for direction_to_check in [Vector2i.LEFT, Vector2i.RIGHT]:
			if not floors.get_cell_tile_data(v_d + direction_to_check):
				exposed_doors[v_d] = direction_to_check
				continue

	return exposed_doors


func get_set_piece_size():
	return floors.get_used_rect().size


func get_cell_position() -> Vector2i:
	return floors.get_used_rect().position


func get_non_tile_map_children() -> Array:
	var return_array = []
	for child_node in get_children():
		if child_node is not TileMapLayer:
			return_array.append(child_node)
	return return_array
