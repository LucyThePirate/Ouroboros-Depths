extends Node2D

signal exploded

@onready var displayLerpTime = 0.0

@onready var sprite = $StarSprite
@export var note_VFX: PackedScene

@onready var speed = 2000
var max_distance = 8


func _ready():
	pass


func _process(delta):
	displayLerpTime += delta * 0.3
	#sprite.global_position = sprite.global_position.lerp(global_position, min(1, displayLerpTime))
	sprite.global_position = Vector2(
		move_toward(sprite.global_position.x, global_position.x, speed * delta),
		move_toward(sprite.global_position.y, global_position.y, speed * delta)
	)
	#visual.global_position = sprite.global_position


func initialize(direction: Vector2i, grid_entity: GridEntity):
	global_position = grid_entity.global_position
	sprite.global_position = grid_entity.global_position
	sprite.look_at(global_position + Vector2(direction))
	sprite.rotate(PI / 2)
	$StarSprite/Launch.play()
	var grid_coords = Global.floors.local_to_map(grid_entity.global_position) as Vector2i
	for i in range(max_distance):
		grid_coords += direction
		position += Vector2(Global.CELL_SIZE * direction)
		await get_tree().create_timer(0.05).timeout
		if grid_entity and grid_entity.is_obstructed(grid_coords, false):
			break
	explode_star(grid_coords, grid_entity, direction)


func _on_expiration_timeout() -> void:
	queue_free()


func explode_star(grid_coords, grid_entity, attack_direction):
	var star_points = [
		Vector2.ZERO, Vector2(1, 0), Vector2(0, -1), Vector2(0, 1), Vector2(-1, -1), Vector2(-1, 1)
	]
	for point in star_points:
		var rotated_point = point.rotated(Vector2(attack_direction).angle())
		var check_coords = Vector2i(round(rotated_point.x), round(rotated_point.y)) + grid_coords
		#print(
		#"checking:", check_coords, "point:", Vector2i(point.rotated(Vector2(direction).angle()))
		#)
		#grid_entity.spawn_tile.emit(check_coords)
		var new_note_VFX = note_VFX.instantiate()
		get_tree().current_scene.add_child(new_note_VFX)
		new_note_VFX.global_position = Global.floors.map_to_local(check_coords)
		if (
			Global.entity_positions.has(check_coords)
			and is_instance_valid(Global.entity_positions[check_coords])
		):
			if point == Vector2.ZERO:
				Global.entity_positions[check_coords]._on_hit(grid_entity)
			else:  # Skill crit
				Global.entity_positions[check_coords]._on_hit(grid_entity, 2)
	exploded.emit()
	finish_flying()


func finish_flying():
	$StarSprite/Trail.emitting = false
	sprite.sprite_frames = null
	$StarSprite/Line2D.show()
	$AnimationPlayer.play("Impact")
	$Expiration.start()
	$StarSprite/Impact.global_position = global_position
	$StarSprite/Impact.emitting = true
	$StarSprite/Hit.play()
