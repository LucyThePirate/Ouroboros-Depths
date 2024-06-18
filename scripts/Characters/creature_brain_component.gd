extends Node2D


enum States {WANDER, PURSUIT, DEAD}

var current_target
@onready var state = States.WANDER

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	match state:
		States.WANDER:
			pass
		States.PURSUIT:
			# Get the input direction and handle the movement/deceleration.
			var direction = Vector2()
			direction = %CreatureComponent.global_position - current_target.global_position
			if direction:
				if direction.length() > 1:
					direction = direction.normalized()
				%CreatureComponent.move_in_direction(direction)
			
			# Handle rotation
			%CreatureComponent.point_towards(%CreatureComponent.global_position + direction)
			
			# Handle attacking
			if Input.is_action_just_pressed("MainHand"):
				%CreatureComponent.attack()
	
