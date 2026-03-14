# based loosely on https://www.youtube.com/watch?v=Bhc_EBasycY
extends Node2D

@export var target_position: Vector2

const MAX_POINTS = 100


func _process(delta: float) -> void:
	global_position = get_global_mouse_position()
	%Trail.add_point(global_position)
	if %Trail.points.size() > MAX_POINTS:
		%Trail.remove_point(0)
