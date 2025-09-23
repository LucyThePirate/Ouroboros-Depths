extends Node2D

var target: GridEntity

var speed := 100
var block_range := 3


func _ready() -> void:
	Global.next_floor_reached.connect(queue_free)
	_find_target()


func _process(delta: float) -> void:
	if target and target.is_alive():
		global_position = global_position.move_toward(target.global_position, delta * speed)
	else:
		_find_target()


func _find_target():
	var entities = get_tree().get_nodes_in_group("GridEntity")
	for entity in entities:
		if entity.is_in_group("Player"):
			target = entity
			break
	if not (target and target.is_alive()):
		target = entities.pick_random()


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("GridEntity"):
		body.on_death()


func _on_messwith_blocks_timer_timeout() -> void:
	var block_1_coords = Global.floors.local_to_map(global_position)
	var block_2_coords = Global.floors.local_to_map(global_position)
	block_1_coords += Vector2i(
		randi_range(-block_range, block_range), randi_range(-block_range, block_range)
	)
	block_2_coords += Vector2i(
		randi_range(-block_range, block_range), randi_range(-block_range, block_range)
	)
	var block_1 = Global.floors.get_cell_tile_data(block_1_coords) as TileData
	var block_2 = Global.floors.get_cell_tile_data(block_2_coords) as TileData
	if (
		not block_1
		or not block_2
		or block_1.get_custom_data("indestructable")
		or block_2.get_custom_data("indestructable")
	):
		return
	# Swap floors
	var temp_source_id = Global.floors.get_cell_source_id(block_1_coords)
	var temp_atlas_coords = Global.floors.get_cell_atlas_coords(block_1_coords)
	Global.floors.set_cell(
		block_1_coords,
		Global.floors.get_cell_source_id(block_2_coords),
		Global.floors.get_cell_atlas_coords(block_2_coords)
	)
	Global.floors.set_cell(block_2_coords, temp_source_id, temp_atlas_coords)
	# Swap walls
	temp_source_id = Global.walls.get_cell_source_id(block_1_coords)
	temp_atlas_coords = Global.walls.get_cell_atlas_coords(block_1_coords)
	Global.walls.set_cell(
		block_1_coords,
		Global.walls.get_cell_source_id(block_2_coords),
		Global.walls.get_cell_atlas_coords(block_2_coords)
	)
	Global.walls.set_cell(block_2_coords, temp_source_id, temp_atlas_coords)
