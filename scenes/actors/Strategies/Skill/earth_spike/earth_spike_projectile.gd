extends Node2D

signal exploded

@onready var displayLerpTime = 0.0

@onready var sprite = $StarSprite

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
		grid_entity.spawn_wall.emit(grid_coords, Tiles.Walls["boulder"])
	explode_star(grid_coords, grid_entity, direction)


func _on_expiration_timeout() -> void:
	queue_free()


func explode_star(grid_coords, grid_entity, attack_direction):
	var star_points = [
		Vector2.ZERO,
		Vector2(1, 0),
		Vector2(1, 1),
		Vector2(0, 1),
		Vector2(-1, 1),
		Vector2(-1, 0),
		Vector2(-1, -1),
		Vector2(0, -1),
		Vector2(1, -1)
	]
	for point in star_points:
		var rotated_point = point.rotated(Vector2(attack_direction).angle())
		var check_coords = Vector2i(round(rotated_point.x), round(rotated_point.y)) + grid_coords
		if (
			Global.entity_positions.has(check_coords)
			and is_instance_valid(Global.entity_positions[check_coords])
		):
			grid_entity.hit(Global.entity_positions[check_coords])
		elif point != Vector2.ZERO:
			grid_entity.spawn_wall.emit(check_coords, Tiles.Walls["boulder"])

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
