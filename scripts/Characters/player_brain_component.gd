extends Node2D

signal uncovered_fog(creature)

# Called when the node enters the scene tree for the first time.
func _ready():
	uncover_fog(%CreatureComponent)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	# Get the input direction and handle the movement/deceleration.
	var direction = Vector2()
	direction.x = Input.get_axis("Left", "Right")
	direction.y = Input.get_axis("Up", "Down")
	if direction:
		if direction.length() > 1:
			direction = direction.normalized()
		%CreatureComponent.move_in_direction(direction)
		uncover_fog(%CreatureComponent)
	
	# Handle rotation
	%CreatureComponent.point_towards(get_global_mouse_position())
	%CameraRotation.look_at(get_global_mouse_position())
	
	# Handle attacking
	if Input.is_action_pressed("MainHand"):
		%CreatureComponent.attack()
		
	if Input.is_action_pressed("OffHand"):
		%CreatureComponent.cast_spell(%CreatureComponent.pick_spell_at_random())
		
	handle_slowdown()
	
	
func handle_slowdown():
	if %CreatureComponent.is_doing_something():
		Engine.time_scale = 1.0
		return
	if not Debug.slowdown_enabled:
		return
	Engine.time_scale = 0.05
	


func _on_creature_component_died():
	pass
	#queue_free()
	
func uncover_fog(creature : Creature):
	uncovered_fog.emit(creature)
