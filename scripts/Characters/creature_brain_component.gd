extends Node2D


enum States {WANDER, PURSUIT, DEAD}

var current_target
var target_in_melee_range : bool = false
@onready var state = States.WANDER

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	$CreatureComponent/DebugLabel.text = States.keys()[state]
	match state:
		States.WANDER:
			pass
		States.PURSUIT:
			_handle_pursuit()


func _handle_pursuit():
	# Get the input direction and handle the movement/deceleration.
			var _distance_to_target = Vector2()
			var _direction = Vector2()
			_distance_to_target = current_target.global_position - %CreatureComponent.global_position
			if _distance_to_target:
				if _distance_to_target.length() > 1:
					_direction = _distance_to_target.normalized()
				%CreatureComponent.move_in_direction(_direction)
			
			# Handle rotation
			%CreatureComponent.point_towards(%CreatureComponent.global_position + _direction)
			
			# Handle attacking
			if target_in_melee_range:
				%CreatureComponent.attack()
			else:
				%CreatureComponent.projectile_attack()


func _on_sight_body_entered(creature):
	_try_aggroing_at(creature)


func _on_sight_body_exited(creature):
	if state == States.PURSUIT and creature == current_target:
		current_target = null
		state = States.WANDER


func _on_creature_component_creature_entered_attack_range(creature):
	if creature == current_target:
		target_in_melee_range = true


func _on_creature_component_creature_exited_attack_range(creature):
	if creature == current_target:
		target_in_melee_range = false


func _on_creature_component_died():
	state = States.DEAD


func _on_creature_component_hit_by(creature):
	_try_aggroing_at(creature)


func _try_aggroing_at(creature):
	if state == States.WANDER and creature != $CreatureComponent:
		current_target = creature
		state = States.PURSUIT
		print("Found target:", current_target.name)
