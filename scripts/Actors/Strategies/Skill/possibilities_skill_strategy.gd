extends SkillStrategy

@export var metamorphosis_scene: PackedScene


func _ready():
	super()


func use_skill(grid_entity: GridEntity):
	var new_metamorphosis = metamorphosis_scene.instantiate() as Metamorphosis
	add_child(new_metamorphosis)
	for i in range(3):
		var new_skill = (
			new_metamorphosis.buyable_skills.pick_random().instantiate() as SkillStrategy
		)
		new_skill.count = 1
		grid_entity.stack_component.add_child(new_skill)
		grid_entity.stack_component.add_skill(new_skill)
	new_metamorphosis.queue_free()
	super(grid_entity)
