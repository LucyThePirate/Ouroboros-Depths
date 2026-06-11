extends SkillStrategy


func _ready():
	super()


func use_skill(grid_entity: GridEntity):
	if grid_entity.health_component.health > 1:
		var grid_coords = Global.floors.local_to_map(grid_entity.global_position)
		grid_entity.spawn_entity.emit(grid_coords, grid_entity.species_type, self)
	super(grid_entity)


func on_entity_summoned(grid_entity: GridEntity, summoned_entity: CreatureAI):
	var new_health = grid_entity.health_component.health / 2
	grid_entity.health_component.set_health(new_health)
	summoned_entity.grid_entity.health_component.set_health(new_health)
	super(grid_entity, summoned_entity)
