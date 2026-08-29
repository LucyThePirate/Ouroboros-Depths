extends SkillStrategy

var shockwave_radius = 3

@export var StompVFX: PackedScene


func _ready():
	super()


func use_skill(grid_entity: GridEntity):
	var new_stomp_VFX = StompVFX.instantiate()
	add_child(new_stomp_VFX)
	new_stomp_VFX.global_position = grid_entity.global_position
	var grid_coords = grid_entity.grid_coords
	var offset = -shockwave_radius + 1
	for i in range(shockwave_radius * 2 - 1):
		for j in range(shockwave_radius * 2 - 1):
			var check_coords = grid_coords + Vector2i(offset + i, offset + j)
			var wall_data = Global.walls.get_cell_tile_data(check_coords)
			var floor_data = Global.floors.get_cell_tile_data(check_coords)
			if wall_data and wall_data.get_custom_data("is_solid"):
				if (
					wall_data.get_custom_data("indestructable")
					or (floor_data and floor_data.get_custom_data("indestructable"))
				):
					continue
				Tiles.spawn_floor(check_coords, wall_data.get_custom_data("material"))
				Tiles.remove_wall_or_floor(check_coords)
			elif floor_data and not floor_data.get_custom_data("indestructable"):
				Tiles.spawn_wall(check_coords, floor_data.get_custom_data("material"))
	super(grid_entity)
