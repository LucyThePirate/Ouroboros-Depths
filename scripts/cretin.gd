extends CharacterBody2D

enum States {
	PATROLLING,
	FIGHTING,
	TRACKING,
}

@export var wander_distance = 50.0
@export var home_range = 100.0
## How close this character has to be near a target before it is considered "close enough"
@export var target_margin = 10.0
## The min amount of time this character will wait before wandering again
@export var wander_time_min = 0.25
## The max amount of time this character will wait before wandering again
@export var wander_time_max = 5

const SPEED = 100.0
const JUMP_VELOCITY = -400.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

var _state = States.PATROLLING
var _wander_target := Vector2.ZERO
var _on_wander_cooldown = false
var _current_target := Vector2.ZERO

func _ready():
	%Home.global_position = global_position

func _physics_process(delta):
	match _state:
		States.PATROLLING:
			var _distance_from_home = (global_position - %Home.global_position).length()
			if _distance_from_home < home_range:
				_wander_target = _handle_wandering()
				
				_current_target = _wander_target
			elif not _on_wander_cooldown: # too far from home, mosey on back
				_current_target = %Home.global_position
	
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction = (_current_target - global_position)
	if direction.length() > target_margin:
		direction = direction.normalized()
		velocity.x = direction.x * SPEED
		velocity.y = direction.y * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.y = move_toward(velocity.y, 0, SPEED)

	move_and_slide()
	_update_animation()
	
func _update_animation():
	if velocity:
		%Sprite.play("walking")
		%Sprite.flip_h = (velocity.x > 0)
			
	else:
		%Sprite.play("idle")
		
func _handle_wandering() -> Vector2:
	if _on_wander_cooldown:
		return _wander_target
	_on_wander_cooldown = true
	$WanderTimer.start(randf_range(wander_time_min, wander_time_max))
	var _target_position = global_position + (Vector2(randf_range(-wander_distance, wander_distance), randf_range(-wander_distance, wander_distance)))
	var _space_state = get_world_2d().direct_space_state
	# use global coordinates, not local to node
	var _query = PhysicsRayQueryParameters2D.create(global_position, _target_position)
	var _result = _space_state.intersect_ray(_query)
	if _result:
		return _result.position
	return _target_position

func _on_wander_timer_timeout():
	_on_wander_cooldown = false
