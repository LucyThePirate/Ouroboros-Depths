extends Node

#region Terrain generation and Tiles
@onready var path_tile := [3, Vector2i(1, 3)]
@onready var room_floor_tile := [3, Vector2i(0, 3)]
@onready var glass_wall_tile := [2, Vector2i(3, 0)]
@onready var stone_wall_tile := [2, Vector2i(1, 0)]
@onready var boulder_object_tile := [2, Vector2i(3, 2)]
@onready var tall_tree_wall_tile := [3, Vector2i(3, 2)]
@onready var small_tree_wall_tile := [3, Vector2i(2, 3)]
@onready var clover_decor_tile := [3, Vector2i(3, 1)]
@onready var grass_floor_tile := [3, Vector2i(1, 3)]
@onready var stone_floor_tile := [2, Vector2i(0, 1)]
@onready var water_floor_tile := [3, Vector2i(0, 0)]
@onready var lilly_decor_tile := [3, Vector2i(3, 0)]
@onready var ice_floor_tile := [3, Vector2i(2, 1)]
@onready var door_horizontal_tile := [2, Vector2i(1, 2)]
@onready var door_vertical_tile := [2, Vector2i(2, 2)]
@onready var stairs_up_tile := [2, Vector2i(0, 2)]
@onready var stairs_down_tile := [2, Vector2i(0, 3)]
@onready var lock_tile := [2, Vector2i(4, 2)]
@onready var fog_tile := [3, Vector2i(1, 1)]

@onready var Floors := {"stone": [2, Vector2i(0, 1)]}
@onready var Walls := {"boulder": [2, Vector2i(3, 2)]}
#endregion
