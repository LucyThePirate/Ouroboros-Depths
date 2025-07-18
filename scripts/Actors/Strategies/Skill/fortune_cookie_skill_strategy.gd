extends SkillStrategy

@export var heal_amount := 2


func _ready():
	super()


func use_skill(grid_entity: GridEntity):
	grid_entity.heal(heal_amount)
	super(grid_entity)
