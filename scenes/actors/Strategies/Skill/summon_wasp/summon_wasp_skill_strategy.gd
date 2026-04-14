extends SkillStrategy

@onready var wasp_type := GridEntity.Species.WASP
#@export var shield_status: PackedScene
#@export var power := 5


func _ready():
	super()


func use_skill(grid_entity: GridEntity):
	var grid_coords = Global.floors.local_to_map(grid_entity.global_position)
	grid_entity.spawn_entity.emit(grid_coords, wasp_type, self)
	super(grid_entity)


func on_entity_summoned(grid_entity: GridEntity, summoned_entity: CreatureAI):
	#var new_status = shield_status.instantiate() as StatusStrategy
	#new_status.power = power
	#summoned_entity.grid_entity.add_child(new_status)
	#var wasp_status_component = (
	#summoned_entity.grid_entity.status_component as StatusManagerComponent
	#)
	#wasp_status_component.add_status(new_status)
	super(grid_entity, summoned_entity)
