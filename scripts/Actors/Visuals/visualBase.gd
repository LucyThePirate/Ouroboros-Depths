extends Node2D

var parent: Node2D
var grid_entity: GridEntity
@onready var animation_player = $AnimationPlayer


func initialize(new_grid_entity: GridEntity) -> void:
	grid_entity = new_grid_entity
	grid_entity.connect("moved", _on_moved)


func _on_moved(old_coords: Vector2i, new_coords: Vector2i):
	#print("Moved from", old_coords, "to", new_coords)
	animation_player.play("Moving")


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	animation_player.play("Idle")
