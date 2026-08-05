extends StatusStrategy


func on_death(is_despawning: bool, health_component: HealthComponent = null) -> bool:
	if is_despawning:
		return false
	power += 1
	if health_component:
		var max_health_penalty = abs(health_component.health) + 1
		if max_health_penalty >= health_component.max_health:
			return false
		health_component.set_health(1, health_component.max_health - max_health_penalty)
	return true


func on_next_floor_reached(health_component: HealthComponent = null):
	if power > 0:
		power -= 1
		if health_component:
			health_component.set_health(health_component.health, health_component.max_health + 1)


func on_turn_ended():
	pass
