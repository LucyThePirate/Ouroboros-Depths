extends SkillStrategy


func ready_skill(grid_entity: GridEntity) -> bool:
	%HissSFX.play()
	%AnimationPlayer.play("RESET")
	request_direction()
	return false


func use_skill(grid_entity: GridEntity):
	state = SkillStrategy.States.PLAYING_ANIMATION
	await get_tree().create_timer(0.025).timeout
	var check_coords = Global.floors.local_to_map(grid_entity.global_position) + direction
	%ChompVFX.global_position = Global.floors.map_to_local(check_coords)
	var wall_data = Global.walls.get_cell_tile_data(check_coords)
	if (
		Global.entity_positions.has(check_coords)
		and is_instance_valid(Global.entity_positions[check_coords])
	):
		var target = Global.entity_positions[check_coords] as GridEntity
		target.hurt.connect(on_chomp_dealt_damage)
		grid_entity.hit(target, 2, true)
		target.hurt.disconnect(on_chomp_dealt_damage)
	elif (
		wall_data
		and wall_data.get_custom_data("is_solid")
		and not wall_data.get_custom_data("indestructable")
	):
		%AnimationPlayer.play("chomp_hard")
		grid_entity.spawn_wall.emit(check_coords)
		grid_entity.health_component.deal_damage(2)
	else:
		%AnimationPlayer.play("chomp")
	state = SkillStrategy.States.IDLE
	super(grid_entity)


func on_chomp_dealt_damage(attacker: GridEntity, damage):
	if damage > 0:
		attacker.heal(damage)
		%AnimationPlayer.play("chomp_hit")
	else:
		attacker.health_component.deal_damage(2)
		%AnimationPlayer.play("chomp_hard")
