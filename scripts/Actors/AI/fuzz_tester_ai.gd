extends CreatureAI

@export var metamorphosis_scene: PackedScene


func _ready() -> void:
	super()
	var new_metamorphosis = metamorphosis_scene.instantiate() as Metamorphosis
	add_child(new_metamorphosis)
	for i in range(3):
		var new_skill = new_metamorphosis.buyable_skills.pick_random().instantiate()
		grid_entity.stack_component.add_child(new_skill)
		grid_entity.stack_component.add_skill(new_skill)
	new_metamorphosis.queue_free()


func _on_detection_radius_body_entered(body: Node2D) -> void:
	if angry_at:
		return
	_update_angry_at(body)
