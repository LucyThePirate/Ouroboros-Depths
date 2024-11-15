extends Node2D

@onready var grid_entity = $GridEntity

var initialized = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	grid_entity.global_position = global_position


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not initialized:
		return
		
	global_position = grid_entity.position
	var moveDirection = Input.get_vector("Left", "Right", "Up", "Down")
	if moveDirection and (Input.is_action_just_pressed("Left") or Input.is_action_just_pressed("Right") or Input.is_action_just_pressed("Down") or Input.is_action_just_pressed("Up")):
		grid_entity.move(moveDirection)
		


func _on_grid_entity_grid_entity_initialized() -> void:
	if initialized:
		return
	initialized = true
