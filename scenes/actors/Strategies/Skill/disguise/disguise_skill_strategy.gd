extends SkillStrategy

@export var smoke_scene: PackedScene
@export var hidden_status_scene: PackedScene
@export var power := 5
var radius = 4


func _ready():
	super()


func use_skill(grid_entity: GridEntity):
	var hiding_spots = []
	var grid_coords = Global.floors.local_to_map(grid_entity.global_position)
	var offset = -radius + 1
	for i in range(radius * 2 - 1):
		for j in range(radius * 2 - 1):
			var check_coords = grid_coords + Vector2i(offset + i, offset + j)
			var wall_data = Global.walls.get_cell_tile_data(check_coords)
			if (
				wall_data
				and wall_data.get_custom_data("is_solid")
				and not Global.entity_positions.has(check_coords)
			):
				hiding_spots.append(check_coords)
	if hiding_spots.size() > 0:
		var new_smoke = smoke_scene.instantiate()
		new_smoke.global_position = grid_entity.global_position
		get_tree().current_scene.add_child(new_smoke)
		var can_walk_through_walls = grid_entity.can_walk_through_walls
		grid_entity.can_walk_through_walls = true
		grid_entity.warp(hiding_spots.pick_random())
		grid_entity.can_walk_through_walls = can_walk_through_walls
		var new_status = hidden_status_scene.instantiate() as StatusStrategy
		new_status.power = power
		add_child(new_status)
		gained_status.emit(new_status)
	super(grid_entity)
