extends Node2D

signal finished_animation

var grid_entity: GridEntity
@export var animation_player: AnimationPlayer
@onready var anim_tree = self.get_node_or_null("%AnimationTree")
var run_speed := 0.0
var t := 0.0
const TIME_SCALE = 0.1


func initialize(new_grid_entity: GridEntity) -> void:
	grid_entity = new_grid_entity
	grid_entity.connect("moved", _on_grid_entity_moved)
	grid_entity.connect("hurt", _on_grid_entity_hurt)


func set_charging(is_charging: bool):
	use_parent_material = not is_charging
	if is_charging and animation_player.has_animation("Charging"):
		animation_player.play("Charging")
	elif animation_player.has_animation("Idle"):
		animation_player.play("Idle")


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
		if (
			animation_player.has_animation("Hide")
			and Global.walls.get_cell_tile_data(new_coords)
			and Global.walls.get_cell_tile_data(new_coords).get_custom_data("is_solid")
		):
			animation_player.play("Hide")
		elif animation_player.has_animation("Moving"):
			animation_player.play("Moving")


func _on_animation_player_animation_finished(_anim_name: StringName) -> void:
	finished_animation.emit()
	if animation_player.has_animation("Idle"):
		animation_player.play("Idle")


func _on_talked():
	if animation_player.has_animation("Talking"):
		animation_player.play("Talking")


func _on_fell_off_map():
	if animation_player.has_animation("Falling"):
		animation_player.play("Falling")


func _on_grid_entity_hurt(_attacker: GridEntity, _damage):
	if anim_tree:
		anim_tree.set("parameters/HurtOneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	else:
		if animation_player.has_animation("Hurt"):
			animation_player.play("Hurt")
