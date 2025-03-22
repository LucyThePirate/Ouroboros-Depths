extends Node2D

signal turn_ended

@onready var grid_entity = $GridEntity
@onready var display = $Display
@onready var visual = $LichTest
@onready var displayLerpTime = 0.0

var initialized = false

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
	
	if not grid_entity.my_turn:
		return
	
	var moveDirection = Input.get_vector("Left", "Right", "Up", "Down")
	if moveDirection and (Input.is_action_just_pressed("Left") or Input.is_action_just_pressed("Right") or Input.is_action_just_pressed("Down") or Input.is_action_just_pressed("Up")):
		visual.global_position = grid_entity.global_position
		display.global_position = grid_entity.global_position
		var move_successful = grid_entity.move(moveDirection)
		if (not move_successful):
			display.global_position += moveDirection * 25
		else:
			end_turn()
		displayLerpTime = 0.0
	
	elif Input.is_action_just_pressed("Wait"):
		end_turn()
		return


func _on_grid_entity_grid_entity_initialized() -> void:
	if initialized:
		return
	initialized = true
	global_position = grid_entity.position


func _on_grid_entity_hit() -> void:
	queue_free()


func end_turn():
	grid_entity.end_turn()
