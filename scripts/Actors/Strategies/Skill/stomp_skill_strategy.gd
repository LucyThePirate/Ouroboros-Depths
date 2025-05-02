extends SkillStrategy

var shockwave_radius = 1


func use_skill(grid_entity: GridEntity) -> bool:
	print("Used skill ", name, " towards ", direction)
	$StompSound.play()
	return false
