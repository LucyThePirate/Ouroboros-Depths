extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready():
	#rotation = randf_range(-360, 360)
	pass
	%AttackComponent.attack()

func _physics_process(delta):
	var direction = Vector2(1, 0).rotated(rotation)
	velocity = direction * SPEED * delta

	move_and_slide()


func _on_attack_component_finished_attack_duration():
	queue_free()
