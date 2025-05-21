extends Node2D

@onready var displayLerpTime = 0.0

@onready var sprite = $StarSprite

@onready var speed = 2000


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


func initialize(direction: Vector2, grid_entity: GridEntity):
	global_position = grid_entity.global_position
	sprite.global_position = grid_entity.global_position
	sprite.look_at(global_position + direction)
	sprite.rotate(PI / 2)
	$StarSprite/Launch.play()


func finish_flying():
	$StarSprite/Trail.emitting = false
	sprite.sprite_frames = null
	$StarSprite/Line2D.show()
	$AnimationPlayer.play("Impact")
	$Expiration.start()
	$StarSprite/Impact.global_position = global_position
	$StarSprite/Impact.emitting = true
	$StarSprite/Hit.play()


func _on_expiration_timeout() -> void:
	queue_free()
