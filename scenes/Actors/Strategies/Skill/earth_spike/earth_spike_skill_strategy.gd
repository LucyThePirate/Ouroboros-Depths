extends SkillStrategy

var max_distance = 8

@export var earth_spike_projectile: PackedScene


func ready_skill(grid_entity: GridEntity) -> bool:
	request_direction()
	if show_UI:
		$Arrows.global_position = grid_entity.global_position
		$Arrows.show()
	return false


func use_skill(grid_entity: GridEntity):
	$Arrows.hide()
	state = SkillStrategy.States.PLAYING_ANIMATION
	##print("Used skill ", name, " towards ", direction)
	var new_star_VFX = earth_spike_projectile.instantiate()
	add_child(new_star_VFX)
	new_star_VFX.initialize(direction, grid_entity)
	if grid_entity.move(-direction):
		moved_self.emit()
	await new_star_VFX.exploded
	state = SkillStrategy.States.IDLE
	super(grid_entity)
