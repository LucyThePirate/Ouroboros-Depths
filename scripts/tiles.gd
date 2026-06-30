extends Node

@onready var boulder_splash_vfx := preload("uid://dm6okwh3ft3uu")

#region Terrain generation and Tiles
@onready var path_tile := [3, Vector2i(1, 3)]

@onready var glass_wall_tile := [2, Vector2i(3, 0)]
@onready var stone_wall_tile := [2, Vector2i(1, 0)]
@onready var dirt_wall_tile := [2, Vector2i(1, 4)]
@onready var boulder_object_tile := [2, Vector2i(3, 2)]
@onready var tall_tree_wall_tile := [3, Vector2i(3, 2)]
@onready var small_tree_wall_tile := [3, Vector2i(2, 3)]
@onready var lilly_decor_tile := [3, Vector2i(3, 0)]
@onready var clover_decor_tile := [3, Vector2i(3, 1)]
@onready var ice_wall_tile := [2, Vector2i(4, 4)]
@onready var plant_wall_tile := [2, Vector2i(5, 0)]
@onready var wood_wall_tile := [2, Vector2i(1, 2)]
@onready var snow_wall_tile := [2, Vector2i(7, 2)]

@onready var grass_floor_tile := [3, Vector2i(1, 3)]
@onready var stone_floor_tile := [2, Vector2i(0, 1)]
@onready var dirt_floor_tile := [2, Vector2i(0, 5)]
@onready var water_floor_tile := [3, Vector2i(0, 0)]
@onready var wood_floor_tile := [3, Vector2i(0, 3)]
@onready var plant_floor_tile := [2, Vector2i(4, 1)]
@onready var glass_floor_tile := [2, Vector2i(2, 1)]
@onready var ice_floor_tile := [3, Vector2i(2, 1)]
@onready var snow_floor_tile := [2, Vector2i(2, 5)]

@onready var door_horizontal_tile := [2, Vector2i(1, 2)]
@onready var door_vertical_tile := [2, Vector2i(2, 2)]

@onready var stairs_up_tile := [2, Vector2i(0, 2)]
@onready var stairs_down_tile := [2, Vector2i(0, 3)]
@onready var lock_tile := [2, Vector2i(4, 2)]
@onready var fog_tile := [3, Vector2i(1, 1)]
@onready var random_monster_tile := [2, Vector2i(9, 0)]

@onready var Floors := {
	"stone": stone_floor_tile,
	"dirt": dirt_floor_tile,
	"wood": wood_floor_tile,
	"plant": plant_floor_tile,
	"glass": glass_floor_tile,
	"ice": ice_floor_tile,
	"snow": snow_floor_tile
}
@onready var Walls := {
	"boulder": boulder_object_tile,
	"stone": stone_wall_tile,
	"dirt": dirt_wall_tile,
	"glass": glass_wall_tile,
	"ice": ice_wall_tile,
	"snow": snow_wall_tile,
	"wood": wood_wall_tile,
	"plant": plant_wall_tile,
	"grass": plant_wall_tile
}
#endregion


# Returns true if there is/was a wall
func remove_wall_or_floor(coords) -> bool:
	var wall_data = Global.walls.get_cell_tile_data(coords)
	if wall_data and wall_data.get_custom_data("indestructable"):
		return true
	elif wall_data and wall_data.get_custom_data("is_solid"):
		Global.walls.set_cell(coords, -1)
		return true
	# No destructable wall, try the floor now
	var floor_data = Global.floors.get_cell_tile_data(coords)
	if floor_data and floor_data.get_custom_data("indestructable"):
		return false
	elif floor_data:
		Global.walls.set_cell(coords, -1)
		Global.floors.set_cell(coords, -1)
		return false
	# Nothing destroyale there at all
	return false


# Try to move a wall. Returns false if the wall being moved is destroyed.
func move_wall(old_coords, new_coords) -> bool:
	var old_wall_data = Global.walls.get_cell_tile_data(old_coords)
	if (
		not old_wall_data
		or not old_wall_data.get_custom_data("is_solid")
		or old_wall_data.get_custom_data("indestructable")
	):
		return true

	# Check if there's already a wall at the new location
	var new_wall_data = Global.walls.get_cell_tile_data(new_coords)
	if new_wall_data and new_wall_data.get_custom_data("is_solid"):
		return true

	# Check if the wall is going to sink into the ground
	var new_floor_data = Global.floors.get_cell_tile_data(new_coords)
	if not new_floor_data:
		spawn_floor(new_coords, old_wall_data.get_custom_data("material"))
		Global.walls.set_cell(old_coords, -1)
		return false
	if (
		new_floor_data.get_custom_data("is_liquid")
		and not new_floor_data.get_custom_data("indestructable")
	):
		var splashVFX = boulder_splash_vfx.instantiate()
		get_tree().current_scene.add_child(splashVFX)
		splashVFX.global_position = Global.floors.map_to_local(new_coords)
		spawn_floor(new_coords, old_wall_data.get_custom_data("material"))
		Global.walls.set_cell(old_coords, -1)
		return false

	# Move the wall
	Global.walls.set_pattern(new_coords, Global.walls.get_pattern([old_coords]))
	Global.walls.set_cell(old_coords, -1)
	return true


func spawn_floor(coords, material := "nothing"):
	if material in Floors.keys():
		Global.floors.set_cell(coords, Tiles.Floors[material][0], Tiles.Floors[material][1])
	else:
		Global.floors.set_cell(coords, -1)


func spawn_wall(coords, material := "nothing"):
	if material in Walls.keys():
		Global.walls.set_cell(coords, Tiles.Walls[material][0], Tiles.Walls[material][1])
	else:
		Global.walls.set_cell(coords, -1)
