extends StatusStrategy

var is_active := false


func on_grid_entity_parent_set(grid_entity: GridEntity):
	%RemoteTransform2D.remote_path = grid_entity.get_path()


func on_turn_ended():
	if not is_active:
		return
	current_turns_afflicted -= 1
	if current_turns_afflicted <= 0:
		harmed.emit(power)
		current_turns_afflicted = turns_afflicted
		_update_visuals()
	if power <= 0:
		on_status_ended()


func modify_incoming_damage(incoming_damage := 1) -> int:
	if incoming_damage > 0:
		is_active = true
		%SparkParticles.emitting = true
		%FuseSFX.play()
	return incoming_damage
