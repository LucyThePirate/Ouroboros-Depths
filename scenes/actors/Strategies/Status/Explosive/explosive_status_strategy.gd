extends StatusStrategy
@export var explosion_VFX: PackedScene
var grid_parent: GridEntity
var bomb_placer: GridEntity
var used_effect := false


func on_grid_entity_parent_set(grid_entity: GridEntity):
	grid_parent = grid_entity


func on_turn_ended():
	pass


func on_death(is_despawning: bool, _health_component: HealthComponent = null) -> bool:
	if is_despawning:
		return false
	if used_effect or power <= 0:
		return false
	used_effect = true
	var grid_coords = grid_parent.grid_coords
	var new_explosion_VFX = explosion_VFX.instantiate()
	get_tree().current_scene.add_child(new_explosion_VFX)
	new_explosion_VFX.global_position = grid_parent.global_position
	var offset = -power + 1
	for i in range(power * 2 - 1):
		for j in range(power * 2 - 1):
			var check_coords = grid_coords + Vector2i(offset + i, offset + j)
			if Tiles.remove_wall_or_floor(check_coords):
				pass
			elif (
				Global.entity_positions.has(check_coords)
				and is_instance_valid(Global.entity_positions[check_coords])
			):
				if Global.entity_positions[check_coords] == grid_parent:
					continue
				grid_parent.hit(Global.entity_positions[check_coords], power * 2)
	power = 0
	return false
