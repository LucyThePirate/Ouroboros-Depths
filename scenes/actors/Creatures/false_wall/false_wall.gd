extends CreatureAI


func _ready() -> void:
	%WallCracks.frame = 0
	super()


func _on_grid_entity_died(is_despawning) -> void:
	if not is_despawning:
		Tiles.remove_wall_or_floor(grid_entity.grid_coords)
	super(is_despawning)


func _on_grid_entity_hurt(attacker: GridEntity, damage_amount: int) -> void:
	super(attacker, damage_amount)
	var missing_health = (
		grid_entity.health_component.max_health - grid_entity.health_component.health
	)
	%EggCrack.volume_db = missing_health
	%EggCrack.pitch_scale = 1.2 - (0.08 * missing_health)
	%EggCrack.play()
	%WallCracks.frame = missing_health
