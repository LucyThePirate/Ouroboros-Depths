extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# Get the input direction and handle the movement/deceleration.
	var direction = Vector2()
	direction.x = Input.get_axis("Left", "Right")
	direction.y = Input.get_axis("Up", "Down")
	if direction:
		if direction.length() > 1:
			direction = direction.normalized()
		%CreatureComponent.move_in_direction(direction)
		global_position = %CreatureComponent.global_position
	
	# Handle rotation
	var mouse_distance = get_global_mouse_position() - %CreatureComponent.global_position
	%CreatureComponent.point_towards(get_global_mouse_position())
	%CameraRotation.look_at(get_global_mouse_position())
	
	# Handle attacking
	if Input.is_action_just_pressed("MainHand"):
		%CreatureComponent.attack()
	
