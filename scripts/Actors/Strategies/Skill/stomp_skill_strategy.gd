extends SkillStrategy

var shockwave_radius = 2
var damage = 1

@export var StompVFX: PackedScene


func _ready():
	super()


func use_skill(grid_entity: GridEntity):
	skill_crit = grid_entity.moved_by_skill
	if skill_crit:
		shockwave_radius += 1
		damage += 1
	print("Used skill ", name, " towards ", direction)
	var new_stomp_VFX = StompVFX.instantiate()
	add_child(new_stomp_VFX)
	new_stomp_VFX.global_position = grid_entity.global_position
	var grid_coords = Global.floors.local_to_map(grid_entity.global_position)
	var offset = -shockwave_radius + 1
	for i in range(shockwave_radius * 2 - 1):
		for j in range(shockwave_radius * 2 - 1):
			var checkingPosition = grid_coords + Vector2i(offset + i, offset + j)
			if (
				Global.entity_positions.has(checkingPosition)
				and is_instance_valid(Global.entity_positions[checkingPosition])
			):
				if Global.entity_positions[checkingPosition] == grid_entity:
					continue
				Global.entity_positions[checkingPosition]._on_hit(grid_entity, damage)
	if skill_crit:
		shockwave_radius -= 1
		damage -= 1
	super(grid_entity)
