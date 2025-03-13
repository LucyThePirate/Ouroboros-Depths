extends Node2D

signal turn_ended

@onready var grid_entity = $GridEntity
@onready var display = $Display
@onready var visual = $Sprite2D
@onready var displayLerpTime = 0.0

var initialized = false
var level : Node2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	grid_entity.global_position = global_position
	display.global_position = grid_entity.global_position
	global_position = grid_entity.position


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not initialized:
		return
	global_position = grid_entity.position
	displayLerpTime += delta * 1.8
	display.global_position = display.global_position.lerp(grid_entity.global_position, min(1, displayLerpTime))
	#visual.global_position = visual.global_position.lerp(display.global_position, min(1, displayLerpTime))
	visual.global_position = display.global_position
	

func take_turn():
	move_randomly()


func move_randomly():
	var moveDirection = grid_entity.get_valid_moves().pick_random()
	if moveDirection:
		visual.global_position = grid_entity.global_position
		display.global_position = grid_entity.global_position
		var move_successful = grid_entity.move(moveDirection)
		if (not move_successful):
			display.global_position += Vector2(moveDirection) * 25
		displayLerpTime = 0.0
		#$Camera2D.make_current()
		#$Timer.start()
		turn_ended.emit()


func _on_grid_entity_grid_entity_initialized() -> void:
	if initialized:
		return
	initialized = true


func _on_grid_entity_hit() -> void:
	queue_free()


func _on_timer_timeout() -> void:
	turn_ended.emit()
