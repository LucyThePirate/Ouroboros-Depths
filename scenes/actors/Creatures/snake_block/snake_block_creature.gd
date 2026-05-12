extends CreatureAI

var block_segments = []
var block_pattern
var block_data
const MAX_BLOCK_SIZE = 10


func _on_grid_entity_moved(old_coord: Vector2i, new_coord: Vector2i) -> void:
	if old_coord == new_coord:
		return
	%Sprite2D.rotation = (Vector2(new_coord) - Vector2(old_coord)).angle()

	if block_segments.size() > 0:
		var tail_block = block_segments.pop_back()
		if Global.walls.get_cell_tile_data(tail_block) != block_data:
			block_segments.pop_back()
			health_component.deal_damage(2)
			health_component.max_health -= 2

		else:
			Global.walls.set_cell(tail_block, -1)
		Global.walls.set_pattern(new_coord, block_pattern)
		block_segments.push_front(new_coord)
	elif Global.walls.get_cell_tile_data(new_coord):
		_form_block_snake()


func _on_grid_entity_grid_entity_initialized() -> void:
	super()
	_form_block_snake()


func _form_block_snake() -> void:
	var starting_coords = Global.floors.local_to_map(grid_entity.global_position)
	block_data = Global.walls.get_cell_tile_data(starting_coords)
	if (
		not block_data
		or not block_data.get_custom_data("is_solid")
		or block_data.get_custom_data("indestructable")
	):
		return
	block_pattern = Global.walls.get_pattern([starting_coords])
	block_segments.push_front(starting_coords)
	var adjacent = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
	var checking_coords = starting_coords
	var found_new_block_segment = false
	while block_segments.size() < MAX_BLOCK_SIZE:
		found_new_block_segment = false
		adjacent.shuffle()
		for a in adjacent:
			var current_coords = checking_coords + a
			if Global.walls.get_cell_tile_data(current_coords) == block_data:
				if current_coords not in block_segments:
					block_segments.push_back(current_coords)
					checking_coords = current_coords
					found_new_block_segment = true
		if not found_new_block_segment:
			break
	health_component.max_health += block_segments.size() * 2
	health_component.heal(block_segments.size() * 2)
	grid_entity.can_walk_through_walls = false
