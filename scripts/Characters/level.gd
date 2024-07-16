extends Node2D

@export var map : TileMap

@export var last_player_map_position : Vector2i

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_player_brain_component_uncovered_fog(location, radius : int = 1):
	if not map:
		return
	var map_coordinates = map.local_to_map(location)
	if map_coordinates == last_player_map_position:
		return
	last_player_map_position = map_coordinates
	for x in range(0, (radius * 2) + 1):
		for y in range(0, (radius * 2) + 1):
			map.set_cell(-1, map_coordinates + Vector2i(x - (radius), y - (radius)), -1)


func _on_player_brain_component_tiles_lit(light_body):
	map.erase_cell(-1, map.get_coords_for_body_rid(light_body))
