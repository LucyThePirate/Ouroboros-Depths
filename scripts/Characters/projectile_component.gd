extends CharacterBody2D


@export var damage_parent : Creature
const SPEED = 250.0


func _ready():
	#rotation = randf_range(-360, 360)
	%AttackComponent.damage_parent = damage_parent
	%AttackComponent.attack()


func _physics_process(delta):
	var direction = Vector2(1, 0).rotated(rotation)
	velocity = direction * SPEED
	move_and_slide()


func _on_attack_component_finished_attack_duration():
	queue_free()
