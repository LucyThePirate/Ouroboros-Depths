extends CharacterBody2D


@export var damage_parent : Creature
@export var bounciness : float = 1
@export var slipperiness : float = 1
const SPEED = 250.0


func _ready():
	#rotation = randf_range(-360, 360)
	%AttackComponent.damage_parent = damage_parent
	%AttackComponent.attack()
	var direction = Vector2(1, 0).rotated(rotation)
	velocity = direction * SPEED


func _physics_process(delta):
	var collision = move_and_collide(velocity * delta)
	if collision:
		velocity = (velocity.slide(collision.get_normal()) * slipperiness)
		#velocity += (velocity.bounce(collision.get_normal()) * bounciness)
		#velocity /= 2


func _on_attack_component_finished_attack_duration():
	queue_free()
