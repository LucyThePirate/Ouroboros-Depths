extends SkillStrategy

@onready var wasp_scene := preload("uid://v4jyo2omhd1l")


func _ready():
	super()


func use_skill(grid_entity: GridEntity):
	var grid_coords = Global.floors.local_to_map(grid_entity.global_position)
	grid_entity.spawn_entity.emit(grid_coords, wasp_scene)
	super(grid_entity)
