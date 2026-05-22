extends SkillStrategy

@export var shield_status: PackedScene
@export var mobile_guard_status: PackedScene
@export var power := 5

var is_in_queue := false


func _ready():
	super()


func use_skill(grid_entity: GridEntity):
	var new_status = shield_status.instantiate() as StatusStrategy
	new_status.power = power
	add_child(new_status)

	gained_status.emit(new_status)
	super(grid_entity)


func on_skill_queued():
	var new_status = mobile_guard_status.instantiate() as StatusStrategy
	new_status.power = 1
	add_child(new_status)
	gained_status.emit(new_status)
