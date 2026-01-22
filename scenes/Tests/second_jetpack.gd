extends Node2D


func _physics_process(delta: float) -> void:
	var towards_mouse_force = (get_global_mouse_position() - %"Bone-0".global_position) * 15
	for child in %Coco.get_children():
		if child is RigidBody2D:
			child.apply_force(towards_mouse_force)
