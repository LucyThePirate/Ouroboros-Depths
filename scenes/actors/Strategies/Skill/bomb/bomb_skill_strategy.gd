extends SkillStrategy

@onready var bomb_type := GridEntity.Species.BOMB
#@export var shield_status: PackedScene
#@export var power := 5


func _ready():
	super()


func ready_skill(grid_entity: GridEntity) -> bool:
	request_direction()
	return false


func use_skill(grid_entity: GridEntity):
	var grid_coords = grid_entity.grid_coords + direction
	grid_entity.spawn_entity.emit(grid_coords, bomb_type, self)
	super(grid_entity)


func on_entity_summoned(_grid_entity: GridEntity, _summoned_entity: CreatureAI):
	pass
