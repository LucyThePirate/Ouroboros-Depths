class_name Creature
extends CharacterBody2D

enum States {ALIVE, DEAD}

signal creature_entered_attack_range(body)
signal creature_exited_attack_range(body)
signal hit_by(creature)
signal died()

const SPEED = 150.0
const FRICTION_MULTIPLIER = 0.9

@export_category("Creature Stats")
@export var max_health : float = 20

@export_category("Attacks")
@export var fire_bat : PackedScene

var is_moving = false
@onready var current_attack = %AttackComponent
@onready var health = max_health
var state = States.ALIVE

func _physics_process(delta):
	if not is_moving:
		velocity = Vector2.ZERO
	move_and_slide()
	is_moving = false


## Assumption: direction is a normalized (or less than normalized) vector
func move_in_direction(direction : Vector2):
	velocity = direction * SPEED
	if not %AttackComponent.is_on_standby():
		velocity *= 0.5
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


func projectile_attack():
	if fire_bat:
		var new_projectile = fire_bat.instantiate()
		new_projectile.position = $AttackOffset.global_position
		new_projectile.rotation = $AttackOffset.rotation
		new_projectile.damage_parent = self
		add_child(new_projectile)


func hit(damage_amount, damage_type, damage_parent):
	if damage_parent:
		hit_by.emit(damage_parent)
	match damage_type:
		Damage_Types.DamageTypes.TRUE:
			health -= max(damage_amount, 0)
		_:
			#print("Unknown damage type:", damage_type)
			health -= max(damage_amount, 0)
	var health_percent = health / max_health
	%Sprite.self_modulate = Color(1, health_percent, health_percent)
	if health <= 0:
		perish()


func perish():
	if state == States.ALIVE:
		state = States.DEAD
		died.emit()
		%CreatureCollider.disabled = true
		
		%AnimationPlayer.play("Die")
		


func _on_attack_component_creature_entered_range(body):
	creature_entered_attack_range.emit(body)


func _on_attack_component_creature_exited_range(body):
	creature_exited_attack_range.emit(body)
