extends CharacterBody2D


const SPEED = 150.0
const FRICTION_MULTIPLIER = 0.9

var is_moving = false
@onready var current_attack = %AttackComponent

func _physics_process(delta):
	if not is_moving:
		velocity = Vector2.ZERO
	move_and_slide()
	is_moving = false


## Assumption: direction is a normalized (or less than normalized) vector
func move_in_direction(direction : Vector2):
	#if direction.x:
		#$Sprite.flip_h = direction.x > 0
	velocity = direction * SPEED
	is_moving = true
	
	
func point_towards(look_position : Vector2):
	
	var point_direction = (look_position - global_position)
	if point_direction.x:
		$Sprite.flip_h = point_direction.x > 0
	$AttackOffset.look_at(look_position)
	#look_at(look_position)


func attack():
	if current_attack:
		current_attack.attack()
