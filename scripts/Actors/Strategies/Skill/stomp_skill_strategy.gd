extends SkillStrategy

var shockwave_radius = 2
var damage = 1

@export var StompVFX: PackedScene

@export var note_VFX: PackedScene


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
			var check_coords = grid_coords + Vector2i(offset + i, offset + j)
			var new_note_VFX = note_VFX.instantiate()
			get_tree().current_scene.add_child(new_note_VFX)
			new_note_VFX.global_position = Global.floors.map_to_local(check_coords)
			if (
				Global.entity_positions.has(check_coords)
				and is_instance_valid(Global.entity_positions[check_coords])
			):
				if Global.entity_positions[check_coords] == grid_entity:
					continue
				grid_entity.hit(Global.entity_positions[check_coords], damage)
	if skill_crit:
		shockwave_radius -= 1
		damage -= 1
	super(grid_entity)
