extends Node2D


func _ready() -> void:
	Global.next_floor_reached.connect(despawn)


func despawn():
	queue_free()
