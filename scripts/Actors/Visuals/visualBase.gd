extends Node2D

signal finished_animation

var parent: Node2D
var grid_entity: GridEntity
@onready var animation_player = $AnimationPlayer as AnimationPlayer
@onready var anim_tree = $AnimationTree if $AnimationTree else null
var run_speed := 0.0
var t := 0.0
const TIME_SCALE = 0.1


func initialize(new_grid_entity: GridEntity) -> void:
	grid_entity = new_grid_entity
	grid_entity.connect("moved", _on_grid_entity_moved)
	grid_entity.connect("hurt", _on_grid_entity_hurt)


func _process(delta: float) -> void:
	t += delta * TIME_SCALE
	run_speed = clampf(lerpf(run_speed, 0, t), 0, 2)
	if run_speed < 0.25:
		run_speed = 0
	if anim_tree:
		anim_tree.set("parameters/RunBlend/blend_amount", run_speed)


func _on_grid_entity_moved(old_coords: Vector2i, new_coords: Vector2i):
	#print("Moved from", old_coords, "to", new_coords)
	t = 0
	run_speed = clampf((new_coords - old_coords).length() * 2, 0, 2)
	var xDifference = new_coords.x - old_coords.x
	if xDifference:
		if xDifference > 0 and scale.x < 0:
			scale.x *= -1
		elif xDifference < 0 and scale.x > 0:
			scale.x *= -1
	if not anim_tree:
		animation_player.play("Moving")


func _on_animation_player_animation_finished(_anim_name: StringName) -> void:
	finished_animation.emit()
	animation_player.play("Idle")


func _on_talked():
	animation_player.play("Talking")


func _on_fell_off_map():
	animation_player.play("Falling")


func _on_grid_entity_hurt(_attacker: GridEntity):
	if anim_tree:
		anim_tree.set("parameters/HurtOneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	else:
		animation_player.play("Hurt")
