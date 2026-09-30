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
	grid_entity.connect("slapped", _on_grid_entity_slapped)
	grid_entity.connect("thumped", _flip_grid_entity_check)


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
	_flip_grid_entity_check(old_coords, new_coords)
	if not anim_tree:
		if (
			animation_player.has_animation("Hide")
			and Global.walls.get_cell_tile_data(new_coords)
			and Global.walls.get_cell_tile_data(new_coords).get_custom_data("is_solid")
		):
			animation_player.play("Hide")
		elif animation_player.has_animation("Moving"):
			animation_player.play("Moving")
			animation_player.seek(0)


func _flip_grid_entity_check(old_coords: Vector2i, new_coords: Vector2i):
	var xDifference = new_coords.x - old_coords.x
	if xDifference:
		if xDifference > 0 and scale.x < 0:
			scale.x *= -1
		elif xDifference < 0 and scale.x > 0:
			scale.x *= -1


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


func play(animation_name: StringName, _sentinel1 = 0, _sentinel2 = 0):
	if _sentinel1 or _sentinel2:
		print("Found you!")
	if animation_player.has_animation(animation_name):
		animation_player.play(animation_name)
		animation_player.seek(0)


func _on_grid_entity_hurt(_attacker: GridEntity, _damage):
	if anim_tree:
		anim_tree.set("parameters/HurtOneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	else:
		if animation_player.has_animation("Hurt"):
			animation_player.play("Hurt")
			animation_player.seek(0)


func _on_grid_entity_slapped(victim: GridEntity):
	if animation_player.has_animation("Attack"):
		animation_player.play("Attack")
		animation_player.seek(0)
	_flip_grid_entity_check(grid_entity.grid_coords, victim.grid_coords)
